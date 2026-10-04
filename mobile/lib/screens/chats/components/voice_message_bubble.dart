import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../theme/app_theme.dart';

/// Global reference to ensure only one voice note plays at any given time
AudioPlayer? _activeVoicePlayer;
VoidCallback? _activeStopCallback;

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final int status; // 1: sent, 2: delivered, 3: read
  final String timestamp;

  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.status,
    required this.timestamp,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  // Waveform heights (pseudo-random representative heights for voice waveform)
  static const List<double> _waveformPattern = [
    0.3, 0.6, 0.9, 0.5, 0.7, 1.0, 0.8, 0.4, 0.6, 0.9,
    0.7, 0.5, 0.8, 1.0, 0.6, 0.4, 0.7, 0.9, 0.5, 0.3,
    0.6, 0.8, 0.5, 0.4, 0.7, 0.3, 0.5, 0.2
  ];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    _durationSubscription = _player.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });

    _positionSubscription = _player.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_activeVoicePlayer == _player) {
      _activeVoicePlayer = null;
      _activeStopCallback = null;
    }
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      // Pause currently playing audio if different
      if (_activeVoicePlayer != null && _activeVoicePlayer != _player) {
        await _activeVoicePlayer?.pause();
        _activeStopCallback?.call();
      }

      _activeVoicePlayer = _player;
      _activeStopCallback = () {
        if (mounted) setState(() {});
      };

      if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(widget.audioUrl));
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '10:30';
    }
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;

    switch (widget.status) {
      case 3: // Read
        icon = Icons.done_all_rounded;
        color = const Color(0xFF67E8F9); // Light cyan
        break;
      case 2: // Delivered
        icon = Icons.done_all_rounded;
        color = Colors.white70;
        break;
      case 1: // Sent
      default:
        icon = Icons.done_rounded;
        color = Colors.white70;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final isPlaying = _playerState == PlayerState.playing;

    // Progress percentage 0.0 - 1.0
    double progress = 0.0;
    if (_duration.inMilliseconds > 0) {
      progress = (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    }

    final activeBarColor = isMe ? Colors.white : AppTheme.primaryTeal;
    final inactiveBarColor = isMe ? Colors.white38 : const Color(0xFFCBD5E1);

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. Play / Pause Circular Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMe ? Colors.white : AppTheme.primaryTeal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isMe ? AppTheme.primaryTeal : Colors.white,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Interactive Waveform Bars & Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform Bars
                    GestureDetector(
                      onTapDown: (details) {
                        if (_duration.inMilliseconds > 0) {
                          final localPos = details.localPosition;
                          final fraction = (localPos.dx / 170).clamp(0.0, 1.0);
                          final seekTarget = Duration(
                            milliseconds: (_duration.inMilliseconds * fraction).round(),
                          );
                          _player.seek(seekTarget);
                        }
                      },
                      child: Container(
                        height: 28,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_waveformPattern.length, (index) {
                            final barFraction = index / _waveformPattern.length;
                            final isPassed = barFraction <= progress;
                            final barHeight = 8 + (20 * _waveformPattern[index]);

                            return Container(
                              width: 3,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: isPassed ? activeBarColor : inactiveBarColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Duration info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPlaying
                              ? _formatDuration(_position)
                              : (_duration > Duration.zero
                                  ? _formatDuration(_duration)
                                  : '0:00'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white70 : AppTheme.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.mic_rounded,
                              size: 12,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Voice',
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 3. Timestamp and Read Status Checkmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTimestamp(widget.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIndicator(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
