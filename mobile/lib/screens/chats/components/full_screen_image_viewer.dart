import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../profile/friend_profile_screen.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? senderName;
  final String? timestamp;
  final String? userId;
  final String? userPhone;
  final String? userAvatar;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.senderName,
    this.timestamp,
    this.userId,
    this.userPhone,
    this.userAvatar,
  });

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? senderName,
    String? timestamp,
    String? userId,
    String? userPhone,
    String? userAvatar,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) => FullScreenImageViewer(
          imageUrl: imageUrl,
          senderName: senderName,
          timestamp: timestamp,
          userId: userId,
          userPhone: userPhone,
          userAvatar: userAvatar,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Zoomable Image via InteractiveViewer
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.5,
                child: Hero(
                  tag: imageUrl,
                  child: Image.network(
                    ApiService.normalizeUrl(imageUrl),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0D9488),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                            SizedBox(height: 12),
                            Text(
                              'Gagal memuat gambar',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. Top Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (userId != null && userId!.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FriendProfileScreen(
                                  userId: userId!,
                                  userName: senderName ?? 'Teman',
                                  userPhone: userPhone,
                                  userAvatar: userAvatar,
                                ),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (senderName != null && senderName!.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    senderName!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (userId != null && userId!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Lihat Profil',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            if (timestamp != null && timestamp!.isNotEmpty)
                              Text(
                                timestamp!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
