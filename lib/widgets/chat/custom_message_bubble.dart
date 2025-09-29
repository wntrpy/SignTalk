import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/models/message_status.dart';
import 'dart:math' as math;

const Duration kAppTzOffset = Duration(hours: 8);

DateTime _toAppLocal(dynamic ts) {
  if (ts == null) return DateTime.now().toUtc().add(kAppTzOffset);
  try {
    if (ts is DateTime) return ts.toUtc().add(kAppTzOffset);
    if (ts is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        ts,
        isUtc: true,
      ).add(kAppTzOffset);
    }
    final seconds = ts.seconds as int;
    final nanos = ts.nanoseconds as int;
    final epochMs = seconds * 1000 + (nanos ~/ 1000000);
    return DateTime.fromMillisecondsSinceEpoch(
      epochMs,
      isUtc: true,
    ).add(kAppTzOffset);
  } catch (_) {
    return DateTime.now().toUtc().add(kAppTzOffset);
  }
}

String _formatTimeHM(DateTime dt) => DateFormat('h:mm a').format(dt);

String formatDuration(Duration d) {
  if (d.inHours > 0) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}

class CustomMessageBubble extends StatefulWidget {
  final String sender;
  final String text;
  final bool isMe;
  final dynamic timestamp;
  final DateTime Function(dynamic) timestampToLocal;
  final MessageStatus status;
  final String messageId;
  final String? audioUrl;

  const CustomMessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.isMe,
    this.timestamp,
    required this.timestampToLocal,
    required this.status,
    required this.messageId,
    this.audioUrl,
  });

  @override
  State<CustomMessageBubble> createState() => _CustomMessageBubbleState();
}

enum AudioState { idle, loading, ready, playing, paused, error }

