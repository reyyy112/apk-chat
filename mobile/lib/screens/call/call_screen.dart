import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../providers/socket_provider.dart';
import '../../services/api_service.dart';
import '../../services/webrtc_service.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

class CallDialog {
  static void startCall(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String targetUserAvatar,
  }) {
    _launchCall(
      context,
      ref,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      mediaType: 'audio',
      isOutgoing: true,
    );
  }

  static void startVideoCall(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String targetUserAvatar,
  }) {
    _launchCall(
      context,
      ref,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      mediaType: 'video',
      isOutgoing: true,
    );
  }

  static void openActiveCall(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String targetUserAvatar,
    required String mediaType,
    Map<String, dynamic>? offer,
  }) {
    _launchCall(
      context,
      ref,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      mediaType: mediaType,
      isOutgoing: false,
      offer: offer,
    );
  }

  static void _launchCall(
    BuildContext context,
    WidgetRef ref, {
    required String targetUserId,
    required String targetUserName,
    required String targetUserAvatar,
    required String mediaType,
    required bool isOutgoing,
    Map<String, dynamic>? offer,
  }) {
    if (isOutgoing) {
      ref.read(callProvider.notifier).startOutgoingCall(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
        mediaType: mediaType,
      );
    }

    final navContext = rootNavigatorKey.currentContext ?? context;

    showModalBottomSheet(
      context: navContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ActiveCallScreen(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        targetUserAvatar: targetUserAvatar,
        initialMediaType: mediaType,
        isOutgoing: isOutgoing,
        offer: offer,
      ),
    );
  }
}

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String targetUserAvatar;
  final String initialMediaType; // 'audio' | 'video'
  final bool isOutgoing;
  final Map<String, dynamic>? offer;

  const ActiveCallScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserAvatar,
    required this.initialMediaType,
    required this.isOutgoing,
    this.offer,
  });

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  late String _mediaType;
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;
  bool _isSwapped = false; // Tap PiP preview to swap local and remote views
  String _callStatus = 'Menghubungkan...';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mediaType = widget.initialMediaType;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupWebRtc();
  }

  Future<void> _setupWebRtc() async {
    final webrtc = WebRtcService();
    final isVideo = _mediaType == 'video';

    webrtc.onIceCandidate = (candidate) {
      final socket = ref.read(socketProvider);
      socket?.emit('ice_candidate', {
        'targetUserId': widget.targetUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    webrtc.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {});
      }
    };

    webrtc.onConnectionStateChange = (state) {
      debugPrint('[ActiveCall] WebRTC state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (mounted) {
          _startTimer();
        }
      }
    };

    try {
      if (widget.isOutgoing) {
        setState(() {
          _callStatus = 'Menghubungkan...';
        });

        // 1. Create offer with STUN/TURN ICE servers
        final offer = await webrtc.createOffer(isVideo: isVideo);

        // 2. Emit call_user with offer
        final socket = ref.read(socketProvider);
        socket?.emit('call_user', {
          'recipientId': widget.targetUserId,
          'callerId': ApiService.currentUserId,
          'callerName': ApiService.currentUserName,
          'callerAvatar': ApiService.currentUserAvatar,
          'mediaType': _mediaType,
          'offer': offer.toMap(),
        });

        if (mounted) {
          setState(() {
            _callStatus = 'Berdering...';
          });
        }
      } else {
        // Incoming call accepted: Create answer from caller's offer
        if (widget.offer != null) {
          final answer = await webrtc.createAnswer(
            remoteOffer: widget.offer!,
            isVideo: isVideo,
          );

          final socket = ref.read(socketProvider);
          socket?.emit('answer_call', {
            'callerId': widget.targetUserId,
            'answer': answer.toMap(),
          });
        } else {
          await webrtc.startLocalMedia(isVideo: isVideo);
        }
        _startTimer();
      }
    } catch (e) {
      debugPrint('[ActiveCall] Error initializing WebRTC: $e');
      if (mounted) {
        setState(() {
          _callStatus = 'Gagal menghubungkan';
        });
      }
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() {
      _callStatus = 'Terhubung';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
        ref.read(callProvider.notifier).updateDuration(_seconds);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    WebRtcService().cleanUp();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showCameraSelectionDialog(BuildContext context) async {
    final webrtc = WebRtcService();
    final cameras = await webrtc.getAvailableCameras();
    if (!mounted || cameras.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.videocam_rounded, color: AppTheme.primaryTeal),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Kamera Perangkat',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              ...cameras.map((c) {
                final label = c.label.isNotEmpty ? c.label : 'Kamera (${c.deviceId.substring(0, 8)})';
                return ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
                  title: Text(label, style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await webrtc.switchCamera(targetDeviceId: c.deviceId);
                    if (mounted) setState(() {});
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEndCall() {
    WebRtcService().cleanUp();

    final socket = ref.read(socketProvider);
    socket?.emit('end_call', {
      'targetUserId': widget.targetUserId,
      'duration': _seconds,
    });

    // Save call record to database
    ApiService.recordCall(
      callerId: widget.isOutgoing ? ApiService.currentUserId : widget.targetUserId,
      receiverId: widget.isOutgoing ? widget.targetUserId : ApiService.currentUserId,
      status: _seconds > 0 ? 'completed' : 'missed',
      duration: _seconds,
      type: _mediaType,
    );

    ref.read(callProvider.notifier).endCall();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for call state termination from peer
    ref.listen<CallState>(callProvider, (previous, next) {
      if (!next.isCalling && mounted) {
        Navigator.of(context).pop();
      } else if (next.status == 'connected' && _timer == null) {
        _startTimer();
      }
    });

    final isVideo = _mediaType == 'video';

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: Color(0xFF090D16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          child: isVideo ? _buildVideoCallLayout() : _buildAudioCallLayout(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AUDIO CALL LAYOUT
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAudioCallLayout() {
    final webrtc = WebRtcService();

    return Stack(
      children: [
        // Hidden / offstage audio renderer so remote audio track plays via WebRTC
        Positioned(
          top: 0,
          left: 0,
          child: SizedBox(
            width: 1,
            height: 1,
            child: webrtc.remoteRenderer.srcObject != null
                ? RTCVideoView(webrtc.remoteRenderer)
                : const SizedBox.shrink(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.primaryTeal),
                        SizedBox(width: 6),
                        Text(
                          'WebRTC P2P Enkripsi • Panggilan Suara',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Animated Pulsing Avatar
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 150 * _pulseAnimation.value,
                            height: 150 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                            ),
                          ),
                          Container(
                            width: 130 * _pulseAnimation.value,
                            height: 130 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.mintLight,
                              border: Border.all(color: AppTheme.primaryTeal, width: 3),
                              image: widget.targetUserAvatar.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.targetUserAvatar),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: widget.targetUserAvatar.isEmpty
                                ? Center(
                                    child: Text(
                                      widget.targetUserName.isNotEmpty
                                          ? widget.targetUserName.substring(0, 1).toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryTeal,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Friend Name
                  Text(
                    widget.targetUserName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status / Timer
                  Text(
                    _seconds > 0 ? _formatDuration(_seconds) : _callStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: _seconds > 0 ? const Color(0xFF4ADE80) : Colors.white70,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              // Bottom Controls
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute Mic
                      _buildCircleBtn(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Muted' : 'Mute',
                        isActive: _isMuted,
                        activeColor: Colors.amber,
                        onTap: () {
                          setState(() => _isMuted = !_isMuted);
                          WebRtcService().toggleMic(_isMuted);
                        },
                      ),

                      // Speaker
                      _buildCircleBtn(
                        icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        label: 'Speaker',
                        isActive: _isSpeaker,
                        activeColor: AppTheme.primaryTeal,
                        onTap: () {
                          setState(() => _isSpeaker = !_isSpeaker);
                          WebRtcService().toggleSpeaker(_isSpeaker);
                        },
                      ),

                      // Switch to Video Call
                      _buildCircleBtn(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        isActive: false,
                        onTap: () async {
                          setState(() {
                            _mediaType = 'video';
                          });
                          ref.read(callProvider.notifier).setMediaType('video');
                          await WebRtcService().startLocalMedia(isVideo: true);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // End Call Button
                  GestureDetector(
                    onTap: _handleEndCall,
                    child: Container(
                      width: 72,
                      height: 72,
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
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Akhiri Panggilan',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIDEO CALL LAYOUT (WebRTC Peer-to-Peer)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildVideoCallLayout() {
    final webrtc = WebRtcService();
    final hasRemote = webrtc.hasRemoteStream;

    final Widget remoteView = hasRemote
        ? RTCVideoView(
            webrtc.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF020617)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.mintLight,
                    border: Border.all(color: AppTheme.primaryTeal, width: 3.5),
                    image: widget.targetUserAvatar.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.targetUserAvatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: widget.targetUserAvatar.isEmpty
                      ? Center(
                          child: Text(
                            widget.targetUserName.isNotEmpty
                                ? widget.targetUserName.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  widget.targetUserName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _seconds > 0 ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _seconds > 0 ? _formatDuration(_seconds) : _callStatus,
                      style: TextStyle(
                        fontSize: 15,
                        color: _seconds > 0 ? const Color(0xFF4ADE80) : Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

    final Widget localView = _isCameraOn
        ? RTCVideoView(
            webrtc.localRenderer,
            mirror: _isFrontCamera,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_rounded, color: Colors.white60, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Kamera Mati',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          );

    return Stack(
      children: [
        // 1. Main Background Display (Remote or Local depending on _isSwapped)
        Positioned.fill(
          child: _isSwapped ? localView : remoteView,
        ),

        // 2. Top App Bar with Details, Encryption & Camera Selection
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: AppTheme.primaryTeal, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      hasRemote ? 'WebRTC P2P • Aktif' : 'Video Call • Menghubungkan',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Camera Switcher Button
              GestureDetector(
                onTap: () => _showCameraSelectionDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.cameraswitch_rounded, color: AppTheme.primaryTeal, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Pilih Kamera',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Picture-in-Picture (PiP) Floating Preview (Tap to Swap!)
        Positioned(
          top: 60,
          right: 16,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isSwapped = !_isSwapped;
              });
            },
            child: Container(
              width: 115,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryTeal, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isSwapped ? remoteView : localView,
                    ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSwapped ? widget.targetUserName : 'Anda',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.sync_rounded, color: Colors.white70, size: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Bottom Floating Glassmorphic Control Dock
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle Mic
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _isMuted ? const Color(0xFFEF4444) : Colors.white,
                    size: 26,
                  ),
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    WebRtcService().toggleMic(_isMuted);
                  },
                ),

                // Toggle Camera On/Off
                IconButton(
                  icon: Icon(
                    _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                    color: _isCameraOn ? AppTheme.primaryTeal : const Color(0xFFEF4444),
                    size: 26,
                  ),
                  tooltip: _isCameraOn ? 'Matikan Kamera' : 'Nyalakan Kamera',
                  onPressed: () {
                    setState(() => _isCameraOn = !_isCameraOn);
                    WebRtcService().toggleCamera(_isCameraOn);
                  },
                ),

                // Flip/Switch Camera
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 26),
                  tooltip: 'Ganti Kamera',
                  onPressed: () async {
                    setState(() => _isFrontCamera = !_isFrontCamera);
                    await WebRtcService().switchCamera();
                  },
                ),

                // Switch to Audio Call
                IconButton(
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white70, size: 24),
                  tooltip: 'Beralih ke Suara',
                  onPressed: () {
                    setState(() {
                      _mediaType = 'audio';
                    });
                    ref.read(callProvider.notifier).setMediaType('audio');
                  },
                ),

                // End Call Button
                GestureDetector(
                  onTap: _handleEndCall,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66EF4444),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? Colors.white)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black87 : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
