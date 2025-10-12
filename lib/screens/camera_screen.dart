import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart' show showCupertinoDialog, CupertinoAlertDialog, CupertinoDialogAction;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/UniSign/message.dart';
import 'package:signtalk/UniSign/firebase_store.dart';
import 'package:signtalk/UniSign/model_api.dart';
import 'package:signtalk/providers/chat_provider.dart';

class RecordVideoScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  

  const RecordVideoScreen({super.key, required this.chatId, required this.receiverId});

  @override
  State<RecordVideoScreen> createState() => _RecordVideoScreenState(chatId, receiverId);
}

class _RecordVideoScreenState extends State<RecordVideoScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isTimerPause = false;
  int _secondsRecorded = 0;
  String _processingStatus = 'Uploading';
  XFile? _videoFile;
  String _errorMessage = '';
  String chatId = '';
  String receiverId = '';

  _RecordVideoScreenState(this.chatId, this.receiverId);

  @override
  void initState() {
    super.initState();

    print('RecordVideoScreen initialized');
    _initializeCamera();
    _initializeMicrophone();
  }

  Future<void> _initializeMicrophone() async {
    final status = await Permission.microphone.request();

    if (status.isDenied) {
      print('Microphone permission denied');
      setState(() {
        _errorMessage =
            'Microphone permission denied. Please enable in settings.';
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      print('Camera permission permanently denied');
      setState(() {
        _errorMessage =
            'Camera permission permanently denied. Go to Settings → Apps → Permissions.';
      });
      return;
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();

      if (status.isDenied) {
        print('Camera permission denied');
        setState(() {
          _errorMessage =
              'Camera permission denied. Please enable in settings.';
        });
        return;
      }

      if (status.isPermanentlyDenied) {
        print('Camera permission permanently denied');
        setState(() {
          _errorMessage =
              'Camera permission permanently denied. Go to Settings → Apps → Permissions.';
        });
        return;
      }

      final cameras = await availableCameras();
      print('Found ${cameras.length} cameras');

      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras found on this device';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      print('Initializing camera controller...');
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      print('Initializing camera...');
      await _controller!.initialize();

      print('Camera initialized successfully!');
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera error: $e');
      setState(() {
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  late Future<void> _recordingFuture; 
  int _recordingId = 0;
  DateTime? _recordingStartTime;
  int _pausedDuration = 0;
  DateTime? _currentPauseStartTime; // Add this to track current pause
  bool _isManuallyPaused = false;   

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Cannot start recording: controller not ready');
      return;
    }

    if (_controller!.value.isRecordingVideo) {
    print('Recording already in progress');
    return;
  }

    try {
      print('Starting recording...');
      _isCancelled = false;
      _videoFile = null;
      _recordingId++;
      _recordingStartTime = DateTime.now();
      _pausedDuration = 0;
      _isManuallyPaused = false;

      await _controller!.startVideoRecording();
    
      setState(() {
        _isRecording = true;
        _secondsRecorded = 0;
        _isTimerPause = false;
      });

      _updateTimer();

      final currentRecordingId = _recordingId;

    // Check every 100ms if we've reached 15 seconds of actual recording time
    _checkRecordingDuration(currentRecordingId);
  
    } catch (e) {
      print('Recording error: $e');
      _showError('Failed to start recording: $e');
    }
  }

  void _checkRecordingDuration(int recordingId) {
  Future.delayed(Duration(milliseconds: 100), () {
    if (!_isRecording || _isCancelled || recordingId != _recordingId || !mounted) {
      return;
    }

    // Calculate actual recording time (excluding paused time)
    final totalElapsed = DateTime.now().difference(_recordingStartTime!).inSeconds;

     int currentPauseDuration = 0;
    if (_isManuallyPaused && _currentPauseStartTime != null) {
      currentPauseDuration = DateTime.now().difference(_currentPauseStartTime!).inSeconds;
    }

    final actualRecordingTime = totalElapsed - _pausedDuration - currentPauseDuration;

     print('Total elapsed: $totalElapsed, Paused: $_pausedDuration, Current pause: $currentPauseDuration, Actual: $actualRecordingTime');

    if (actualRecordingTime >= 15) {
      print('15 seconds of recording reached');
      _stopRecording();
    } else {
      _checkRecordingDuration(recordingId); // Keep checking
    }
  });
}

  void _updateTimer() {
    if (!_isRecording) return;

    Future.delayed(Duration(seconds: 1), () {
      if (!_isTimerPause && _isRecording && mounted) {
        setState(() => _secondsRecorded++);
        _updateTimer();
      }else if(_isTimerPause && _isRecording && mounted){
        _updateTimer();
      }
    });
  }

  bool _isCancelled = false;

  Future<void> _stopRecording() async {
    if (!_controller!.value.isRecordingVideo) return;

    try {
      print('Stopping recording...');
      _videoFile = await _controller!.stopVideoRecording();
      print('Video saved: ${_videoFile!.path}');
      setState(() => _isRecording = false);

        if (!_isCancelled) {
          print("Processing vid");
      await _processVideo();
    }else {
      print("vid is not processing cos canncelled");
    }

    } catch (e) {
      print('Stop recording error: $e');
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _processVideo() async {
    if (_videoFile == null) return;
       
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Uploading video';
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final firebaseService = FirebaseService();
      final apiService = ModelApiService();

      setState(() => _processingStatus = 'Uploading.....');
      final videoUrl = await firebaseService.uploadVideo(
        File(_videoFile!.path),
        userId,
      );
      print('Video uploaded: $videoUrl');

      print('Checking API health...');
      setState(() => _processingStatus = 'Connecting.....');
      final isHealthy = await apiService.checkHealth();
      
      if (!isHealthy) {
        throw Exception('Cannot connect to API.');
      }

      setState(() => _processingStatus = 'Recognizing signs');
      final result = await apiService.recognizeVideo(
        videoUrl: videoUrl,
        userId: userId,
        chatId: widget.chatId,
      );

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Recognition failed');
      }
      print('Recognition complete: ${result['translation']}');

      print('Saving message...');
      setState(() => _processingStatus = 'Saving message');
      final message = Message(
        id: '',
        chatId: widget.chatId,
        senderId: userId,
        text: result['translation'],
        videoUrl: videoUrl,
        timestamp: DateTime.now(),
      );

      await firebaseService.saveMessage(message);
      print('Message saved');

      // Success!
      if (mounted) {
        
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        var message = result['translation'];

        await chatProvider.sendMessage(chatId, message, receiverId);
      
      }
    } catch (e) {
      print('Processing error: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
    Future<void> _cancelRecording() async {
    try {
    print('Attempting to pause recording...');
    print('Is recording before pause: ${_controller!.value.isRecordingVideo}');
    print('Is recording paused before: ${_controller!.value.isRecordingPaused}');

    _isManuallyPaused = true;
    _currentPauseStartTime = DateTime.now();
    
    await _controller!.pauseVideoRecording();
    
    print('Is recording after pause: ${_controller!.value.isRecordingVideo}');
    print('Is recording paused after: ${_controller!.value.isRecordingPaused}');
  } catch (e) {
    print('Error pausing recording: $e');
    // If pause fails, we might need to handle this differently
  }
   
     setState(() {
    _isTimerPause = true;
  });
  
    
   final bool? result = await showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        content: Text('Are you sure you want to cancel? The recording will be deleted.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('No'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(true); // Yes
            },
            child: Text('Yes'),
          ),
        ],
      );
    },
  );

     // Calculate how long we were paused for this session
  if (_currentPauseStartTime != null) {
    final pauseDuration = DateTime.now().difference(_currentPauseStartTime!).inSeconds;
    _pausedDuration += pauseDuration;
    print('Pause duration: $pauseDuration seconds');
    print('Total paused duration: $_pausedDuration seconds');
     _currentPauseStartTime = null;
  }

  if (result == true) {
    // User confirmed cancellation
    _isManuallyPaused = false;
    _currentPauseStartTime = null;
    await _performCancelRecording();
  } else {
    // User said no, resume recording
    await _resumeRecording();
  }
}
  Future<void> _resumeRecording() async {
  try {
    print('Attempting to resume recording...');
    print('Is recording paused before resume: ${_controller!.value.isRecordingPaused}');
    
      // Try to resume even if it says it's not paused
    if (_controller!.value.isRecordingVideo) {
      try {
        await _controller!.resumeVideoRecording();
      } catch (e) {
        print('Resume failed (might already be resumed): $e');
      }
    }
    
    print('Is recording paused after resume: ${_controller!.value.isRecordingPaused}');

    _isManuallyPaused = false;
    _currentPauseStartTime = null;

    setState(() {
       _isTimerPause = false;
    });

    print('Recording resumed');
  } catch (e) {
    print("Error resuming recording: $e");
  }
}

    Future<void> _performCancelRecording()async {
    _isCancelled = true;   
    _recordingId++;
    _isManuallyPaused = false;
    _currentPauseStartTime = null;
  
     try {
        // Check if recording is actually running
    if (!_controller!.value.isRecordingVideo) {
      print('No recording to cancel');
      setState(() {
        _isRecording = false;
        _isTimerPause = false;
        _secondsRecorded = 0;
        _recordingStartTime = null;
        _pausedDuration = 0;
      });
      return;
    }

       setState(() {
      _isRecording = false;
      _isTimerPause = false;
      _secondsRecorded = 0;
      _recordingStartTime = null;
      _pausedDuration = 0;
    });

      await _controller!.stopVideoRecording();

      await Future.delayed(Duration(milliseconds: 1000));
   
    if (_videoFile !=null) {
      final file = File (_videoFile!.path);
      await file.delete();
    }
    _videoFile = null;
    } catch (e) {
      print("Error cancelling recording: $e");
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Record ASL')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_errorMessage.contains('permanently')) {
                      openAppSettings();
                    } else {
                      setState(() {
                        _errorMessage = '';
                      });
                      _initializeCamera();
                    }
                  },
                  child: Text(
                    _errorMessage.contains('permanently')
                        ? 'Open Settings'
                        : 'Try Again',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Record ASL')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Record ASL Video'),
        backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      ),
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),

          if (_isRecording)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Recording: ${_secondsRecorded}s / 15s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      _processingStatus,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please Wait...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isProcessing)
            Positioned(
              bottom: 65,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.videocam,
                      color: _isRecording ? Colors.white : Colors.red,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
         

              if (_isRecording)
                    Positioned(
                      bottom: 78,
                      left: 220,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _cancelRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),        
        ],
      ),
    );
  }
}

