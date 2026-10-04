import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../profile/friend_profile_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final List<Map<String, dynamic>> stories;
  final bool isMyStory;
  final String? userId;

  const StoryViewerScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.stories,
    this.isMyStory = false,
    this.userId,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startProgress();
    _markCurrentStoryViewed();
  }

  void _markCurrentStoryViewed() {
    if (widget.stories.isNotEmpty && !widget.isMyStory) {
      final storyId = widget.stories[_currentIndex]['id'];
      if (storyId != null) {
        ApiService.viewStory(storyId.toString());
      }
    }
  }

  void _startProgress() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.01; // 5 seconds per story
          if (_progress >= 1.0) {
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0.0;
      });
      _markCurrentStoryViewed();
      _startProgress();
    } else {
      _timer?.cancel();
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0.0;
      });
      _markCurrentStoryViewed();
      _startProgress();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showViewersSheet(BuildContext context, Map<String, dynamic> story) async {
    _timer?.cancel(); // Pause auto-progress when viewing viewers

    final storyId = story['id']?.toString() ?? '';
    List<Map<String, dynamic>> viewers = List<Map<String, dynamic>>.from(story['viewers'] ?? []);

    // Fetch latest viewers live
    if (storyId.isNotEmpty) {
      final liveViewers = await ApiService.getStoryViewers(storyId);
      if (liveViewers.isNotEmpty) {
        viewers = liveViewers;
      }
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility_rounded, color: AppTheme.primaryTeal, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Dilihat oleh (${viewers.length})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Hapus Status',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            title: const Text('Hapus Status?'),
                            content: const Text('Status ini akan dihapus permanen untuk semua orang.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && storyId.isNotEmpty) {
                          final ok = await ApiService.deleteStory(storyId);
                          if (ok && mounted) {
                            Navigator.pop(ctx); // close bottom sheet
                            Navigator.of(context).pop(true); // close viewer and refresh
                          }
                        }
                      },
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Belum ada pemirsa.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Teman yang melihat statusmu akan muncul di sini.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: viewers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final v = viewers[idx];
                    final name = v['name'] ?? 'Teman';
                    final avatarUrl = v['avatarUrl'] ?? '';
                    final phone = v['phoneNumber'] ?? '';
                    final viewedAt = v['viewedAt']?.toString() ?? '';

                    String timeStr = 'Baru saja';
                    if (viewedAt.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(viewedAt).toLocal();
                        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      } catch (_) {}
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryTeal,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(phone.isNotEmpty ? phone : 'Kontak Teman', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

    if (mounted) {
      _startProgress(); // Resume progress after sheet is dismissed
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories.isNotEmpty ? widget.stories[_currentIndex] : <String, dynamic>{};
    final mediaUrl = currentStory['mediaUrl'] ?? '';
    final caption = currentStory['caption'] ?? '';
    final viewersCount = currentStory['viewersCount'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (widget.isMyStory && (details.primaryVelocity ?? 0) < -100) {
              _showViewersSheet(context, currentStory);
            }
          },
          child: Stack(
            children: [
              // Background / Media Image
              GestureDetector(
                onTapUp: (details) {
                  final width = MediaQuery.of(context).size.width;
                  if (details.globalPosition.dx < width / 3) {
                    _previousStory();
                  } else {
                    _nextStory();
                  }
                },
                child: Center(
                  child: mediaUrl.isNotEmpty
                      ? Image.network(
                          ApiService.normalizeUrl(mediaUrl),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.primaryTeal,
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              caption,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // Top Progress Bars
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: List.generate(widget.stories.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: index < _currentIndex
                              ? 1.0
                              : index == _currentIndex
                                  ? _progress
                                  : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Top Header: User Info & Close Button
              Positioned(
                top: 22,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!widget.isMyStory && widget.userId != null) {
                          _timer?.cancel();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FriendProfileScreen(
                                userId: widget.userId!,
                                userName: widget.userName,
                                userAvatar: widget.userAvatar,
                              ),
                            ),
                          ).then((_) {
                            if (mounted) _startProgress();
                          });
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.primaryTeal,
                            backgroundImage: widget.userAvatar.isNotEmpty ? NetworkImage(ApiService.normalizeUrl(widget.userAvatar)) : null,
                            child: widget.userAvatar.isEmpty
                                ? Text(widget.userName.isNotEmpty ? widget.userName.substring(0, 1).toUpperCase() : 'U', style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const Text(
                                'Status 24 Jam • Lihat profil',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Caption at bottom (if media is image)
              if (mediaUrl.isNotEmpty && caption.isNotEmpty)
                Positioned(
                  bottom: widget.isMyStory ? 74 : 30,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

              // Real-time Viewers Bar (For Creator)
              if (widget.isMyStory)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showViewersSheet(context, currentStory),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$viewersCount Pemirsa',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

