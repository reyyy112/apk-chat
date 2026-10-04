import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AllPhotosScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialPhotos;
  final VoidCallback? onPhotosChanged;
  final String? userId;
  final String? userName;

  const AllPhotosScreen({
    super.key,
    required this.initialPhotos,
    this.onPhotosChanged,
    this.userId,
    this.userName,
  });

  @override
  State<AllPhotosScreen> createState() => _AllPhotosScreenState();
}

class _AllPhotosScreenState extends State<AllPhotosScreen> {
  late List<Map<String, dynamic>> _photos;
  bool _isLoading = false;

  bool get isOwner => widget.userId == null || widget.userId == ApiService.currentUserId;

  final List<Map<String, String>> _presetPhotos = const [
    {
      'name': 'Pemandangan Senja',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    },
    {
      'name': 'Kopi & Buku',
      'url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800',
    },
    {
      'name': 'Gunung & Alam',
      'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
    },
    {
      'name': 'Perjalanan Kota',
      'url': 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?w=800',
    },
    {
      'name': 'Fotografi Estetik',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
    },
    {
      'name': 'Arsitektur Minimalis',
      'url': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
    },
  ];

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() => _isLoading = true);
    final freshPhotos = widget.userId != null
        ? await ApiService.getUserPhotos(userId: widget.userId)
        : await ApiService.getUserPhotos();
    if (mounted) {
      setState(() {
        if (freshPhotos.isNotEmpty || widget.userId == null) {
          _photos = freshPhotos;
        }
        _isLoading = false;
      });
    }
  }

  void _showAddPhotoDialog() {
    final urlController = TextEditingController();
    final captionController = TextEditingController();
    String? selectedPreset;
    bool isUploadingPhoto = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryTeal, size: 26),
                          SizedBox(width: 10),
                          Text(
                            'Tambah Foto Baru',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Gallery Pick Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mintLight,
                        foregroundColor: AppTheme.primaryTeal,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                        ),
                      ),
                      onPressed: isUploadingPhoto
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                maxHeight: 1920,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setModalState(() => isUploadingPhoto = true);
                                final bytes = await image.readAsBytes();
                                final url = await ApiService.uploadImage(bytes: bytes, filename: image.name);
                                setModalState(() {
                                  if (url != null) {
                                    urlController.text = url;
                                    selectedPreset = null;
                                  }
                                  isUploadingPhoto = false;
                                });
                              }
                            },
                      icon: isUploadingPhoto
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal))
                          : const Icon(Icons.photo_library_rounded, size: 22),
                      label: Text(
                        isUploadingPhoto ? 'Mengunggah dari galeri...' : 'Pilih Foto dari Galeri Perangkat',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Preview
                  if (urlController.text.isNotEmpty) ...[
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primaryTeal, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        ApiService.normalizeUrl(urlController.text),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('atau pilih foto preset', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preset horizontal selector
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final preset = _presetPhotos[idx];
                        final isSelected = selectedPreset == preset['url'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPreset = preset['url'];
                              urlController.text = preset['url']!;
                            });
                          },
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    preset['url']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                  ),
                                  if (isSelected)
                                    Container(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                                      child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'URL Foto',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        selectedPreset = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: captionController,
                    decoration: InputDecoration(
                      labelText: 'Caption (Opsional)',
                      hintText: 'Tuliskan deskripsi foto...',
                      prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final url = urlController.text.trim();
                        if (url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Masukkan URL foto terlebih dahulu')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        final res = await ApiService.addUserPhoto(
                          url: url,
                          caption: captionController.text.trim(),
                        );

                        if (res != null && res['success'] == true) {
                          await _fetchPhotos();
                          widget.onPhotosChanged?.call();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto berhasil ditambahkan!'),
                                backgroundColor: AppTheme.primaryTeal,
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal menambahkan foto')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text(
                        'Upload Foto',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhotoDetail(Map<String, dynamic> photo) {
    final photoId = photo['id']?.toString() ?? '';
    final url = photo['url'] ?? '';
    final caption = photo['caption'] ?? '';
    final createdAt = photo['createdAt'] != null
        ? photo['createdAt'].toString().substring(0, 10)
        : '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  InteractiveViewer(
                    child: Image.network(
                      ApiService.normalizeUrl(url),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 320,
                      errorBuilder: (_, __, ___) => Container(
                        height: 320,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caption.isNotEmpty) ...[
                      Text(
                        caption,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (createdAt.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Diunggah pada $createdAt',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (photoId.isNotEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Hapus Foto?'),
                                  content: const Text('Foto ini akan dihapus permanen dari profil Anda.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                Navigator.pop(ctx);
                                final deleted = await ApiService.deleteUserPhoto(photoId);
                                if (deleted) {
                                  await _fetchPhotos();
                                  widget.onPhotosChanged?.call();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Foto berhasil dihapus')),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Hapus Foto'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userName != null ? 'Foto ${widget.userName} (${_photos.length})' : 'Semua Foto (${_photos.length})',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              tooltip: 'Tambah Foto',
              onPressed: _showAddPhotoDialog,
            ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              onPressed: _showAddPhotoDialog,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Tambah Foto', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : _photos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.mintLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 46,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Belum Ada Foto',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unggah momen dan foto terbaik Anda untuk mempercantik profil!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _showAddPhotoDialog,
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: const Text('Unggah Foto Pertama', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryTeal,
                  onRefresh: _fetchPhotos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      final url = photo['url'] ?? '';
                      return GestureDetector(
                        onTap: () => _showPhotoDetail(photo),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                ApiService.normalizeUrl(url),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.mintLight,
                                  child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.primaryTeal),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.6),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Text(
                                    photo['caption'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
