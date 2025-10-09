import 'dart:io';
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

  const RecordVideoScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
  });

  @override
  State<RecordVideoScreen> createState() =>
      _RecordVideoScreenState(chatId, receiverId);
}

class _RecordVideoScreenState extends State<RecordVideoScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isProcessing = false;
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

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Cannot start recording: controller not ready');
      return;
    }

    try {
      print('Starting recording...');
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _secondsRecorded = 0;
      });

      _updateTimer();

      Future.delayed(Duration(seconds: 15), () {
        if (_isRecording && mounted) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Recording error: $e');
      _showError('Failed to start recording: $e');
    }
  }

  void _updateTimer() {
    if (!_isRecording) return;

    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() => _secondsRecorded++);
        _updateTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_controller!.value.isRecordingVideo) return;

    try {
      print('Stopping recording...');
      _videoFile = await _controller!.stopVideoRecording();
      print('Video saved: ${_videoFile!.path}');
      setState(() => _isRecording = false);
      await _processVideo();
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
        throw Exception('Cannot connect to API. Make sure Colab is running.');
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
    if (_isRecording) {
      _stopRecording();
    }
    setState(() {
      _isRecording = false;
    });
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
              bottom: 40,
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

          //  if (!_isProcessing) ...[
          //   SizedBox(width: 20),

          //       child: Center(
          //       child: Container(
          //         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //         decoration: BoxDecoration(
          //           color: Colors.red,
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //       child: Text(
          //       'Cancel',
          //           style: TextStyle(
          //           color: Colors.white,
          //           fontWeight: FontWeight.bold,
          //           fontSize: 15,
          //             ),
          //           ),
          //         ),
          //       ),

          //   ),
          // ],
        ],
      ),
    );
  }
}
