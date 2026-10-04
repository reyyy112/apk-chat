import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/voice_record_service.dart';
import '../../../theme/app_theme.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoidCallback onRecordingStarted;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onRecordingCancelled;
  final ValueChanged<VoiceRecordResult> onRecordingCompleted;

  const VoiceRecordButton({
    super.key,
    required this.onRecordingStarted,
    required this.onDurationChanged,
    required this.onRecordingCancelled,
    required this.onRecordingCompleted,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  final VoiceRecordService _voiceService = VoiceRecordService();
  bool _isPressing = false;
  bool _isCancelled = false;
  int _seconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _seconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
        widget.onDurationChanged(_seconds);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isPressing = true;
      _isCancelled = false;
    });
    _pulseController.repeat(reverse: true);

    final started = await _voiceService.startRecording();
    if (!started) {
      _handleCancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan untuk merekam suara'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    _startTimer();
    widget.onRecordingStarted();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    // If user dragged finger/cursor > 70px to the left
    if (details.localOffsetFromOrigin.dx < -70) {
      if (!_isCancelled) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isCancelled = true;
        });
      }
    } else {
      if (_isCancelled) {
        setState(() {
          _isCancelled = false;
        });
      }
    }
  }

  Future<void> _handleLongPressEnd(LongPressEndDetails details) async {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();

    final wasCancelled = _isCancelled;
    final recordedSeconds = _seconds;

    setState(() {
      _isPressing = false;
      _isCancelled = false;
      _seconds = 0;
    });

    if (wasCancelled) {
      await _voiceService.cancelRecording();
      widget.onRecordingCancelled();
      return;
    }

    if (recordedSeconds < 1) {
      await _voiceService.cancelRecording();
      widget.onRecordingCancelled();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahan tombol lebih lama untuk merekam suara'),
            duration: Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Stop and upload voice note to Supabase Storage
    final result = await _voiceService.stopAndUpload();
    if (result != null && result.uploadedUrl != null) {
      widget.onRecordingCompleted(result);
    } else {
      widget.onRecordingCancelled();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunggah pesan suara ke penyimpanan'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _handleCancel() {
    _pulseController.stop();
    _pulseController.reset();
    _stopTimer();
    setState(() {
      _isPressing = false;
      _isCancelled = false;
      _seconds = 0;
    });
    _voiceService.cancelRecording();
    widget.onRecordingCancelled();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahan tombol mikrofon untuk merekam suara'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = _isPressing ? _scaleAnimation.value : 1.0;
          final bgColor = _isCancelled
              ? const Color(0xFFEF4444)
              : (_isPressing ? const Color(0xFF0F766E) : AppTheme.primaryTeal);

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: _isPressing ? 14 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isCancelled ? Icons.delete_outline_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