class _CustomMessageBubbleState extends State<CustomMessageBubble>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AudioPlayer _audioPlayer;

  bool _expanded = false;
  AudioState _audioState = AudioState.idle;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;
  String? _errorMessage;
  late AnimationController _waveController;

  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<ProcessingState>? _processingSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _setupAudioListeners();
    _configureTts();
  }

  void _setupAudioListeners() {
    // Listen to player state
    _stateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.playing) {
          _audioState = AudioState.playing;
          _waveController.repeat();
        } else if (state.processingState == ProcessingState.completed) {
          _audioState = AudioState.ready;
          _position = Duration.zero;
          _waveController.stop();
        } else {
          if (_audioState == AudioState.playing) {
            _audioState = AudioState.paused;
          }
          _waveController.stop();
        }
      });
    });

    // Listen to duration changes
    _durationSub = _audioPlayer.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() {
        _duration = d;
        if (_audioState == AudioState.loading) {
          _audioState = AudioState.ready;
        }
      });
    });

    // Listen to position changes
    _positionSub = _audioPlayer.positionStream.listen((p) {
      if (!mounted) return;
      setState(() {
        _position = p;
        if (_position > _duration && _duration > Duration.zero) {
          _position = _duration;
        }
      });
    });
  }

  Future<void> _configureTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      if (kDebugMode) print('TTS config error: $e');
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _processingSub?.cancel();
    _waveController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  String _getFileName() {
    final id = widget.messageId.isNotEmpty
        ? widget.messageId
        : widget.text.hashCode.toString();
    return 'tts_msg_$id.mp3';
  }

  Future<String> _getLocalFilePath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/${_getFileName()}';
  }

  Future<bool> _prepareAudio() async {
    if (_audioState == AudioState.ready || _audioState == AudioState.playing) {
      return true;
    }

    setState(() {
      _audioState = AudioState.loading;
      _errorMessage = null;
    });

    try {
      // Try remote URL first
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        try {
          await _audioPlayer.setUrl(widget.audioUrl!);
          final dur = _audioPlayer.duration;
          if (dur != null && dur > Duration.zero) {
            setState(() {
              _duration = dur;
              _audioState = AudioState.ready;
            });
            return true;
          }
        } catch (e) {
          if (kDebugMode) print('Remote URL failed: $e');
        }
      }

      // Check for cached local file
      final localPath = await _getLocalFilePath();
      final localFile = File(localPath);

      if (await localFile.exists()) {
        try {
          _localFilePath = localPath;
          await _audioPlayer.setFilePath(localPath);
          final dur = _audioPlayer.duration;
          if (dur != null && dur > Duration.zero) {
            setState(() {
              _duration = dur;
              _audioState = AudioState.ready;
            });
            return true;
          }
        } catch (e) {
          if (kDebugMode) print('Local file failed: $e');
        }
      }

      // Generate new TTS audio
      final success = await _generateTtsAudio();
      return success;
    } catch (e) {
      if (kDebugMode) print('Audio preparation error: $e');
      setState(() {
        _audioState = AudioState.error;
        _errorMessage = 'Failed to load audio';
      });
      return false;
    }
  }

  Future<bool> _generateTtsAudio() async {
    try {
      final localPath = await _getLocalFilePath();
      final localFile = File(localPath);

      // Delete old file if exists
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Synthesize to file
      await _flutterTts.synthesizeToFile(widget.text, localPath);

      // Poll for file creation
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        if (await localFile.exists()) {
          _localFilePath = localPath;

          try {
            await _audioPlayer.setFilePath(localPath);
            final dur = _audioPlayer.duration;
            if (dur != null && dur > Duration.zero) {
              setState(() {
                _duration = dur;
                _audioState = AudioState.ready;
              });
              return true;
            }
          } catch (e) {
            if (kDebugMode) print('Set file path error: $e');
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Estimate duration as fallback
      final wordCount = widget.text.split(' ').length;
      final estimatedSeconds = (wordCount / 2.5)
          .ceil(); // ~150 words per minute
      setState(() {
        _duration = Duration(seconds: estimatedSeconds);
        _audioState = AudioState.ready;
      });

      if (kDebugMode) print('Using estimated duration: $_duration');
      return false;
    } catch (e) {
      if (kDebugMode) print('TTS generation error: $e');
      setState(() {
        _audioState = AudioState.error;
        _errorMessage = 'Generation failed';
      });
      return false;
    }
  }

  Future<void> _handlePlayPause() async {
    try {
      switch (_audioState) {
        case AudioState.idle:
        case AudioState.ready:
          // Prepare and play
          if (_localFilePath == null) {
            final prepared = await _prepareAudio();
            if (!prepared) {
              // Fallback to live TTS
              setState(() => _audioState = AudioState.playing);
              _waveController.repeat();
              await _flutterTts.speak(widget.text);
              return;
            }
          }
          await _audioPlayer.play();
          break;

        case AudioState.playing:
          // Pause
          await _audioPlayer.pause();
          setState(() => _audioState = AudioState.paused);
          break;

        case AudioState.paused:
          // Resume
          await _audioPlayer.play();
          setState(() => _audioState = AudioState.playing);
          break;

        case AudioState.loading:
          // Wait for loading to complete
          break;

        case AudioState.error:
          // Retry
          await _prepareAudio();
          break;
      }
    } catch (e) {
      if (kDebugMode) print('Play/Pause error: $e');
      setState(() {
        _audioState = AudioState.error;
        _errorMessage = 'Playback error';
      });
    }
  }

  IconData _getPlayPauseIcon() {
    switch (_audioState) {
      case AudioState.playing:
        return Icons.pause;
      case AudioState.paused:
        return Icons.play_arrow;
      case AudioState.loading:
        return Icons.hourglass_empty;
      case AudioState.error:
        return Icons.refresh;
      default:
        return Icons.play_arrow;
    }
  }

  Widget _buildWaveform(Color barColor) {
    return SizedBox(
      width: 60,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final progress = _waveController.value;
              final phase = (i / 5) * 2 * math.pi;
              final value = math.sin(progress * 2 * math.pi + phase);
              final heightFactor = 0.3 + 0.7 * (0.5 + 0.5 * value);

              return Container(
                width: 4,
                height: 24 * heightFactor,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime messageTime = _toAppLocal(widget.timestamp);
    final formatted = _formatTimeHM(messageTime);

    final bubbleColor = widget.isMe
        ? AppConstants.lightViolet
        : AppConstants.extraLightViolet;
    final textColor = widget.isMe ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: widget.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: widget.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    children: [
                      Text(
                        formatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStatusIcon(widget.status),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    color: bubbleColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.text,
                          style: TextStyle(color: textColor, fontSize: 15),
                        ),
                        if (_expanded) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: _handlePlayPause,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.2)
                                        : AppConstants.darkViolet,
                                  ),
                                  child: _audioState == AudioState.loading
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              widget.isMe
                                                  ? Colors.white
                                                  : Colors.white,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          _getPlayPauseIcon(),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildWaveform(
                                          widget.isMe
                                              ? Colors.white70
                                              : AppConstants.darkViolet
                                                    .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _audioState == AudioState.loading
                                                ? 'Loading...'
                                                : _audioState ==
                                                      AudioState.error
                                                ? _errorMessage ?? 'Error'
                                                : _duration > Duration.zero
                                                ? '${formatDuration(_duration - _position)} / ${formatDuration(_duration)}'
                                                : '--:--',
                                            style: TextStyle(
                                              color: textColor.withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_duration > Duration.zero)
                                      SliderTheme(
                                        data: SliderThemeData(
                                          trackHeight: 2,
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 12,
                                              ),
                                        ),
                                        child: Slider(
                                          min: 0,
                                          max: _duration.inMilliseconds
                                              .toDouble(),
                                          value: _position.inMilliseconds
                                              .clamp(
                                                0,
                                                _duration.inMilliseconds,
                                              )
                                              .toDouble(),
                                          activeColor: widget.isMe
                                              ? Colors.white
                                              : AppConstants.darkViolet,
                                          inactiveColor: widget.isMe
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                          onChanged: (v) async {
                                            final seekPos = Duration(
                                              milliseconds: v.toInt(),
                                            );
                                            await _audioPlayer.seek(seekPos);
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (!widget.isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 16, color: Colors.grey);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 16, color: Colors.grey);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 16, color: Colors.blue);
    }
  }
}

extension on num {
  double sin() {
    return (this as double).sin();
  }
}
