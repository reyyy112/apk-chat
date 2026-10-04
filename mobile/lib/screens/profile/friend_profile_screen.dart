import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../call/call_screen.dart';
import '../chats/components/full_screen_image_viewer.dart';
import 'all_photos_screen.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userAvatar;

  const FriendProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userAvatar,
  });

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.getUserProfile(widget.userId);
    if (mounted) {
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? widget.userName;
    final phone = _profile?['phoneNumber'] ?? widget.userPhone ?? '+6281298765432';
    final bio = _profile?['aboutStatus'] ?? _profile?['bio'] ?? 'Hey there! I am using QuickChat.';
    final isOnline = _profile?['isOnline'] ?? false;
    final isMutual = _profile?['isMutualContact'] ?? true;
    final avatarUrl = _profile?['avatarUrl'] ?? widget.userAvatar;
    final photosList = List<String>.from(_profile?['photos'] ?? []);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profil Teman',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar + Status Badge (Ketuk untuk perbesar)
                        GestureDetector(
                          onTap: () {
                            if (avatarUrl != null && avatarUrl.isNotEmpty) {
                              FullScreenImageViewer.show(
                                context,
                                imageUrl: avatarUrl,
                                senderName: name,
                              );
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.mintLight,
                                  border: Border.all(color: AppTheme.primaryTeal, width: 2.5),
                                  image: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(ApiService.normalizeUrl(avatarUrl)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: avatarUrl == null || avatarUrl.isEmpty
                                    ? Center(
                                        child: Text(
                                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Mutual Contact Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMutual ? AppTheme.mintLight : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isMutual ? Icons.verified_user_rounded : Icons.person_outline,
                                size: 14,
                                color: isMutual ? AppTheme.primaryTeal : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isMutual ? 'Mutual Friend' : 'Kontak Disimpan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isMutual ? AppTheme.primaryTeal : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone Number
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bio / About Status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Social Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('${_profile?['postsCount'] ?? 0}', 'POSTS'),
                            _buildStatItem('${_profile?['followersCount'] ?? 1}', 'FOLLOWERS'),
                            _buildStatItem('${_profile?['followingCount'] ?? 1}', 'FOLLOWING'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Quick Action Buttons (Kirim Pesan, Telepon & Video Call)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  final myId = ApiService.currentUserId;
                                  final targetId = widget.userId;
                                  final convId = ApiService.get1on1ConversationId(myId, targetId);
                                  context.push('/chat/$convId?name=${Uri.encodeComponent(name)}&targetId=$targetId&phone=${Uri.encodeComponent(phone)}');
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                label: const Text(
                                  'Kirim Pesan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // Panggilan Suara
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F766E),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      CallDialog.startCall(
                                        context,
                                        ref,
                                        targetUserId: widget.userId,
                                        targetUserName: name,
                                        targetUserAvatar: avatarUrl ?? '',
                                      );
                                    },
                                    icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                                    label: const Text(
                                      'Telepon',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Video Call
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      CallDialog.startVideoCall(
                                        context,
                                        ref,
                                        targetUserId: widget.userId,
                                        targetUserName: name,
                                        targetUserAvatar: avatarUrl ?? '',
                                      );
                                    },
                                    icon: const Icon(Icons.videocam_rounded, size: 18),
                                    label: const Text(
                                      'Video Call',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Photo Gallery Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Galeri Foto (${photosList.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (photosList.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AllPhotosScreen(
                                  initialPhotos: photosList.map((u) => {'url': u}).toList(),
                                  userId: widget.userId,
                                  userName: name,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Photo Gallery Grid or Empty State
                  if (photosList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.mintLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_outlined, size: 36, color: AppTheme.primaryTeal),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum Ada Foto',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$name belum mengunggah foto apa pun',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: photosList.length,
                      itemBuilder: (context, index) {
                        final url = photosList[index];
                        return _buildPhotoTile(url, name);
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoTile(String url, String name) {
    return GestureDetector(
      onTap: () {
        FullScreenImageViewer.show(
          context,
          imageUrl: url,
          senderName: name,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          ApiService.normalizeUrl(url),
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.mintLight,
            child: const Icon(Icons.broken_image_outlined, color: AppTheme.primaryTeal),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
