import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcService {
  static final WebRtcService _instance = WebRtcService._internal();
  factory WebRtcService() => _instance;
  WebRtcService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool _isRenderersInitialized = false;
  bool _isRemoteDescriptionSet = false;
  final List<RTCIceCandidate> _candidateQueue = [];

  // Callbacks
  Function(MediaStream stream)? onRemoteStream;
  Function(RTCPeerConnectionState state)? onConnectionStateChange;
  Function(RTCIceCandidate candidate)? onIceCandidate;

  static const Map<String, dynamic> _iceConfiguration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {
        'urls': [
          'turn:openrelay.metered.ca:80',
          'turn:openrelay.metered.ca:443',
          'turn:openrelay.metered.ca:443?transport=tcp',
          'turns:openrelay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  static Map<String, dynamic> _getConstraints({required bool isVideo}) => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': isVideo,
    },
    'optional': [],
  };

  Future<void> initRenderers() async {
    if (!_isRenderersInitialized) {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _isRenderersInitialized = true;
    }
  }

  List<MediaDeviceInfo> _cachedVideoDevices = [];
  List<MediaDeviceInfo> get availableVideoDevices => _cachedVideoDevices;

  Future<List<MediaDeviceInfo>> getAvailableCameras() async {
    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      _cachedVideoDevices = devices.where((d) {
        final label = d.label.toLowerCase();
        final isIR = label.contains(' ir ') ||
            label.contains('ir ') ||
            label.contains('ir_') ||
            label.contains('ir uvc') ||
            label.contains('infrared');
        return d.kind == 'videoinput' && !isIR;
      }).toList();
      return _cachedVideoDevices;
    } catch (_) {
      return [];
    }
  }

  /// Create local media stream (microphone and/or camera)
  Future<MediaStream> startLocalMedia({required bool isVideo, String? selectedDeviceId}) async {
    await initRenderers();

    String? preferredCameraId = selectedDeviceId;
    if (isVideo && preferredCameraId == null) {
      try {
        final videoDevices = await getAvailableCameras();
        debugPrint('[WebRTC] Available video devices: ${videoDevices.map((d) => "${d.label} [${d.deviceId}]").toList()}');

        MediaDeviceInfo? bestCandidate;
        int bestScore = -1;

        // Strictly prioritize real local laptop webcam / phone native camera
        for (final device in videoDevices) {
          final label = device.label.toLowerCase();

          // Reject virtual / phone-mirroring cameras (e.g. Phone Link, DroidCam, etc.)
          final isPhoneOrVirtual = label.contains('virtual') ||
              label.contains('droidcam') ||
              label.contains('iriun') ||
              label.contains('phone') ||
              label.contains('camo') ||
              label.contains('link to') ||
              label.contains('connected device');
          if (isPhoneOrVirtual) {
            debugPrint('[WebRTC] Ignoring virtual/phone-link camera: ${device.label}');
            continue;
          }

          int score = 0;
          if (label.contains('fhd') || label.contains('full hd')) score += 50;
          if (label.contains('integrated') || label.contains('built-in') || label.contains('internal')) score += 40;
          if (label.contains('webcam') || label.contains('uvc')) score += 30;
          if (label.contains('front') || label.contains('depan') || label.contains('facing front')) score += 35;
          if (label.contains('camera')) score += 10;

          if (score > bestScore) {
            bestScore = score;
            bestCandidate = device;
          }
        }

        if (bestCandidate != null) {
          preferredCameraId = bestCandidate.deviceId;
          debugPrint('[WebRTC] Selected preferred device webcam: ${bestCandidate.label} (Score: $bestScore)');
        } else if (videoDevices.isNotEmpty) {
          preferredCameraId = videoDevices.first.deviceId;
          debugPrint('[WebRTC] Fallback to first available camera: ${videoDevices.first.label}');
        }
      } catch (e) {
        debugPrint('[WebRTC] Error enumerating devices: $e');
      }
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': isVideo
          ? (preferredCameraId != null
              ? {
                  'deviceId': preferredCameraId,
                  'facingMode': 'user',
                }
              : {
                  'facingMode': 'user',
                })
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
      return _localStream!;
    } catch (e) {
      debugPrint('[WebRTC] Error getting user media: $e');
      // Fallback to audio only if camera fails
      if (isVideo) {
        debugPrint('[WebRTC] Falling back to audio-only user media');
        _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
        localRenderer.srcObject = _localStream;
        return _localStream!;
      }
      rethrow;
    }
  }

  /// Initialize RTCPeerConnection and attach tracks & listeners
  Future<void> _createPeerConnection({required bool isVideo}) async {
    _isRemoteDescriptionSet = false;
    _candidateQueue.clear();

    _peerConnection = await createPeerConnection(_iceConfiguration, _getConstraints(isVideo: isVideo));

    // Listen for ICE connection state changes
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[WebRTC] Connection state changed: $state');
      onConnectionStateChange?.call(state);
    };

    // Listen for generated ICE Candidates to send to peer
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        debugPrint('[WebRTC] Generated ICE candidate: ${candidate.sdpMid}');
        onIceCandidate?.call(candidate);
      }
    };

    // Listen for incoming remote tracks / stream (supports both legacy and Unified Plan)
    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      debugPrint('[WebRTC] Remote track received: ${event.track.kind}, streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      } else {
        _remoteStream ??= await createLocalMediaStream('remote_stream');
        _remoteStream!.addTrack(event.track);
      }
      remoteRenderer.srcObject = _remoteStream;
      onRemoteStream?.call(_remoteStream!);
    };

    // Add local tracks to peer connection
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  /// Create and set SDP Offer (for Caller)
  Future<RTCSessionDescription> createOffer({required bool isVideo}) async {
    await startLocalMedia(isVideo: isVideo);
    await _createPeerConnection(isVideo: isVideo);

    final RTCSessionDescription offer = await _peerConnection!.createOffer(_getConstraints(isVideo: isVideo));
    await _peerConnection!.setLocalDescription(offer);
    debugPrint('[WebRTC] Created and set local offer (isVideo: $isVideo)');
    return offer;
  }

  /// Create and set SDP Answer from incoming Offer (for Callee)
  Future<RTCSessionDescription> createAnswer({
    required Map<String, dynamic> remoteOffer,
    required bool isVideo,
  }) async {
    await startLocalMedia(isVideo: isVideo);
    await _createPeerConnection(isVideo: isVideo);

    final description = RTCSessionDescription(
      remoteOffer['sdp']?.toString(),
      remoteOffer['type']?.toString() ?? 'offer',
    );
    await _peerConnection!.setRemoteDescription(description);
    _isRemoteDescriptionSet = true;
    debugPrint('[WebRTC] Set remote offer description');

    // Flush any ICE candidates that arrived before remote description was set
    await _flushQueuedCandidates();

    final RTCSessionDescription answer = await _peerConnection!.createAnswer(_getConstraints(isVideo: isVideo));
    await _peerConnection!.setLocalDescription(answer);
    debugPrint('[WebRTC] Created and set local answer (isVideo: $isVideo)');
    return answer;
  }

  /// Set remote answer received from peer (Caller receives this)
  Future<void> setRemoteAnswer(Map<String, dynamic> remoteAnswer) async {
    if (_peerConnection == null) return;

    final description = RTCSessionDescription(
      remoteAnswer['sdp']?.toString(),
      remoteAnswer['type']?.toString() ?? 'answer',
    );
    await _peerConnection!.setRemoteDescription(description);
    _isRemoteDescriptionSet = true;
    debugPrint('[WebRTC] Set remote answer description');

    await _flushQueuedCandidates();
  }

  /// Add incoming ICE candidate from peer
  Future<void> addIceCandidate(Map<String, dynamic> candidateData) async {
    final candidate = RTCIceCandidate(
      candidateData['candidate']?.toString(),
      candidateData['sdpMid']?.toString(),
      candidateData['sdpMLineIndex'] is int
          ? candidateData['sdpMLineIndex']
          : int.tryParse(candidateData['sdpMLineIndex']?.toString() ?? '0') ?? 0,
    );

    if (_peerConnection != null && _isRemoteDescriptionSet) {
      debugPrint('[WebRTC] Adding candidate directly');
      await _peerConnection!.addCandidate(candidate);
    } else {
      debugPrint('[WebRTC] Queueing candidate (waiting for remote description)');
      _candidateQueue.add(candidate);
    }
  }

  Future<void> _flushQueuedCandidates() async {
    if (_peerConnection == null) return;
    for (final candidate in _candidateQueue) {
      try {
        debugPrint('[WebRTC] Flushing queued candidate');
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('[WebRTC] Error adding queued candidate: $e');
      }
    }
    _candidateQueue.clear();
  }

  /// Controls: Mute/Unmute microphone
  void toggleMic(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  /// Controls: Enable/Disable camera
  void toggleCamera(bool isCameraOn) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = isCameraOn;
      }
    }
  }

  /// Controls: Switch camera (supports mobile front/back + web/desktop device switching)
  Future<void> switchCamera({String? targetDeviceId}) async {
    if (_localStream == null) return;

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        final videoDevices = await getAvailableCameras();
        if (videoDevices.isNotEmpty) {
          String nextDeviceId = targetDeviceId ?? '';
          if (nextDeviceId.isEmpty) {
            final currentTracks = _localStream!.getVideoTracks();
            final currentTrackId = currentTracks.isNotEmpty ? currentTracks.first.getSettings()['deviceId'] : null;
            final currentIndex = videoDevices.indexWhere((d) => d.deviceId == currentTrackId);
            final nextIndex = (currentIndex + 1) % videoDevices.length;
            nextDeviceId = videoDevices[nextIndex].deviceId;
          }

          if (nextDeviceId.isNotEmpty) {
            for (final t in _localStream!.getVideoTracks()) {
              await t.stop();
              _localStream!.removeTrack(t);
            }

            final newStream = await navigator.mediaDevices.getUserMedia({
              'audio': false,
              'video': {'deviceId': nextDeviceId},
            });

            if (newStream.getVideoTracks().isNotEmpty) {
              final newTrack = newStream.getVideoTracks().first;
              _localStream!.addTrack(newTrack);

              if (_peerConnection != null) {
                final senders = await _peerConnection!.getSenders();
                for (final sender in senders) {
                  if (sender.track?.kind == 'video') {
                    await sender.replaceTrack(newTrack);
                  }
                }
              }
              localRenderer.srcObject = _localStream;
            }
          }
        }
      } catch (e) {
        debugPrint('[WebRTC] Error switching camera on desktop/web: $e');
      }
    } else {
      // Mobile native (Android / iOS)
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  /// Controls: Toggle speakerphone / earpiece
  void toggleSpeaker(bool isSpeaker) {
    if (_localStream != null) {
      Helper.setSpeakerphoneOn(isSpeaker);
    }
  }

  /// Clean up all WebRTC resources upon call termination
  Future<void> cleanUp() async {
    debugPrint('[WebRTC] Cleaning up WebRtcService');
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }
      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) {
          await track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      _isRemoteDescriptionSet = false;
      _candidateQueue.clear();
    } catch (e) {
      debugPrint('[WebRTC] Exception during cleanup: $e');
    }
  }

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get hasRemoteStream => _remoteStream != null && _remoteStream!.getTracks().isNotEmpty;
}
