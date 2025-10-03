import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
  final bool showAudio;

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
    required this.showAudio,
  });

  @override
  State<CustomMessageBubble> createState() => _CustomMessageBubbleState();
}

enum PlayState { idle, loading, ready, playing, paused, error }

class _CustomMessageBubbleState extends State<CustomMessageBubble>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  bool _expanded = false;
  PlayState _state = PlayState.idle;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _cachedPath;
  late AnimationController _waveAnim;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _setupListeners();
  }

  void _setupListeners() {
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.playing) {
        setState(() => _state = PlayState.playing);
        _waveAnim.repeat();
      } else if (state.processingState == ProcessingState.completed) {
        _simulationTimer?.cancel();
        setState(() {
          _state = PlayState.ready;
          _position = Duration.zero;
        });
        _waveAnim.stop();
      } else if (_state == PlayState.playing) {
        setState(() => _state = PlayState.paused);
        _waveAnim.stop();
      }
    });

    _player.durationStream.listen((d) {
      if (d != null && mounted) {
        setState(() {
          _duration = d;
          if (_state == PlayState.loading) _state = PlayState.ready;
        });
      }
    });

    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _waveAnim.dispose();
    _player.dispose();
    super.dispose();
  }

  String _getCacheFileName() {
    final id = widget.messageId.isNotEmpty
        ? widget.messageId
        : widget.text.hashCode.toString();
    return 'tts_$id.mp3';
  }

  Future<String?> _generateFreeTts() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${_getCacheFileName()}';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      final text = Uri.encodeComponent(widget.text);
      final url = Uri.parse(
        'https://api.streamelements.com/kappa/v2/speech?voice=Brian&text=$text',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.length > 1000) {
        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('TTS error: $e');
      return null;
    }
  }

  void _startSimulatedPlayback() {
    _simulationTimer?.cancel();
    final startTime = DateTime.now();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted || _state != PlayState.playing) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime);
      setState(() {
        _position = elapsed;
        if (_position >= _duration) {
          _position = Duration.zero;
          _state = PlayState.ready;
          _waveAnim.stop();
          t.cancel();
        }
      });
    });
  }

  Future<void> _prepareAudio() async {
    if (_state == PlayState.ready || _state == PlayState.playing) return;

    setState(() => _state = PlayState.loading);

    try {
      if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _player.setUrl(widget.audioUrl!);
        await Future.delayed(const Duration(milliseconds: 300));
        if (_player.duration != null && _player.duration! > Duration.zero) {
          setState(() {
            _duration = _player.duration!;
            _state = PlayState.ready;
            _cachedPath = widget.audioUrl;
          });
          return;
        }
      }

      final path = await _generateFreeTts();
      if (path != null) {
        await _player.setFilePath(path);
        await Future.delayed(const Duration(milliseconds: 500));
        if (_player.duration != null && _player.duration! > Duration.zero) {
          setState(() {
            _duration = _player.duration!;
            _state = PlayState.ready;
            _cachedPath = path;
          });
          return;
        }
      }

      final estimatedSec = math.max(2, widget.text.length ~/ 15);
      setState(() {
        _duration = Duration(seconds: estimatedSec);
        _state = PlayState.ready;
      });
    } catch (_) {
      final estimatedSec = math.max(
        2,
        (widget.text.split(' ').length / 2.5).ceil(),
      );
      setState(() {
        _duration = Duration(seconds: estimatedSec);
        _state = PlayState.ready;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (!widget.showAudio) return; // skip if hidden

    switch (_state) {
      case PlayState.idle:
      case PlayState.ready:
        if (_cachedPath == null) await _prepareAudio();
        if (_state != PlayState.ready) return;

        if (_cachedPath != null) {
          try {
            await _player.play();
            return;
          } catch (_) {}
        }

        setState(() => _state = PlayState.playing);
        _waveAnim.repeat();
        _startSimulatedPlayback();
        break;

      case PlayState.playing:
        _simulationTimer?.cancel();
        if (_cachedPath != null) await _player.pause();
        setState(() => _state = PlayState.paused);
        _waveAnim.stop();
        break;

      case PlayState.paused:
        if (_cachedPath != null) {
          await _player.play();
        } else {
          setState(() => _state = PlayState.playing);
          _waveAnim.repeat();
          _startSimulatedPlayback();
        }
        break;

      case PlayState.loading:
      case PlayState.error:
        await _prepareAudio();
        break;
    }
  }

  IconData _getIcon() {
    switch (_state) {
      case PlayState.playing:
        return Icons.pause;
      case PlayState.loading:
        return Icons.hourglass_empty;
      case PlayState.error:
        return Icons.refresh;
      default:
        return Icons.play_arrow;
    }
  }

  Widget _buildWave(Color color) {
    return SizedBox(
      width: 50,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          return AnimatedBuilder(
            animation: _waveAnim,
            builder: (_, __) {
              final phase = (i / 4) * math.pi * 2;
              final val = math.sin(_waveAnim.value * math.pi * 2 + phase);
              final h = 0.3 + 0.7 * (0.5 + 0.5 * val);
              return Container(
                width: 3,
                height: 20 * h,
                decoration: BoxDecoration(
                  color: color,
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
    final messageTime = _toAppLocal(widget.timestamp);
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
                    borderRadius: BorderRadius.circular(15),
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
                        if (_expanded && widget.showAudio) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              InkWell(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.isMe
                                        ? Colors.white.withOpacity(0.25)
                                        : AppConstants.darkViolet,
                                  ),
                                  child: _state == PlayState.loading
                                      ? const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          _getIcon(),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _buildWave(
                                          widget.isMe
                                              ? Colors.white70
                                              : AppConstants.darkViolet
                                                    .withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _state == PlayState.loading
                                                ? 'Loading...'
                                                : _duration > Duration.zero
                                                ? '${formatDuration(_duration - _position)} / ${formatDuration(_duration)}'
                                                : '--:--',
                                            style: TextStyle(
                                              color: widget.isMe
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : Colors.black87.withOpacity(
                                                      0.8,
                                                    ),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_duration > Duration.zero)
                                      Slider(
                                        min: 0,
                                        max: _duration.inMilliseconds
                                            .toDouble(),
                                        value: _position.inMilliseconds
                                            .clamp(0, _duration.inMilliseconds)
                                            .toDouble(),
                                        activeColor: widget.isMe
                                            ? Colors.white
                                            : AppConstants.darkViolet,
                                        inactiveColor: Colors.grey.withOpacity(
                                          0.3,
                                        ),
                                        onChanged: (v) async {
                                          final seekPos = Duration(
                                            milliseconds: v.toInt(),
                                          );
                                          setState(() => _position = seekPos);
                                          if (_cachedPath != null) {
                                            await _player.seek(seekPos);
                                          }
                                        },
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
