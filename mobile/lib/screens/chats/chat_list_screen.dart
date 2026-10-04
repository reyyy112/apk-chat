import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../call/call_screen.dart';
import '../profile/friend_profile_screen.dart';
import '../story/story_viewer_screen.dart';
import '../../providers/socket_provider.dart';



class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _myProfile;
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final contactsFuture = ApiService.getContacts();
    final storiesFuture = ApiService.getStories();
    final callsFuture = ApiService.getCalls();
    final requestsFuture = ApiService.getFriendRequests();
    final groupsFuture = ApiService.getGroups();
    final profileFuture = ApiService.getMyProfile();

    final results = await Future.wait([contactsFuture, storiesFuture, callsFuture, requestsFuture, groupsFuture, profileFuture]);

    if (mounted) {
      setState(() {
        _contacts = results[0] as List<Map<String, dynamic>>;
        _stories = results[1] as List<Map<String, dynamic>>;
        _calls = results[2] as List<Map<String, dynamic>>;
        final reqs = results[3] as Map<String, dynamic>;
        _incomingRequests = List<Map<String, dynamic>>.from(reqs['incoming'] ?? []);
        _groups = results[4] as List<Map<String, dynamic>>;
        _myProfile = results[5] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _openStoryCreationDialog() {
    final textController = TextEditingController();
    final urlController = TextEditingController();
    Uint8List? selectedImageBytes;
    // ignore: unused_local_variable
    String? selectedImageName;
    String? uploadedImageUrl;
    bool isUploading = false;
    bool isSubmitting = false;
    bool showUrlInput = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickImage() async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                maxHeight: 1920,
                imageQuality: 85,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setModalState(() {
                  selectedImageBytes = bytes;
                  selectedImageName = picked.name;
                  isUploading = true;
                });

                final uploadedUrl = await ApiService.uploadImage(
                  bytes: bytes,
                  filename: picked.name,
                );

                setModalState(() {
                  uploadedImageUrl = uploadedUrl;
                  isUploading = false;
                });
              }
            } catch (e) {
              setModalState(() => isUploading = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: Colors.redAccent),
                );
              }
            }
          }

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.mintLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buat Status Baru',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Status aktif 24 jam untuk teman Anda',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Image Selection / Preview Card
                  if (selectedImageBytes != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            color: Colors.black,
                            child: Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(color: Colors.white),
                                    SizedBox(height: 10),
                                    Text('Mengunggah foto...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onPressed: isUploading
                                  ? null
                                  : () {
                                      setModalState(() {
                                        selectedImageBytes = null;
                                        selectedImageName = null;
                                        uploadedImageUrl = null;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: isUploading ? null : pickImage,
                        icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.primaryTeal),
                        label: const Text('Ganti Foto dari Galeri', style: TextStyle(color: AppTheme.primaryTeal)),
                      ),
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_library_rounded, color: AppTheme.primaryTeal, size: 30),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Pilih Foto dari Galeri Perangkat',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ketuk di sini untuk mengambil foto asli',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setModalState(() => showUrlInput = !showUrlInput);
                        },
                        child: Text(
                          showUrlInput ? 'Sembunyikan Input URL' : 'Atau masukkan URL Gambar langsung',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primaryTeal),
                        ),
                      ),
                    ),
                    if (showUrlInput) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/foto.jpg',
                          prefixIcon: const Icon(Icons.link, color: AppTheme.primaryTeal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Tulis caption atau pesan status...',
                      prefixIcon: const Icon(Icons.edit_note, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (isUploading || isSubmitting)
                        ? null
                        : () async {
                            final finalMedia = uploadedImageUrl ?? urlController.text.trim();
                            final caption = textController.text.trim();

                            if (finalMedia.isEmpty && caption.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Pilih foto atau tulis teks status terlebih dahulu')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final success = await ApiService.createStory(
                              mediaUrl: finalMedia,
                              caption: caption,
                            );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }

                            if (success) {
                              _loadAllData();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Status berhasil dibagikan! Aktif selama 24 jam.')),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gagal membagikan status'), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Bagikan Status',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  void _openAddFriendModal({String? initialPhone}) {
    final phoneController = TextEditingController(text: initialPhone ?? '');
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void performSearch(String query) async {
            final trimmed = query.trim();
            if (trimmed.isEmpty) return;

            setModalState(() {
              isSearching = true;
              hasSearched = true;
            });

            final results = await ApiService.searchContactByPhone(trimmed);

            if (ctx.mounted) {
              setModalState(() {
                searchResults = results;
                isSearching = false;
              });
            }
          }

          if (initialPhone != null && initialPhone.isNotEmpty && !hasSearched && RegExp(r'^\d+$').hasMatch(initialPhone.trim())) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted && !hasSearched) {
                performSearch(initialPhone);
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_search_rounded, color: AppTheme.primaryTeal, size: 26),
                        SizedBox(width: 8),
                        Text(
                          'Cari Nomor Teman',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan nomor telepon yang didaftarkan teman Anda untuk menambahkan kontak.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // Search Input & Action Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        onSubmitted: performSearch,
                        decoration: InputDecoration(
                          hintText: 'Cth: +6281298765432 atau 0812...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryTeal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () => performSearch(phoneController.text),
                      child: const Text('Cari', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Results Area
                if (isSearching)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
                  )
                else if (!hasSearched)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.contact_phone_outlined, size: 54, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text(
                            'Ketik nomor telepon teman Anda\nlalu klik tombol "Cari".',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (searchResults.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_off_outlined, size: 54, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text(
                            'Nomor tidak ditemukan!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pastikan teman Anda sudah mendaftar di QuickChat dengan nomor tersebut.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, idx) {
                        final u = searchResults[idx];
                        final isMutual = u['isMutualContact'] == true;
                        final isAdded = u['isAdded'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => FriendProfileScreen(
                                        userId: u['id']?.toString() ?? '',
                                        userName: u['name'] ?? 'Pengguna',
                                        userPhone: u['phoneNumber'] ?? '',
                                        userAvatar: u['avatarUrl'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.mintLight,
                                  backgroundImage: u['avatarUrl'] != null && u['avatarUrl'].isNotEmpty
                                      ? NetworkImage(ApiService.normalizeUrl(u['avatarUrl']))
                                      : null,
                                  child: u['avatarUrl'] == null || u['avatarUrl'].isEmpty
                                      ? Text(
                                          u['name']?.substring(0, 1) ?? 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          u['name'] ?? 'Pengguna',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (isMutual) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified, size: 14, color: AppTheme.primaryTeal),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      u['phoneNumber'] ?? '',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMutual
                                          ? 'Mutual Friends (Saling Menyimpan)'
                                          : isAdded
                                              ? 'Kontak Disimpan (Menunggu Teman)'
                                              : 'Belum Ditambahkan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isMutual
                                            ? const Color(0xFF10B981)
                                            : isAdded
                                                ? const Color(0xFFF59E0B)
                                                : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMutual
                                      ? const Color(0xFF10B981)
                                      : AppTheme.primaryTeal,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                onPressed: isMutual
                                    ? () {
                                        Navigator.pop(context);
                                        final myId = ApiService.currentUserId;
                                        final targetId = u['id'];
                                        final convId = ApiService.get1on1ConversationId(myId, targetId);
                                        context.push('/chat/$convId?name=${Uri.encodeComponent(u['name'] ?? 'Teman')}&targetId=$targetId&phone=${Uri.encodeComponent(u['phoneNumber'] ?? '')}');
                                      }
                                    : () async {
                                        final res = await ApiService.addContact(targetUserId: u['id']);
                                        if (res != null) {
                                          ref.read(contactSyncProvider.notifier).state++;
                                          final mutual = res['contact']?['isMutualContact'] == true;
                                          setModalState(() {
                                            u['isMutualContact'] = mutual;
                                            u['isAdded'] = true;
                                          });
                                          _loadAllData();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                mutual
                                                    ? '🎉 Selamat! Kalian berdua sekarang resmi Mutual Friends!'
                                                    : 'Kontak disimpan! Menunggu teman menambahkan nomor Anda.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: Text(
                                  isMutual
                                      ? 'Chat'
                                      : isAdded
                                          ? 'Tersimpan'
                                          : '+ Tambah',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openCreateGroupModal() {
    final groupNameController = TextEditingController();
    final searchController = TextEditingController();
    final Set<String> selectedUserIds = <String>{};
    Uint8List? groupPhotoBytes;
    String? uploadedGroupPhotoUrl;
    bool isUploadingPhoto = false;
    bool isCreating = false;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickGroupPhoto() async {
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 800,
                maxHeight: 800,
                imageQuality: 85,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setModalState(() {
                  groupPhotoBytes = bytes;
                  isUploadingPhoto = true;
                });
                final url = await ApiService.uploadImage(bytes: bytes, filename: picked.name);
                setModalState(() {
                  uploadedGroupPhotoUrl = url;
                  isUploadingPhoto = false;
                });
              }
            } catch (e) {
              setModalState(() => isUploadingPhoto = false);
            }
          }

          final filteredContacts = _contacts.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final phone = (c['phoneNumber'] ?? '').toString().toLowerCase();
            final q = searchQuery.toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.mintLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.group_add_rounded, color: AppTheme.primaryTeal, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Buat Grup Baru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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

                // Group Info (Name & Photo)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: isUploadingPhoto ? null : pickGroupPhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.mintLight,
                            backgroundImage: groupPhotoBytes != null
                                ? MemoryImage(groupPhotoBytes!)
                                : (uploadedGroupPhotoUrl != null && uploadedGroupPhotoUrl!.isNotEmpty
                                    ? NetworkImage(uploadedGroupPhotoUrl!)
                                    : null) as ImageProvider?,
                            child: (groupPhotoBytes == null && (uploadedGroupPhotoUrl == null || uploadedGroupPhotoUrl!.isEmpty))
                                ? const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryTeal, size: 26)
                                : null,
                          ),
                          if (isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: groupNameController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Nama Grup (misal: Tim Proyek)...',
                          labelText: 'Nama Grup',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Selected Members horizontal chips
                if (selectedUserIds.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Anggota Dipilih (${selectedUserIds.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() => selectedUserIds.clear()),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                        child: const Text('Hapus Semua', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: selectedUserIds.map((uid) {
                        final contact = _contacts.firstWhere(
                          (c) => c['id'] == uid,
                          orElse: () => {'name': 'Anggota', 'avatarUrl': ''},
                        );
                        final name = contact['name'] ?? 'Anggota';
                        final avatarUrl = contact['avatarUrl'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.mintLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFB4E3DE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primaryTeal,
                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl.isEmpty
                                    ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white))
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => setModalState(() => selectedUserIds.remove(uid)),
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Search field for contacts
                TextField(
                  controller: searchController,
                  onChanged: (val) => setModalState(() => searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari teman untuk ditambahkan...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Contact list header
                const Text(
                  'Pilih dari Kontak Teman:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),

                // Contacts list
                Expanded(
                  child: filteredContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 44, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 8),
                              Text(
                                _contacts.isEmpty ? 'Belum ada kontak teman tersimpan' : 'Kontak tidak ditemukan',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              if (_contacts.isEmpty) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Tambahkan kontak teman terlebih dahulu di tab Pesan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredContacts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final contact = filteredContacts[idx];
                            final uid = contact['id'] as String? ?? '';
                            final name = contact['name'] ?? 'Teman';
                            final phone = contact['phoneNumber'] ?? '';
                            final avatarUrl = contact['avatarUrl'] ?? '';
                            final isSelected = selectedUserIds.contains(uid);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.mintLight,
                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl.isEmpty
                                    ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal))
                                    : null,
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              trailing: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedUserIds.remove(uid);
                                  } else {
                                    selectedUserIds.add(uid);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  onPressed: (groupNameController.text.trim().isNotEmpty && selectedUserIds.isNotEmpty && !isCreating)
                      ? () async {
                          setModalState(() => isCreating = true);
                          final groupName = groupNameController.text.trim();
                          final newGroup = await ApiService.createGroup(
                            name: groupName,
                            avatar: uploadedGroupPhotoUrl,
                            participantIds: selectedUserIds.toList(),
                          );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (newGroup != null && newGroup['id'] != null) {
                            _loadAllData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Grup "$groupName" berhasil dibuat!')),
                              );
                              final gid = newGroup['id'];
                              context.push('/chat/$gid?name=${Uri.encodeComponent(groupName)}&targetId=$gid&isGroup=true');
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal membuat grup'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        }
                      : null,
                  child: isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          selectedUserIds.isEmpty
                              ? 'Pilih Anggota Terlebih Dahulu'
                              : 'Buat Grup (${selectedUserIds.length} Anggota)',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openFriendRequestsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryTeal, size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'Permintaan Pertemanan (${_incomingRequests.length})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Terima permintaan di bawah untuk menjadi Mutual Friends dan mulai obrolan real-time.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              if (_incomingRequests.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Tidak ada permintaan pertemanan yang tertunda', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _incomingRequests.length,
                    itemBuilder: (context, idx) {
                      final req = _incomingRequests[idx];
                      final rName = req['name'] ?? 'Pengguna';
                      final rPhone = req['phoneNumber'] ?? '';
                      final rId = req['id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FriendProfileScreen(
                                      userId: req['userId']?.toString() ?? req['id']?.toString() ?? '',
                                      userName: rName,
                                      userPhone: rPhone,
                                      userAvatar: req['avatarUrl'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.mintLight,
                                backgroundImage: req['avatarUrl'] != null && req['avatarUrl'] != ''
                                    ? NetworkImage(ApiService.normalizeUrl(req['avatarUrl']))
                                    : null,
                                child: (req['avatarUrl'] == null || req['avatarUrl'] == '')
                                    ? Text(
                                        rName.isNotEmpty ? rName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(rPhone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                final success = await ApiService.acceptFriendRequest(rId);
                                if (success) {
                                  ref.read(contactSyncProvider.notifier).state++;
                                  setModalState(() {
                                    _incomingRequests.removeAt(idx);
                                  });
                                  _loadAllData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Sekarang Anda berteman dengan $rName!'), backgroundColor: AppTheme.primaryTeal),
                                    );
                                  }
                                  if (_incomingRequests.isEmpty && Navigator.canPop(ctx)) {
                                    Navigator.pop(ctx);
                                  }
                                }
                              },
                              child: const Text('Terima', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                minimumSize: Size.zero,
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () async {
                                final success = await ApiService.rejectFriendRequest(rId);
                                if (success) {
                                  ref.read(contactSyncProvider.notifier).state++;
                                  setModalState(() {
                                    _incomingRequests.removeAt(idx);
                                  });
                                  _loadAllData();
                                }
                              },
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
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
    ref.listen<int>(contactSyncProvider, (prev, next) {
      if (mounted) _loadAllData();
    });

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            _searchQuery = '';
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryTeal,
          elevation: 0,
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Tutup Pencarian',
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Cari pesan atau kontak...'
                        : _tabController.index == 1
                            ? 'Cari grup...'
                            : 'Cari riwayat panggilan...',
                    hintStyle: const TextStyle(color: Colors.white70, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                )
              : const Text(
                  'All Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          actions: _isSearching
              ? [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      tooltip: 'Hapus Pencarian',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                    tooltip: 'Tambah Kontak & Teman',
                    onPressed: _openAddFriendModal,
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    tooltip: 'Cari',
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: const [
              Tab(text: 'Message'),
              Tab(text: 'Group'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMessageTab(),
                  _buildGroupTab(),
                  _buildCallsTab(),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: Colors.white,
          tooltip: _tabController.index == 1 ? 'Buat Grup Baru' : 'Mulai Obrolan Baru',
          onPressed: _tabController.index == 1 ? _openCreateGroupModal : _openAddFriendModal,
          child: Icon(_tabController.index == 1 ? Icons.group_add_rounded : Icons.chat_bubble_rounded),
        ),
      ),
    );
  }

  Widget _buildMessageTab() {
    final filteredContacts = _searchQuery.isEmpty
        ? _contacts
        : _contacts.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final phone = (c['phoneNumber'] ?? '').toString().toLowerCase();
            final about = (c['aboutStatus'] ?? '').toString().toLowerCase();
            final lastMsg = (c['lastMessage']?['content'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || phone.contains(_searchQuery) || about.contains(_searchQuery) || lastMsg.contains(_searchQuery);
          }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primaryTeal,
      child: ListView(
        children: [
          // ── Horizontal Story Section (Hanya tampil saat tidak mencari) ──
          if (_searchQuery.isEmpty)
            Container(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            height: 115,
            child: Builder(
              builder: (context) {
                // Identify current user's story group vs friend story groups
                final myStoryIndex = _stories.indexWhere((s) => s['userId'] == ApiService.currentUserId);
                final myStoryGroup = myStoryIndex != -1 ? _stories[myStoryIndex] : null;
                final myStoriesList = myStoryGroup != null
                    ? List<Map<String, dynamic>>.from(myStoryGroup['stories'] ?? [])
                    : <Map<String, dynamic>>[];
                final hasMyStory = myStoriesList.isNotEmpty;

                // Priority: myStory user avatar -> ApiService current avatar -> _myProfile avatar
                final myAvatar = (myStoryGroup?['user']?['avatarUrl'] != null &&
                        (myStoryGroup!['user']['avatarUrl'] as String).isNotEmpty)
                    ? (myStoryGroup['user']['avatarUrl'] as String)
                    : (ApiService.currentUserAvatar.isNotEmpty
                        ? ApiService.currentUserAvatar
                        : (_myProfile?['avatarUrl'] as String? ?? ''));

                final otherStoryGroups = _stories.where((s) => s['userId'] != ApiService.currentUserId).toList();

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // ── 1. My Story ("Status Saya") ────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: GestureDetector(
                        onTap: () {
                          if (hasMyStory) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(
                                  userName: 'Status Saya',
                                  userAvatar: myAvatar,
                                  stories: myStoriesList,
                                  isMyStory: true,
                                ),
                              ),
                            ).then((_) => _loadAllData());
                          } else {
                            _openStoryCreationDialog();
                          }
                        },
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: hasMyStory ? AppTheme.primaryTeal : const Color(0xFFB4E3DE),
                                      width: hasMyStory ? 2.5 : 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppTheme.mintLight,
                                    backgroundImage: myAvatar.isNotEmpty
                                        ? NetworkImage(myAvatar)
                                        : null,
                                    child: myAvatar.isEmpty
                                        ? Text(
                                            ApiService.currentUserName.isNotEmpty
                                                ? ApiService.currentUserName.substring(0, 1).toUpperCase()
                                                : 'S',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal, fontSize: 18),
                                          )
                                        : null,
                                  ),
                                ),
                                // '+' badge on bottom right
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _openStoryCreationDialog,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTeal,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const SizedBox(
                              width: 68,
                              child: Text(
                                'Status Saya',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryTeal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── 2. Friend Stories ("Status Teman") ───────────────────
                    ...otherStoryGroups.map((sGroup) {
                      final u = sGroup['user'] ?? {};
                      final name = u['name'] ?? 'Teman';
                      final avatarUrl = u['avatarUrl'] ?? '';
                      final storiesList = List<Map<String, dynamic>>.from(sGroup['stories'] ?? []);

                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(
                                  userId: (u['id'] ?? sGroup['userId'])?.toString(),
                                  userName: name,
                                  userAvatar: avatarUrl,
                                  stories: storiesList,
                                  isMyStory: false,
                                ),
                              ),
                            ).then((_) => _loadAllData());
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryTeal, width: 2.2),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppTheme.mintLight,
                                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(ApiService.normalizeUrl(avatarUrl)) : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          if (_searchQuery.isEmpty)
            const Divider(height: 1, color: Color(0xFFEDF2F7)),

          // ── Incoming Friend Requests Banner (Hanya saat tidak mencari) ──
          if (_searchQuery.isEmpty && _incomingRequests.isNotEmpty)
            GestureDetector(
              onTap: _openFriendRequestsModal,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ada ${_incomingRequests.length} Permintaan Pertemanan!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Klik untuk melihat dan menerima pertemanan',
                            style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('Terima', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Chat List or Empty State ─────────────────────────────
          if (_contacts.isEmpty)
            _buildEmptyState()
          else if (_searchQuery.isNotEmpty && filteredContacts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 14),
                  Text(
                    'Tidak ada obrolan dengan kata "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ingin mencari dan menambahkan teman baru di QuickChat?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_search_rounded, size: 20),
                    label: Text('Cari "$_searchQuery" di Kontak'),
                    onPressed: () => _openAddFriendModal(initialPhone: _searchQuery),
                  ),
                ],
              ),
            )
          else
            ...(() {
              final myId = ApiService.currentUserId;
              final sortedContacts = List<Map<String, dynamic>>.from(filteredContacts);
              sortedContacts.sort((a, b) {
                final targetA = a['id']?.toString() ?? '';
                final convA = ApiService.get1on1ConversationId(myId, targetA);
                final memA = ref.watch(messagesProvider(convA));
                DateTime? dtA;
                if (memA.isNotEmpty && memA.last['timestamp'] != null) {
                  dtA = DateTime.tryParse(memA.last['timestamp'].toString());
                } else if (a['lastMessage'] != null && a['lastMessage']['timestamp'] != null) {
                  dtA = DateTime.tryParse(a['lastMessage']['timestamp'].toString());
                }

                final targetB = b['id']?.toString() ?? '';
                final convB = ApiService.get1on1ConversationId(myId, targetB);
                final memB = ref.watch(messagesProvider(convB));
                DateTime? dtB;
                if (memB.isNotEmpty && memB.last['timestamp'] != null) {
                  dtB = DateTime.tryParse(memB.last['timestamp'].toString());
                } else if (b['lastMessage'] != null && b['lastMessage']['timestamp'] != null) {
                  dtB = DateTime.tryParse(b['lastMessage']['timestamp'].toString());
                }

                final timeA = dtA?.millisecondsSinceEpoch ?? 0;
                final timeB = dtB?.millisecondsSinceEpoch ?? 0;
                if (timeA != timeB) return timeB.compareTo(timeA);
                return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
              });

              return sortedContacts.map((contact) {
                final name = contact['name'] ?? 'Teman';
                final phone = contact['phoneNumber'] ?? '';
                final avatarUrl = contact['avatarUrl'] ?? '';
                final isOnline = contact['isOnline'] == true;
                final isMutual = contact['isMutualContact'] == true;
                final lastMsg = contact['lastMessage'] as Map<String, dynamic>?;
                final unreadCount = (contact['unreadCount'] as num?)?.toInt() ?? 0;

                final targetId = contact['id']?.toString() ?? '';
                final convId = ApiService.get1on1ConversationId(myId, targetId);
                final inMemoryMsgs = ref.watch(messagesProvider(convId));

                // Find effective last message: prioritize in-memory if newer
                Map<String, dynamic>? effectiveLastMsg = lastMsg;
                if (inMemoryMsgs.isNotEmpty) {
                  final lastMem = inMemoryMsgs.last;
                  if (effectiveLastMsg == null) {
                    effectiveLastMsg = lastMem;
                  } else {
                    try {
                      final tMem = DateTime.parse(lastMem['timestamp']?.toString() ?? '');
                      final tDb = DateTime.parse(effectiveLastMsg['timestamp']?.toString() ?? '');
                      if (!tMem.isBefore(tDb)) {
                        effectiveLastMsg = lastMem;
                      }
                    } catch (_) {
                      effectiveLastMsg = lastMem;
                    }
                  }
                }

                // Parse subtitle display
                String displaySubtitle = 'Belum ada pesan';
                IconData? messageIcon;
                Color messageIconColor = const Color(0xFF0D9488);
                IconData? statusIcon;
                Color? statusColor;

                if (effectiveLastMsg != null) {
                  String content = (effectiveLastMsg['content'] ?? '').toString().trim();
                  final mediaUrl = (effectiveLastMsg['mediaUrl'] ?? effectiveLastMsg['media_url'] ?? '').toString().trim();
                  final isMe = effectiveLastMsg['isMe'] == true;
                  final status = (effectiveLastMsg['status'] as num?)?.toInt() ?? 1;

                  // Unwrap JSON payload if reply was saved as JSON
                  if (content.startsWith('{') && content.contains('"text":')) {
                    try {
                      final decoded = jsonDecode(content);
                      if (decoded is Map && decoded['text'] != null) {
                        content = decoded['text'].toString().trim();
                      }
                    } catch (_) {}
                  }

                  final isVoice = content.contains('[Pesan Suara]') ||
                      content.toLowerCase().contains('pesan suara') ||
                      mediaUrl.contains('voice_') ||
                      mediaUrl.toLowerCase().endsWith('.m4a') ||
                      mediaUrl.toLowerCase().endsWith('.aac') ||
                      mediaUrl.toLowerCase().endsWith('.mp3') ||
                      mediaUrl.toLowerCase().endsWith('.wav') ||
                      mediaUrl.toLowerCase().endsWith('.ogg');

                  final isPhoto = !isVoice && (
                      content.contains('[Foto]') ||
                      content.trim().toLowerCase() == 'foto' ||
                      mediaUrl.contains('img_') ||
                      mediaUrl.contains('chat_') ||
                      mediaUrl.toLowerCase().endsWith('.png') ||
                      mediaUrl.toLowerCase().endsWith('.jpg') ||
                      mediaUrl.toLowerCase().endsWith('.jpeg') ||
                      mediaUrl.toLowerCase().endsWith('.webp') ||
                      mediaUrl.toLowerCase().endsWith('.gif') ||
                      mediaUrl.isNotEmpty
                  );

                  if (isVoice) {
                    messageIcon = Icons.mic_rounded;
                    messageIconColor = const Color(0xFF0D9488);
                    displaySubtitle = 'Pesan Suara';
                  } else if (isPhoto) {
                    messageIcon = Icons.photo_camera_rounded;
                    messageIconColor = const Color(0xFF0D9488);
                    if (content.isNotEmpty && !content.contains('[Foto]') && !content.startsWith('http')) {
                      displaySubtitle = content;
                    } else {
                      displaySubtitle = 'Foto';
                    }
                  } else if (content.isNotEmpty) {
                    messageIcon = null;
                    displaySubtitle = content;
                  } else {
                    messageIcon = null;
                    displaySubtitle = 'Belum ada pesan';
                  }

                  if (isMe) {
                    if (status >= 3) {
                      statusIcon = Icons.done_all;
                      statusColor = const Color(0xFF0284C7); // Read (blue double check)
                    } else if (status == 2) {
                      statusIcon = Icons.done_all;
                      statusColor = const Color(0xFF94A3B8); // Delivered (grey double check)
                    } else if (status == 1) {
                      statusIcon = Icons.check;
                      statusColor = const Color(0xFF94A3B8); // Sent (single check)
                    } else {
                      statusIcon = Icons.access_time_rounded;
                      statusColor = const Color(0xFF94A3B8); // Sending (clock)
                    }
                  }
                }

                // Parse time display
                String displayTime = '';
                if (effectiveLastMsg != null && effectiveLastMsg['timestamp'] != null) {
                  try {
                    final dt = DateTime.parse(effectiveLastMsg['timestamp'].toString()).toLocal();
                    final now = DateTime.now();
                    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                      final hour = dt.hour.toString().padLeft(2, '0');
                      final min = dt.minute.toString().padLeft(2, '0');
                      displayTime = '$hour:$min';
                    } else if (now.difference(dt).inDays == 1 || (now.day - dt.day == 1 && dt.month == now.month)) {
                      displayTime = 'Kemarin';
                    } else {
                      final day = dt.day.toString().padLeft(2, '0');
                      final month = dt.month.toString().padLeft(2, '0');
                      displayTime = '$day/$month';
                    }
                  } catch (_) {}
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unreadCount > 0 ? const Color(0xFFB4E3DE) : const Color(0xFFF1F5F9),
                      width: unreadCount > 0 ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // ── 1. AVATAR KLIK KHUSUS: LANGSUNG BUKA PROFIL TEMAN ──
                        InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            final targetId = contact['id']?.toString() ?? contact['targetUserId']?.toString() ?? '';
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FriendProfileScreen(
                                  userId: targetId,
                                  userName: name,
                                  userPhone: phone,
                                  userAvatar: avatarUrl,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.25), width: 1.5),
                                ),
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppTheme.mintLight,
                                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(ApiService.normalizeUrl(avatarUrl)) : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                          style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 17),
                                        )
                                      : null,
                                ),
                              ),
                              if (isOnline)
                                Positioned(
                                  right: 2,
                                  bottom: 2,
                                  child: Container(
                                    width: 13,
                                    height: 13,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // ── 2. KLIK AREA OBROLAN: BUKA RUANG CHAT ──
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              final myId = ApiService.currentUserId;
                              final targetId = contact['id']?.toString() ?? contact['targetUserId']?.toString() ?? '';
                              final convId = ApiService.get1on1ConversationId(myId, targetId);
                              await context.push('/chat/$convId?name=${Uri.encodeComponent(name)}&targetId=$targetId&phone=${Uri.encodeComponent(phone)}&avatar=${Uri.encodeComponent(avatarUrl)}');
                              if (mounted) {
                                _loadAllData();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isMutual) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified, size: 14, color: AppTheme.primaryTeal),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (statusIcon != null) ...[
                                              Icon(statusIcon, size: 15, color: statusColor),
                                              const SizedBox(width: 4),
                                            ],
                                            if (messageIcon != null) ...[
                                              Icon(messageIcon, size: 15, color: messageIconColor),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                displaySubtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: unreadCount > 0
                                                      ? AppTheme.textPrimary
                                                      : (effectiveLastMsg == null ? Colors.grey.shade400 : AppTheme.textSecondary),
                                                  fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                                  fontStyle: effectiveLastMsg == null ? FontStyle.italic : FontStyle.normal,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (displayTime.isNotEmpty)
                                        Text(
                                          displayTime,
                                          style: TextStyle(
                                            color: unreadCount > 0 ? AppTheme.primaryTeal : AppTheme.textSecondary,
                                            fontSize: 11,
                                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (unreadCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTeal,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : '$unreadCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            })(),

          if (_searchQuery.isNotEmpty && filteredContacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: Color(0xFFB4E3DE), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: Text('Cari "$_searchQuery" sebagai nomor teman baru'),
                onPressed: () => _openAddFriendModal(initialPhone: _searchQuery),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppTheme.mintLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: AppTheme.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Obrolan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mulai percakapan pertama Anda dengan mencari kontak atau teman.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _openAddFriendModal,
            icon: const Icon(Icons.search, size: 20),
            label: const Text(
              'Mulai Obrolan Baru',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTab() {
    final filteredGroups = _searchQuery.isEmpty
        ? _groups
        : _groups.where((g) {
            final name = (g['name'] ?? '').toString().toLowerCase();
            final desc = (g['description'] ?? '').toString().toLowerCase();
            final lastMsg = (g['lastMessage'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || desc.contains(_searchQuery) || lastMsg.contains(_searchQuery);
          }).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primaryTeal,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ── Button: Buat Grup Baru / Tambah Anggota (Hanya saat tidak mencari) ──
          if (_searchQuery.isEmpty) ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F4F1), Color(0xFFF0FDF4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB4E3DE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openCreateGroupModal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Buat Grup Baru',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Tambah anggota dan mulai obrolan bersama',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFB4E3DE)),
                          ),
                          child: const Icon(Icons.add, size: 18, color: AppTheme.primaryTeal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Header: Daftar Grup ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _searchQuery.isEmpty
                    ? 'Grup Anda (${_groups.length})'
                    : 'Hasil Pencarian Grup (${filteredGroups.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Groups List ───────────────────────────────────────────────────
          if (_groups.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.groups_outlined, size: 48, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text('Belum ada grup obrolan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Ketuk tombol di atas untuk membuat grup pertamamu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else if (_searchQuery.isNotEmpty && filteredGroups.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada grup yang cocok dengan "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Periksa kembali kata kunci nama grup yang Anda cari',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...filteredGroups.map((g) {
              final gId = g['id'] ?? 'group_1';
              final name = g['name'] ?? 'Grup';
              final avatar = g['avatar'] as String? ?? '';
              final lastMsg = (g['lastMessage'] ?? 'Belum ada pesan').toString();
              final memberCount = g['memberCount'] ?? 1;
              final lastTime = g['lastMessageTime']?.toString() ?? '';
              final mediaUrl = (g['lastMessageMediaUrl'] ?? '').toString();

              final isGroupVoice = lastMsg.contains('[Pesan Suara]') || mediaUrl.contains('voice_') || mediaUrl.endsWith('.m4a');
              final isGroupPhoto = !isGroupVoice && (lastMsg.contains('[Foto]') || mediaUrl.isNotEmpty);

              IconData? groupIcon;
              String groupDisplaySubtitle = lastMsg;
              if (isGroupVoice) {
                groupIcon = Icons.mic_rounded;
                groupDisplaySubtitle = 'Pesan Suara';
              } else if (isGroupPhoto) {
                groupIcon = Icons.photo_camera_rounded;
                groupDisplaySubtitle = 'Foto';
              }

              String timeStr = '';
              if (lastTime.isNotEmpty) {
                try {
                  final dt = DateTime.parse(lastTime).toLocal();
                  timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {}
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.mintLight,
                      shape: BoxShape.circle,
                      image: avatar.isNotEmpty ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover) : null,
                    ),
                    child: avatar.isEmpty
                        ? const Icon(Icons.groups_rounded, color: AppTheme.primaryTeal, size: 26)
                        : null,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$memberCount anggota',
                          style: const TextStyle(fontSize: 10, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (groupIcon != null) ...[
                        Icon(groupIcon, size: 14, color: const Color(0xFF0D9488)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          groupDisplaySubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push('/chat/$gId?name=${Uri.encodeComponent(name)}&targetId=$gId&isGroup=true');
                    if (mounted) {
                      _loadAllData();
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCallsTab() {
    final filteredCalls = _searchQuery.isEmpty
        ? _calls
        : _calls.where((call) {
            final target = call['targetUser'] ?? {};
            final name = (target['name'] ?? '').toString().toLowerCase();
            final phone = (target['phoneNumber'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || phone.contains(_searchQuery);
          }).toList();

    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.phone_disabled_rounded, size: 54, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'Belum ada riwayat panggilan',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Buka obrolan teman untuk memulai telepon atau video call',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isNotEmpty && filteredCalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Tidak ada riwayat panggilan untuk "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: filteredCalls.length,
      itemBuilder: (context, index) {
        final call = filteredCalls[index];
        final target = call['targetUser'] ?? {};
        final name = target['name'] ?? 'Teman';
        final avatarUrl = target['avatarUrl'] ?? '';
        final isOutgoing = call['isOutgoing'] == true;
        final status = call['status'] ?? 'completed';
        final isMissed = status == 'missed' || status == 'declined';
        final duration = call['duration'] ?? 0;
        final isVideo = call['type'] == 'video';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFF1F5F9)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final targetId = target['id']?.toString() ?? call['targetUserId']?.toString() ?? '';
                    final phone = target['phoneNumber']?.toString() ?? '';
                    if (targetId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FriendProfileScreen(
                            userId: targetId,
                            userName: name,
                            userPhone: phone,
                            userAvatar: avatarUrl,
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.mintLight,
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(ApiService.normalizeUrl(avatarUrl)) : null,
                    child: avatarUrl.isEmpty
                        ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam_rounded : Icons.phone_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Row(
              children: [
                Icon(
                  isOutgoing
                      ? Icons.call_made_rounded
                      : isMissed
                          ? Icons.call_missed_rounded
                          : Icons.call_received_rounded,
                  size: 15,
                  color: isMissed ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                ),
                const SizedBox(width: 4),
                Text(
                  isMissed
                      ? (status == 'declined' ? 'Ditolak' : 'Tak terjawab')
                      : 'Selesai ($duration dtk)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMissed ? const Color(0xFFEF4444) : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVideo ? 'Video' : 'Suara',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isVideo ? const Color(0xFF0284C7) : AppTheme.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: AppTheme.primaryTeal, size: 20),
                  tooltip: 'Telepon Balik',
                  onPressed: () {
                    CallDialog.startCall(
                      context,
                      ref,
                      targetUserId: target['id'] ?? 'user_target',
                      targetUserName: name,
                      targetUserAvatar: avatarUrl,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_rounded, color: Color(0xFF0284C7), size: 22),
                  tooltip: 'Video Call Balik',
                  onPressed: () {
                    CallDialog.startVideoCall(
                      context,
                      ref,
                      targetUserId: target['id'] ?? 'user_target',
                      targetUserName: name,
                      targetUserAvatar: avatarUrl,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
