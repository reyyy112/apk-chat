import 'package:flutter/material.dart';

class LocalCameraView extends StatelessWidget {
  final bool isCameraOn;
  final bool isFrontCamera;
  const LocalCameraView({super.key, required this.isCameraOn, this.isFrontCamera = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: isCameraOn ? const Color(0xFF4ADE80) : Colors.white60,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              isCameraOn ? 'Kamera Aktif' : 'Kamera Nonaktif',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
