// voice_recording_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signtalk/app_constants.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // for MissingPluginException

class VoiceRecordingWidget extends StatefulWidget {
  final AudioRecorder audioRecorder;
  final VoidCallback onCancel;

  /// Now passes (transcribedText, duration, audioPath)
  final Function(String transcribedText, Duration duration, String? audioPath)
  onSend;

  const VoiceRecordingWidget({
    super.key,
    required this.audioRecorder,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with SingleTickerProviderStateMixin {
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  bool _isRecording = true;
  String? _audioPath;
  late AnimationController _pulseController;
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // Speech to text
  late stt.SpeechToText _speechToText;
  String _transcribedText = '';
  bool _speechAvailable = true;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _startTimer();
    _setupPlayerListener();
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) print('❌ Speech recognition error: $error');
        },
        onStatus: (status) {
          if (kDebugMode) print('🎤 Speech recognition status: $status');
        },
      );

      if (!available) {
        if (kDebugMode) print('❌ Speech recognition NOT available');
        setState(() => _speechAvailable = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
        return;
      }

      if (kDebugMode)
        print('✅ Speech recognition available, starting to listen...');
      await _speechToText.listen(
        onResult: (result) {
          if (kDebugMode) {
            print('🗣️ Transcribed: "${result.recognizedWords}"');
            print('📝 Is final: ${result.finalResult}');
          }
          setState(() {
            _transcribedText = result.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    } on MissingPluginException catch (e) {
      // This matches your log: MissingPluginException(No implementation found for method initialize ...)
      if (kDebugMode) print('❌ Speech plugin missing: $e');
      setState(() => _speechAvailable = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition plugin missing')),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Speech recognition initialization error: $e');
      setState(() => _speechAvailable = false);
    }
  }

  void _setupPlayerListener() {
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _player.dispose();
    try {
      _speechToText.stop();
    } catch (_) {}
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });

        // Auto-stop after 5 seconds
        if (_recordingDuration.inSeconds >= 15) {
          if (kDebugMode) print('⏱️ 5 seconds reached, auto-stopping...');
          _stopRecording();
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _stopRecording() async {
    if (kDebugMode) print('🛑 Stopping recording...');

    _timer?.cancel();
    _pulseController.stop();

    // Give speech recognition a moment to finalize
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await _speechToText.stop();
    } catch (_) {}

    if (kDebugMode) print('📋 Final transcribed text: "$_transcribedText"');

    // Stop the recorder and get the path
    final path = await widget.audioRecorder.stop();

    if (kDebugMode) print('💾 Audio saved to: $path');

    if (path != null && await File(path).exists()) {
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      if (_transcribedText.trim().isEmpty) {
        if (kDebugMode) print('⚠️ No speech detected!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No speech detected. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (kDebugMode) print('✅ Speech detected: "$_transcribedText"');
      }
    } else {
      if (kDebugMode) print('❌ Failed to save recording');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save recording')),
        );
      }
    }
  }

  void _deleteRecording() {
    widget.onCancel();
  }

  void _sendRecording() {
    if (kDebugMode) print('📤 Attempting to send recording...');
    if (kDebugMode) print('📋 Transcribed text to send: "$_transcribedText"');
    if (kDebugMode) print('📁 Audio path: $_audioPath');

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available')),
        );
      }
      return;
    }

    if (_transcribedText.trim().isEmpty) {
      if (kDebugMode) print('⚠️ Cannot send - no transcribed text');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speech was transcribed. Please try again.'),
          ),
        );
      }
      return;
    }

    // Pass transcription + duration + audioPath back to the caller
    widget.onSend(_transcribedText.trim(), _recordingDuration, _audioPath);
  }

  Future<void> _togglePlayback() async {
    if (_audioPath == null || _audioPath!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No audio file to play')));
      return;
    }

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.stop();
        await _player.play(DeviceFileSource(_audioPath!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play audio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optionally show an explicit warning if speech plugin unavailable
            if (!_speechAvailable)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Speech recognition is not available on this device.',
                  style: TextStyle(fontSize: 13),
                ),
              ),

            if (_transcribedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppConstants.extraLightViolet.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.lightViolet.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: AppConstants.darkViolet,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Transcribed:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _transcribedText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                IconButton(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        if (_isRecording)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(
                                    0.5 + (_pulseController.value * 0.5),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Icon(
                            Icons.mic,
                            color: AppConstants.darkViolet,
                            size: 20,
                          ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (!_isRecording && _audioPath != null)
                          IconButton(
                            onPressed: _togglePlayback,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            color: AppConstants.darkViolet,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.darkViolet,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isRecording ? _stopRecording : _sendRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
