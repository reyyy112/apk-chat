import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_translations.dart';
import '../../providers/settings_provider.dart';
import '../../providers/socket_provider.dart';
import '../../router/app_router.dart';
import '../../services/api_service.dart';
import '../../services/storage_helper.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationsProvider);
    final name = ApiService.currentUserName.isNotEmpty ? ApiService.currentUserName : 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final avatarUrl = ApiService.currentUserAvatar;
    final notifications = ref.watch(notificationCenterProvider);
    final unreadNotifs = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.mintLight,
                      border: Border.all(color: AppTheme.primaryTeal, width: 2),
                      image: avatarUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: avatarUrl.isEmpty
                        ? Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Hello Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.hello(name),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ApiService.currentUserPhone.isNotEmpty
                              ? ApiService.currentUserPhone
                              : tr.memberSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell in mint box with unread badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.mintLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppTheme.primaryTeal,
                            size: 24,
                          ),
                          onPressed: () => _openNotificationCenter(context),
                        ),
                      ),
                      if (unreadNotifs > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Center(
                              child: Text(
                                '$unreadNotifs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── 2-Column Grid of Settings ────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildGridItem(
                    icon: Icons.person_outline_rounded,
                    title: tr.editProfile,
                    onTap: () => _openEditProfileModal(context, tr),
                  ),
                  _buildGridItem(
                    icon: Icons.notifications_none_rounded,
                    title: tr.notifications,
                    onTap: () => _openNotificationSettingsModal(context),
                  ),
                  _buildGridItem(
                    icon: Icons.lock_outline_rounded,
                    title: tr.privacySecurity,
                    onTap: () => _openPrivacySecurityModal(context),
                  ),
                  _buildGridItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: tr.chatSettings,
                    onTap: () => _openChatSettingsModal(context),
                  ),
                  _buildGridItem(
                    icon: Icons.dns_outlined,
                    title: tr.dataStorage,
                    onTap: () => _openDataStorageModal(context),
                  ),
                  _buildGridItem(
                    icon: Icons.language_rounded,
                    title: tr.language,
                    onTap: () => _openLanguageModal(context),
                  ),
                  _buildGridItem(
                    icon: Icons.help_outline_rounded,
                    title: tr.help,
                    onTap: () => _openHelpModal(context, tr),
                  ),
                  _buildGridItem(
                    icon: Icons.info_outline_rounded,
                    title: tr.about,
                    onTap: () => _openAboutModal(context, tr),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Logout Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                    backgroundColor: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _confirmLogout(context, tr),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    tr.logoutButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDF2F7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.mintLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryTeal,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. NOTIFICATION CENTER (Bell Icon)
  // ──────────────────────────────────────────────────────────────────────────
  void _openNotificationCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final items = ref.watch(notificationCenterProvider);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryTeal, size: 24),
                          const SizedBox(width: 8),
                          Text(tr.notificationCenterTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (items.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ref.read(notificationCenterProvider.notifier).markAllAsRead();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr.allNotifsMarked)),
                            );
                          },
                          child: Text(tr.markAllAsRead, style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 13)),
                        ),
                    ],
                  ),
                  const Divider(),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(tr.noNewNotifications, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          IconData notifIcon;
                          Color iconColor;

                          switch (item.type) {
                            case 'call':
                              notifIcon = Icons.phone_missed_rounded;
                              iconColor = Colors.red;
                              break;
                            case 'group':
                              notifIcon = Icons.groups_rounded;
                              iconColor = const Color(0xFF0284C7);
                              break;
                            default:
                              notifIcon = Icons.info_outline_rounded;
                              iconColor = AppTheme.primaryTeal;
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(notifIcon, color: iconColor, size: 22),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(item.time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            subtitle: Text(
                              item.message,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (items.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(notificationCenterProvider.notifier).clearAll();
                          Navigator.pop(ctx);
                        },
                        child: Text(tr.clearAllNotifs, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. EDIT PROFILE MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openEditProfileModal(BuildContext context, AppTranslations tr) {
    final currentName = ApiService.currentUserName;
    final nameController = TextEditingController(text: currentName);
    final bioController = TextEditingController(text: 'Hey there! I am using QuickChat.');
    final avatarController = TextEditingController(text: ApiService.currentUserAvatar);
    bool isSaving = false;
    bool isUploadingAvatar = false;

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
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            tr.editProfileTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal,
                                    ),
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
                        isUploadingAvatar ? tr.uploading : tr.chooseFromGallery,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: tr.fullNameLabel,
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: bioController,
                    decoration: InputDecoration(
                      labelText: tr.bioLabel,
                      prefixIcon: const Icon(Icons.info_outline, color: AppTheme.primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
                              await ApiService.updateProfile(
                                name: nameController.text.trim(),
                                aboutStatus: bioController.text.trim(),
                                avatarUrl: avatarController.text.trim(),
                              );
                              if (mounted) setState(() {});
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr.profileUpdatedSuccess),
                                  backgroundColor: AppTheme.primaryTeal,
                                ),
                              );
                            },
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(tr.save, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  // ──────────────────────────────────────────────────────────────────────────
  // 3. NOTIFICATIONS SETTINGS MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openNotificationSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final settings = ref.watch(notificationSettingsProvider);
            final notifier = ref.read(notificationSettingsProvider.notifier);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryTeal, size: 26),
                            const SizedBox(width: 10),
                            Text(tr.notifSettingsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.directMessagesTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(tr.directMessagesSub),
                      value: settings.messageNotifications,
                      onChanged: notifier.toggleMessageNotifications,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.groupNotifsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(tr.groupNotifsSub),
                      value: settings.groupNotifications,
                      onChanged: notifier.toggleGroupNotifications,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.callNotifsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(tr.callNotifsSub),
                      value: settings.callNotifications,
                      onChanged: notifier.toggleCallNotifications,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.previewTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(tr.previewSub),
                      value: settings.previewEnabled,
                      onChanged: notifier.togglePreview,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.inAppSoundsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(tr.inAppSoundsSub),
                      value: settings.inAppSounds,
                      onChanged: notifier.toggleInAppSounds,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: Text(tr.resetToDefault),
                        onPressed: () {
                          notifier.reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr.notifSettingsReset)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. PRIVACY & SECURITY MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openPrivacySecurityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final privacy = ref.watch(privacySecurityProvider);
            final notifier = ref.read(privacySecurityProvider.notifier);

            final privacyLabels = {
              'Semua Orang': tr.privacyOptions[0],
              'Kontak Saya': tr.privacyOptions[1],
              'Tidak Ada': tr.privacyOptions[2],
            };

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: AppTheme.primaryTeal, size: 26),
                            const SizedBox(width: 10),
                            Text(tr.privacySecurityTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.lastSeenTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(privacyLabels[privacy.lastSeen] ?? privacy.lastSeen, style: const TextStyle(color: AppTheme.primaryTeal)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showOptionSelector(
                          context,
                          title: tr.lastSeenModalTitle,
                          current: privacy.lastSeen,
                          options: ['Semua Orang', 'Kontak Saya', 'Tidak Ada'],
                          displayLabels: privacyLabels,
                          onSelect: notifier.setLastSeen,
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.profilePhotoTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(privacyLabels[privacy.profilePhoto] ?? privacy.profilePhoto, style: const TextStyle(color: AppTheme.primaryTeal)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showOptionSelector(
                          context,
                          title: tr.profilePhotoModalTitle,
                          current: privacy.profilePhoto,
                          options: ['Semua Orang', 'Kontak Saya', 'Tidak Ada'],
                          displayLabels: privacyLabels,
                          onSelect: notifier.setProfilePhoto,
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.bioStatusTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(privacyLabels[privacy.aboutStatus] ?? privacy.aboutStatus, style: const TextStyle(color: AppTheme.primaryTeal)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showOptionSelector(
                          context,
                          title: tr.bioStatusModalTitle,
                          current: privacy.aboutStatus,
                          options: ['Semua Orang', 'Kontak Saya', 'Tidak Ada'],
                          displayLabels: privacyLabels,
                          onSelect: notifier.setAboutStatus,
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.readReceiptsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tr.readReceiptsSub),
                      value: privacy.readReceipts,
                      onChanged: notifier.toggleReadReceipts,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.appLockTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tr.appLockSub),
                      value: privacy.appLock,
                      onChanged: notifier.toggleAppLock,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.mintLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: AppTheme.primaryTeal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr.encryptionNote,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. CHAT SETTINGS MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openChatSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final chat = ref.watch(chatSettingsProvider);
            final notifier = ref.read(chatSettingsProvider.notifier);

            final themeMap = {
              'Terang': tr.themeLight,
              'Gelap': tr.themeDark,
              'Sistem': tr.themeSystem,
            };

            final fontLabels = {
              'Kecil': tr.sizeSmall,
              'Sedang': tr.sizeMedium,
              'Besar': tr.sizeLarge,
            };

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryTeal, size: 26),
                            const SizedBox(width: 10),
                            Text(tr.chatSettingsTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),
                    // Theme mode selector
                    Text(tr.chatThemeTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Terang', 'Gelap', 'Sistem'].map((t) {
                        final isSel = chat.themeMode == t;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(child: Text(themeMap[t] ?? t)),
                              selected: isSel,
                              selectedColor: AppTheme.mintLight,
                              labelStyle: TextStyle(
                                color: isSel ? AppTheme.primaryTeal : Colors.black87,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => notifier.setThemeMode(t),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Wallpaper selector
                    Text(tr.wallpaperTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildColorDot(notifier, chat.wallpaper, 'default', const Color(0xFFF1F5F9), tr.wpDefault),
                        _buildColorDot(notifier, chat.wallpaper, 'mint', const Color(0xFFE6F4F1), tr.wpTeal),
                        _buildColorDot(notifier, chat.wallpaper, 'blue', const Color(0xFFE0F2FE), tr.wpSky),
                        _buildColorDot(notifier, chat.wallpaper, 'peach', const Color(0xFFFFEDD5), tr.wpPeach),
                        _buildColorDot(notifier, chat.wallpaper, 'dark', const Color(0xFF0F172A), tr.wpDark),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Font size
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.fontSizeTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(fontLabels[chat.fontSize] ?? chat.fontSize, style: const TextStyle(color: AppTheme.primaryTeal)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showOptionSelector(
                          context,
                          title: tr.fontSizeModalTitle,
                          current: chat.fontSize,
                          options: ['Kecil', 'Sedang', 'Besar'],
                          displayLabels: fontLabels,
                          onSelect: notifier.setFontSize,
                        );
                      },
                    ),

                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.enterIsSendTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tr.enterIsSendSub),
                      value: chat.enterIsSend,
                      onChanged: notifier.toggleEnterIsSend,
                    ),

                    const Divider(),
                    // Chat Backup
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryTeal, size: 28),
                      title: Text(tr.chatBackupTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(tr.lastBackupText(chat.lastBackup), style: const TextStyle(fontSize: 12)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, elevation: 0),
                        onPressed: () {
                          notifier.recordBackup();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr.backupSuccess),
                              backgroundColor: AppTheme.primaryTeal,
                            ),
                          );
                        },
                        child: Text(tr.backupNow, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorDot(ChatSettingsNotifier notifier, String current, String id, Color color, String name) {
    final isSel = current == id;
    return GestureDetector(
      onTap: () => notifier.setWallpaper(id),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSel ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                width: isSel ? 3 : 1.5,
              ),
            ),
            child: isSel ? const Icon(Icons.check, size: 20, color: AppTheme.primaryTeal) : null,
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. DATA & STORAGE MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openDataStorageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final dataStorage = ref.watch(dataStorageProvider);
            final notifier = ref.read(dataStorageProvider.notifier);

            final qualityMap = {
              'Standar (Hemat Data)': tr.qualityStandard,
              'Tinggi (HD)': tr.qualityHD,
            };

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.dns_rounded, color: AppTheme.primaryTeal, size: 26),
                            const SizedBox(width: 10),
                            Text(tr.dataStorageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),

                    // Storage summary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr.storageUsageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${dataStorage.cacheSizeMb.toStringAsFixed(1)} MB',
                                  style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: dataStorage.cacheSizeMb > 0 ? 0.35 : 0.02,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: AppTheme.primaryTeal,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr.mediaStoredSub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              TextButton(
                                onPressed: dataStorage.cacheSizeMb <= 0
                                    ? null
                                    : () {
                                        notifier.clearCache();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(tr.cacheClearedSuccess)),
                                        );
                                      },
                                child: Text(tr.clearCache, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(tr.autoDownloadTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.photoWifi, style: const TextStyle(fontSize: 14)),
                      value: dataStorage.autoDownloadWifiPhotos,
                      onChanged: notifier.toggleWifiPhotos,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.videoWifi, style: const TextStyle(fontSize: 14)),
                      value: dataStorage.autoDownloadWifiVideos,
                      onChanged: notifier.toggleWifiVideos,
                    ),
                    SwitchListTile(
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.photoCellular, style: const TextStyle(fontSize: 14)),
                      value: dataStorage.autoDownloadMobilePhotos,
                      onChanged: notifier.toggleMobilePhotos,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr.uploadQualityTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(qualityMap[dataStorage.uploadQuality] ?? dataStorage.uploadQuality, style: const TextStyle(color: AppTheme.primaryTeal)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _showOptionSelector(
                          context,
                          title: tr.uploadQualityModalTitle,
                          current: dataStorage.uploadQuality,
                          options: ['Standar (Hemat Data)', 'Tinggi (HD)'],
                          displayLabels: qualityMap,
                          onSelect: notifier.setUploadQuality,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. LANGUAGE MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationsProvider);
            final currentLang = ref.watch(languageProvider);

            final languages = [
              {'name': 'Bahasa Indonesia', 'sub': 'Indonesia', 'flag': '🇮🇩'},
              {'name': 'English', 'sub': 'English (United States)', 'flag': '🇺🇸'},
              {'name': 'العربية', 'sub': 'Arabic', 'flag': '🇸🇦'},
              {'name': '日本語', 'sub': 'Japanese', 'flag': '🇯🇵'},
              {'name': '简体中文', 'sub': 'Simplified Chinese', 'flag': '🇨🇳'},
              {'name': 'Español', 'sub': 'Spanish', 'flag': '🇪🇸'},
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language_rounded, color: AppTheme.primaryTeal, size: 26),
                          const SizedBox(width: 10),
                          Text(tr.selectLanguageTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  ...languages.map((lang) {
                    final isSel = currentLang == lang['name'];
                    return ListTile(
                      leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                      title: Text(lang['name']!, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(lang['sub']!),
                      trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal) : null,
                      onTap: () {
                        final selectedLang = lang['name']!;
                        ref.read(languageProvider.notifier).state = selectedLang;
                        StorageHelper.setString('app_language', selectedLang);
                        final newTr = AppTranslations.of(selectedLang);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(newTr.langChangedToast(selectedLang)),
                            backgroundColor: AppTheme.primaryTeal,
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. HELP & FAQ MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openHelpModal(BuildContext context, AppTranslations tr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: AppTheme.primaryTeal, size: 26),
                        const SizedBox(width: 10),
                        Text(tr.helpCenterTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),

                ExpansionTile(
                  leading: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.primaryTeal),
                  title: Text(tr.faq1Q),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        tr.faq1A,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                ExpansionTile(
                  leading: const Icon(Icons.group_add_rounded, color: AppTheme.primaryTeal),
                  title: Text(tr.faq2Q),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        tr.faq2A,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                ExpansionTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryTeal),
                  title: Text(tr.faq3Q),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        tr.faq3A,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                ExpansionTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal),
                  title: Text(tr.faq4Q),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        tr.faq4A,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
                    label: Text(tr.contactSupport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr.connectingSupport)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 9. ABOUT MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _openAboutModal(BuildContext context, AppTranslations tr) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'QuickChat',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.mintLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr.appVersion,
                  style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr.appDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.system_update_rounded, color: Colors.white, size: 18),
                  label: Text(tr.checkUpdates, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr.alreadyLatestVersion),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.copyright,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 10. CONFIRM LOGOUT
  // ──────────────────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, AppTranslations tr) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(tr.logoutConfirmTitle),
            ],
          ),
          content: Text(tr.logoutConfirmContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(tr.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(socketProvider.notifier).disconnect();
                ref.read(authProvider.notifier).state = false;
                ApiService.currentUserId = '';
                ApiService.currentUserName = '';
                ApiService.currentUserPhone = '';
                ApiService.currentUserAvatar = '';
                context.go('/login');
              },
              child: Text(tr.logoutConfirmButton, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER SELECTOR MODAL
  // ──────────────────────────────────────────────────────────────────────────
  void _showOptionSelector(
    BuildContext context, {
    required String title,
    required String current,
    required List<String> options,
    Map<String, String>? displayLabels,
    required void Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...options.map((opt) {
                final isSel = opt == current;
                final label = displayLabels?[opt] ?? opt;
                return ListTile(
                  title: Text(label, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: AppTheme.primaryTeal) : null,
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
