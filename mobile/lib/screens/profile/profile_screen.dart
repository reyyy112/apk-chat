import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/socket_provider.dart';
import '../../router/app_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../settings/settings_screen.dart';
import 'all_photos_screen.dart';
import 'friend_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _photos = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

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
    _loadAllProfileData();
  }

  Future<void> _loadAllProfileData() async {
    final contactsFuture = ApiService.getContacts();
    final requestsFuture = ApiService.getFriendRequests();
    final profileFuture = ApiService.getMyProfile();
    final photosFuture = ApiService.getUserPhotos();
    final results = await Future.wait([contactsFuture, requestsFuture, profileFuture, photosFuture]);

    if (mounted) {
      setState(() {
        final contacts = results[0] as List<Map<String, dynamic>>;
        final reqs = results[1] as Map<String, dynamic>;
        _friends = contacts.where((c) => c['isMutualContact'] == true).toList();
        _incomingRequests = List<Map<String, dynamic>>.from(reqs['incoming'] ?? []);
        _outgoingRequests = List<Map<String, dynamic>>.from(reqs['outgoing'] ?? []);
        _userProfile = results[2] as Map<String, dynamic>?;
        _photos = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }


  Future<void> _acceptRequest(String targetUserId, String name) async {
    final success = await ApiService.acceptFriendRequest(targetUserId);
    if (success) {
      ref.read(contactSyncProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sekarang Anda berteman dengan $name!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
      _loadFriends();
    }
  }

  Future<void> _rejectRequest(String targetUserId) async {
    final success = await ApiService.rejectFriendRequest(targetUserId);
    if (success) {
      ref.read(contactSyncProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan pertemanan ditolak')),
        );
      }
      _loadFriends();
    }
  }

  void _openAddFriendDialog() {
    final phoneController = TextEditingController();
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

            setModalState(() {
              searchResults = results;
              isSearching = false;
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

                // Search Input & Button
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
                const SizedBox(height: 20),

                if (isSearching)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)))
                else if (!hasSearched)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.contact_phone_outlined, size: 54, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 12),
                          Text(
                            'Ketik nomor telepon teman Anda\nlalu klik "Cari".',
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
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.mintLight,
                                backgroundImage: u['avatarUrl'] != null && u['avatarUrl'].isNotEmpty
                                    ? NetworkImage(u['avatarUrl'])
                                    : null,
                                child: u['avatarUrl'] == null || u['avatarUrl'].isEmpty
                                    ? Text(
                                        u['name']?.substring(0, 1) ?? 'U',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u['name'] ?? 'Pengguna',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(u['phoneNumber'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMutual
                                          ? 'Mutual Friends'
                                          : isAdded
                                              ? 'Kontak Disimpan'
                                              : 'Belum Ditambahkan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isMutual ? const Color(0xFF10B981) : isAdded ? const Color(0xFFF59E0B) : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMutual ? const Color(0xFF10B981) : AppTheme.primaryTeal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                          setModalState(() {
                                            u['isMutualContact'] = res['contact']?['isMutualContact'] == true;
                                            u['isAdded'] = true;
                                          });
                                          _loadFriends();
                                        }
                                      },
                                child: Text(isMutual ? 'Chat' : isAdded ? 'Tersimpan' : '+ Tambah', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Future<void> _loadFriends() => _loadAllProfileData();

  void _openEditProfileModal() {
    final currentName = _userProfile?['name'] ?? ApiService.currentUserName;
    final currentBio = _userProfile?['aboutStatus'] ?? 'Hey there! I am using QuickChat.';
    final currentAvatar = _userProfile?['avatarUrl'] ?? '';

    final nameController = TextEditingController(text: currentName);
    final bioController = TextEditingController(text: currentBio);
    final avatarController = TextEditingController(text: currentAvatar);
    bool isSaving = false;
    bool isUploadingAvatar = false;

    final List<String> avatarPresets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ];

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
                          Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Edit Profil',
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
                  const SizedBox(height: 16),

                  // Avatar preview with camera overlay
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.mintLight,
                            border: Border.all(color: AppTheme.primaryTeal, width: 2.5),
                            image: avatarController.text.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(avatarController.text),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: avatarController.text.isEmpty
                              ? Center(
                                  child: Text(
                                    nameController.text.isNotEmpty
                                        ? nameController.text[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setModalState(() => isUploadingAvatar = true);
                                final bytes = await image.readAsBytes();
                                final url = await ApiService.uploadImage(bytes: bytes, filename: image.name);
                                setModalState(() {
                                  if (url != null) {
                                    avatarController.text = url;
                                  }
                                  isUploadingAvatar = false;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: isUploadingAvatar
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setModalState(() => isUploadingAvatar = true);
                                final bytes = await image.readAsBytes();
                                final url = await ApiService.uploadImage(bytes: bytes, filename: image.name);
                                setModalState(() {
                                  if (url != null) {
                                    avatarController.text = url;
                                  }
                                  isUploadingAvatar = false;
                                });
                              }
                            },
                      icon: isUploadingAvatar
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal))
                          : const Icon(Icons.photo_library_rounded, size: 16),
                      label: Text(
                        isUploadingAvatar ? 'Mengunggah...' : 'Pilih Foto dari Galeri',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Atau Pilih Avatar Cepat:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: avatarPresets.map((av) {
                      final isSelected = avatarController.text == av;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            avatarController.text = av;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(av),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Pengguna',
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(
                      labelText: 'Status / Bio',
                      prefixIcon: const Icon(Icons.info_outline, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: avatarController,
                    decoration: InputDecoration(
                      labelText: 'URL Foto Profil (Opsional)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.link, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final updated = await ApiService.updateProfile(
                                name: nameController.text.trim(),
                                aboutStatus: bioController.text.trim(),
                                avatarUrl: avatarController.text.trim(),
                              );
                              if (updated != null) {
                                Navigator.pop(ctx);
                                await _loadAllProfileData();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profil berhasil diperbarui!'),
                                      backgroundColor: AppTheme.primaryTeal,
                                    ),
                                  );
                                }
                              } else {
                                setModalState(() => isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gagal memperbarui profil')),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

  void _showShareProfileDialog() {
    final name = _userProfile?['name'] ?? ApiService.currentUserName;
    final phone = _userProfile?['phoneNumber'] ?? ApiService.currentUserPhone;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.share_rounded, color: AppTheme.primaryTeal),
            SizedBox(width: 10),
            Text('Bagikan Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.mintLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 80, color: AppTheme.primaryTeal),
                  const SizedBox(height: 8),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Bagikan nomor Anda agar teman dapat menambahkan Anda ke kontak mereka.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Hubungi saya di QuickChat: $phone ($name)'));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Info kontak disalin ke clipboard!'),
                  backgroundColor: AppTheme.primaryTeal,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun QuickChat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(socketProvider.notifier).disconnect();
              ref.read(authProvider.notifier).state = false;
              ApiService.currentUserId = '';
              ApiService.currentUserName = '';
              ApiService.currentUserPhone = '';
              context.go('/login');
            },
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoModal() {
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
                            'Tambah Foto Profil',
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
                        urlController.text,
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

                  // Presets
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
                      labelText: 'Caption Foto (Opsional)',
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
                          await _loadAllProfileData();
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

  void _openAllPhotosScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllPhotosScreen(
          initialPhotos: _photos,
          onPhotosChanged: _loadAllProfileData,
        ),
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
                      url,
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
                                  content: const Text('Foto ini akan dihapus dari profil Anda.'),
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
                                  await _loadAllProfileData();
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
    ref.listen<int>(contactSyncProvider, (prev, next) {
      if (mounted) _loadAllProfileData();
    });

    final displayName = _userProfile?['name'] ?? (ApiService.currentUserName.isNotEmpty ? ApiService.currentUserName : 'Pengguna');
    final displayPhone = _userProfile?['phoneNumber'] ?? (ApiService.currentUserPhone.isNotEmpty ? ApiService.currentUserPhone : '12345678');
    final avatarUrl = _userProfile?['avatarUrl'] as String? ?? '';
    final bioText = _userProfile?['aboutStatus'] as String? ?? 'Hey there! I am using QuickChat.';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit_profile') {
                _openEditProfileModal();
              } else if (value == 'share_profile') {
                _showShareProfileDialog();
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'edit_profile',
                child: Row(
                  children: const [
                    Icon(Icons.edit_outlined, color: AppTheme.primaryTeal, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share_profile',
                child: Row(
                  children: const [
                    Icon(Icons.share_outlined, color: AppTheme.primaryTeal, size: 20),
                    SizedBox(width: 12),
                    Text('Bagikan Profil', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: const [
                    Icon(Icons.settings_outlined, color: AppTheme.primaryTeal, size: 20),
                    SizedBox(width: 12),
                    Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
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
                  // User Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.mintLight,
                                border: Border.all(color: AppTheme.primaryTeal, width: 2),
                                image: avatarUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarUrl.isEmpty
                                  ? Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Name & Member
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayPhone,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'QuickChat Member',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Bio
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            bioText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('${_photos.length}', 'POSTS'),
                            _buildStatItem('${_friends.length}', 'FOLLOWERS'),
                            _buildStatItem('${_friends.length}', 'FOLLOWING'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),


                  // ==========================================
                  // INCOMING FRIEND REQUESTS (Permintaan Masuk)
                  // ==========================================
                  if (_incomingRequests.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryTeal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Permintaan Pertemanan (${_incomingRequests.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pengguna di bawah ini menambahkan Anda sebagai teman. Klik Terima untuk menjadi Mutual Friends!',
                            style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(height: 12),
                          ..._incomingRequests.map((req) {
                            final rName = req['name'] ?? 'Pengguna';
                            final rPhone = req['phoneNumber'] ?? '';
                            final rId = req['id'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFDCFCE7)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.mintLight,
                                    backgroundImage: req['avatarUrl'] != null && req['avatarUrl'] != ''
                                        ? NetworkImage(req['avatarUrl'])
                                        : null,
                                    child: (req['avatarUrl'] == null || req['avatarUrl'] == '')
                                        ? Text(
                                            rName.isNotEmpty ? rName[0].toUpperCase() : '?',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                          )
                                        : null,
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
                                    onPressed: () => _acceptRequest(rId, rName),
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
                                    onPressed: () => _rejectRequest(rId),
                                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Outgoing Requests (Menunggu Konfirmasi Teman)
                  if (_outgoingRequests.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Menunggu Konfirmasi Teman',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Anda telah menambahkan ${_outgoingRequests.length} orang. Menunggu mereka menambahkan nomor Anda balik.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Friends Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Friends (${_friends.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openAddFriendDialog,
                        child: const Text(
                          '+ Add friends',
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

                  // Friends Content
                  if (_friends.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDF2F7)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 42,
                            color: Color(0xFFA0AEC0),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada teman ditambahkan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Cari dan tambahkan teman dari kontak!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _openAddFriendDialog,
                            icon: const Icon(Icons.person_add_alt, size: 18),
                            label: const Text(
                              'Cari Teman',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDF2F7)),
                      ),
                      child: Column(
                        children: _friends.map((friend) {
                          return ListTile(
                            leading: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FriendProfileScreen(
                                      userId: friend['id'],
                                      userName: friend['name'],
                                      userPhone: friend['phoneNumber'],
                                      userAvatar: friend['avatarUrl'],
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundColor: AppTheme.mintLight,
                                backgroundImage: friend['avatarUrl'] != null && friend['avatarUrl'].isNotEmpty
                                    ? NetworkImage(ApiService.normalizeUrl(friend['avatarUrl']))
                                    : null,
                                child: friend['avatarUrl'] == null || friend['avatarUrl'].isEmpty
                                    ? Text(friend['name']?.substring(0, 1) ?? 'U', style: const TextStyle(color: AppTheme.primaryTeal))
                                    : null,
                              ),
                            ),
                            title: Text(friend['name'] ?? 'Teman', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(friend['aboutStatus'] ?? '', style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.verified, color: AppTheme.primaryTeal, size: 18),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FriendProfileScreen(
                                    userId: friend['id'],
                                    userName: friend['name'],
                                    userPhone: friend['phoneNumber'],
                                    userAvatar: friend['avatarUrl'],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Photos Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_photos.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.mintLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_photos.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showAddPhotoModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.mintLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.add_photo_alternate_outlined, size: 15, color: AppTheme.primaryTeal),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _openAllPhotosScreen,
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Photos Content
                  if (_photos.isEmpty)
                    InkWell(
                      onTap: _showAddPhotoModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDF2F7)),
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: AppTheme.primaryTeal,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Tap "Add" to upload photos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _photos.length > 6 ? 6 : _photos.length,
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        final isLastMore = index == 5 && _photos.length > 6;
                        return GestureDetector(
                          onTap: isLastMore
                              ? _openAllPhotosScreen
                              : () => _showPhotoDetail(photo),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photo['url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.mintLight,
                                    child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.primaryTeal),
                                  ),
                                ),
                                if (isLastMore)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    child: Center(
                                      child: Text(
                                        '+${_photos.length - 5}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
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
