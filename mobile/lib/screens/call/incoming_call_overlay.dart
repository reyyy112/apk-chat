import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/socket_provider.dart';
import '../../router/app_router.dart';
import '../../services/api_service.dart';
import '../../services/webrtc_service.dart';
import '../../theme/app_theme.dart';
import 'call_screen.dart';

class GlobalCallManager extends ConsumerWidget {
  final Widget child;
  const GlobalCallManager({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callProvider);
    final isIncomingRinging = call.isCalling && call.isIncoming && call.status == 'ringing';

    return Stack(
      children: [
        child,
        if (isIncomingRinging)
          Positioned.fill(
            child: IncomingCallOverlayWidget(call: call),
          ),
      ],
    );
  }
}

class IncomingCallOverlayWidget extends ConsumerStatefulWidget {
  final CallState call;
  const IncomingCallOverlayWidget({super.key, required this.call});

  @override
  ConsumerState<IncomingCallOverlayWidget> createState() => _IncomingCallOverlayWidgetState();
}

class _IncomingCallOverlayWidgetState extends ConsumerState<IncomingCallOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleDecline() {
    final socket = ref.read(socketProvider);
    socket?.emit('reject_call', {
      'callerId': widget.call.targetUserId,
      'reason': 'declined',
    });

    ApiService.recordCall(
      callerId: widget.call.targetUserId,
      receiverId: ApiService.currentUserId,
      status: 'declined',
      duration: 0,
      type: widget.call.mediaType,
    );

    WebRtcService().cleanUp();
    ref.read(callProvider.notifier).endCall();
  }

  void _handleAccept() {
    ref.read(callProvider.notifier).connectCall();

    final navContext = rootNavigatorKey.currentContext ?? context;

    CallDialog.openActiveCall(
      navContext,
      ref,
      targetUserId: widget.call.targetUserId,
      targetUserName: widget.call.targetUserName,
      targetUserAvatar: widget.call.targetUserAvatar,
      mediaType: widget.call.mediaType,
      offer: widget.call.offer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.call.mediaType == 'video';

    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: 360,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal)
                    .withValues(alpha: 0.4),
                blurRadius: 36,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge: PANGGILAN MASUK
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isVideo ? const Color(0xFF38BDF8) : const Color(0xFF4ADE80))
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
                      color: isVideo ? const Color(0xFF38BDF8) : const Color(0xFF4ADE80),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isVideo ? 'PANGGILAN VIDEO MASUK' : 'PANGGILAN SUARA MASUK',
                      style: TextStyle(
                        color: isVideo ? const Color(0xFF38BDF8) : const Color(0xFF4ADE80),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Animated Pulsing Avatar
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120 * _pulseAnimation.value,
                        height: 120 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal)
                              .withValues(alpha: 0.12),
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.mintLight,
                          border: Border.all(
                            color: isVideo ? const Color(0xFF38BDF8) : AppTheme.primaryTeal,
                            width: 3.5,
                          ),
                          image: widget.call.targetUserAvatar.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.call.targetUserAvatar),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.call.targetUserAvatar.isEmpty
                            ? Center(
                                child: Text(
                                  widget.call.targetUserName.isNotEmpty
                                      ? widget.call.targetUserName.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: isVideo
                                        ? const Color(0xFF0284C7)
                                        : AppTheme.primaryTeal,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Caller Name
              Text(
                widget.call.targetUserName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Menghubungi Anda...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 36),

              // Action Buttons (Tolak vs Terima)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Button: Tolak (Decline)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _handleDecline,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66EF4444),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tolak',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Button: Terima (Answer)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _handleAccept,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Icon(
                            isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Terima',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
