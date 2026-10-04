// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class LocalCameraView extends StatefulWidget {
  final bool isCameraOn;
  final bool isFrontCamera;
  const LocalCameraView({super.key, required this.isCameraOn, this.isFrontCamera = true});

  @override
  State<LocalCameraView> createState() => _LocalCameraViewState();
}

class _LocalCameraViewState extends State<LocalCameraView> {
  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  String _viewId = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'camera-view-${DateTime.now().microsecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '16px';

      if (widget.isFrontCamera) {
        _videoElement!.style.transform = 'scaleX(-1)';
      }

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) => _videoElement!);

      if (html.window.navigator.mediaDevices != null) {
        final stream = await html.window.navigator.mediaDevices!.getUserMedia({
          'video': true,
          'audio': false,
        });
        _stream = stream;
        _videoElement!.srcObject = stream;
      }
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera init/permission notice: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void didUpdateWidget(LocalCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCameraOn != widget.isCameraOn) {
      if (_stream != null) {
        for (final track in _stream!.getVideoTracks()) {
          track.enabled = widget.isCameraOn;
        }
      }
    }
    if (oldWidget.isFrontCamera != widget.isFrontCamera && _videoElement != null) {
      _videoElement!.style.transform = widget.isFrontCamera ? 'scaleX(-1)' : 'none';
    }
  }

  @override
  void dispose() {
    try {
      _stream?.getTracks().forEach((track) => track.stop());
      _videoElement?.srcObject = null;
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCameraOn || _hasError || _videoElement == null) {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white60, size: 28),
              SizedBox(height: 4),
              Text(
                'Kamera Nonaktif',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }

    return HtmlElementView(viewType: _viewId);
  }
}
