import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_translations.dart';
import '../services/storage_helper.dart';

export '../l10n/app_translations.dart';

// ── Language Provider ────────────────────────────────────────────────────────
final languageProvider = StateProvider<String>((ref) {
  final saved = StorageHelper.getString('app_language');
  return saved ?? 'Bahasa Indonesia';
});

final translationsProvider = Provider<AppTranslations>((ref) {
  final lang = ref.watch(languageProvider);
  return AppTranslations.of(lang);
});

// ── Notifications Settings ───────────────────────────────────────────────────
class NotificationSettings {
  final bool messageNotifications;
  final bool groupNotifications;
  final bool callNotifications;
  final bool previewEnabled;
  final bool inAppSounds;
  final String ringtone; // 'Default', 'Harmoni', 'Chime', 'Digital'
  final String vibrateMode; // 'Default', 'Pendek', 'Panjang', 'Mati'

  const NotificationSettings({
    this.messageNotifications = true,
    this.groupNotifications = true,
    this.callNotifications = true,
    this.previewEnabled = true,
    this.inAppSounds = true,
    this.ringtone = 'Default',
    this.vibrateMode = 'Default',
  });

  NotificationSettings copyWith({
    bool? messageNotifications,
    bool? groupNotifications,
    bool? callNotifications,
    bool? previewEnabled,
    bool? inAppSounds,
    String? ringtone,
    String? vibrateMode,
  }) {
    return NotificationSettings(
      messageNotifications: messageNotifications ?? this.messageNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      callNotifications: callNotifications ?? this.callNotifications,
      previewEnabled: previewEnabled ?? this.previewEnabled,
      inAppSounds: inAppSounds ?? this.inAppSounds,
      ringtone: ringtone ?? this.ringtone,
      vibrateMode: vibrateMode ?? this.vibrateMode,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void toggleMessageNotifications(bool val) => state = state.copyWith(messageNotifications: val);
  void toggleGroupNotifications(bool val) => state = state.copyWith(groupNotifications: val);
  void toggleCallNotifications(bool val) => state = state.copyWith(callNotifications: val);
  void togglePreview(bool val) => state = state.copyWith(previewEnabled: val);
  void toggleInAppSounds(bool val) => state = state.copyWith(inAppSounds: val);
  void setRingtone(String val) => state = state.copyWith(ringtone: val);
  void setVibrateMode(String val) => state = state.copyWith(vibrateMode: val);
  void reset() => state = const NotificationSettings();
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

// ── Privacy & Security Settings ──────────────────────────────────────────────
class PrivacySecuritySettings {
  final String lastSeen; // 'Semua Orang', 'Kontak Saya', 'Tidak Ada'
  final String profilePhoto; // 'Semua Orang', 'Kontak Saya', 'Tidak Ada'
  final String aboutStatus; // 'Semua Orang', 'Kontak Saya', 'Tidak Ada'
  final bool readReceipts; // Centang biru
  final bool appLock; // Kunci aplikasi dengan sidik jari/PIN
  final List<String> blockedUsers;

  const PrivacySecuritySettings({
    this.lastSeen = 'Semua Orang',
    this.profilePhoto = 'Semua Orang',
    this.aboutStatus = 'Semua Orang',
    this.readReceipts = true,
    this.appLock = false,
    this.blockedUsers = const [],
  });

  PrivacySecuritySettings copyWith({
    String? lastSeen,
    String? profilePhoto,
    String? aboutStatus,
    bool? readReceipts,
    bool? appLock,
    List<String>? blockedUsers,
  }) {
    return PrivacySecuritySettings(
      lastSeen: lastSeen ?? this.lastSeen,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      aboutStatus: aboutStatus ?? this.aboutStatus,
      readReceipts: readReceipts ?? this.readReceipts,
      appLock: appLock ?? this.appLock,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}

class PrivacySecurityNotifier extends StateNotifier<PrivacySecuritySettings> {
  PrivacySecurityNotifier() : super(const PrivacySecuritySettings());

  void setLastSeen(String val) => state = state.copyWith(lastSeen: val);
  void setProfilePhoto(String val) => state = state.copyWith(profilePhoto: val);
  void setAboutStatus(String val) => state = state.copyWith(aboutStatus: val);
  void toggleReadReceipts(bool val) => state = state.copyWith(readReceipts: val);
  void toggleAppLock(bool val) => state = state.copyWith(appLock: val);
  void unblockUser(String uid) {
    state = state.copyWith(blockedUsers: state.blockedUsers.where((u) => u != uid).toList());
  }
}

final privacySecurityProvider =
    StateNotifierProvider<PrivacySecurityNotifier, PrivacySecuritySettings>((ref) {
  return PrivacySecurityNotifier();
});

// ── Chat Settings ─────────────────────────────────────────────────────────────
class ChatSettings {
  final String themeMode; // 'Terang', 'Gelap', 'Sistem'
  final String fontSize; // 'Kecil', 'Sedang', 'Besar'
  final String wallpaper; // 'default', 'mint', 'blue', 'dark', 'peach'
  final bool enterIsSend;
  final String lastBackup;

  const ChatSettings({
    this.themeMode = 'Terang',
    this.fontSize = 'Sedang',
    this.wallpaper = 'default',
    this.enterIsSend = true,
    this.lastBackup = 'Belum pernah dicadangkan',
  });

  ChatSettings copyWith({
    String? themeMode,
    String? fontSize,
    String? wallpaper,
    bool? enterIsSend,
    String? lastBackup,
  }) {
    return ChatSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wallpaper: wallpaper ?? this.wallpaper,
      enterIsSend: enterIsSend ?? this.enterIsSend,
      lastBackup: lastBackup ?? this.lastBackup,
    );
  }
}

class ChatSettingsNotifier extends StateNotifier<ChatSettings> {
  ChatSettingsNotifier() : super(const ChatSettings());

  void setThemeMode(String val) => state = state.copyWith(themeMode: val);
  void setFontSize(String val) => state = state.copyWith(fontSize: val);
  void setWallpaper(String val) => state = state.copyWith(wallpaper: val);
  void toggleEnterIsSend(bool val) => state = state.copyWith(enterIsSend: val);
  void recordBackup() {
    final now = DateTime.now();
    final timeStr =
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    state = state.copyWith(lastBackup: timeStr);
  }
}

final chatSettingsProvider = StateNotifierProvider<ChatSettingsNotifier, ChatSettings>((ref) {
  return ChatSettingsNotifier();
});

// ── Data & Storage Settings ──────────────────────────────────────────────────
class DataStorageSettings {
  final double cacheSizeMb;
  final bool autoDownloadWifiPhotos;
  final bool autoDownloadWifiVideos;
  final bool autoDownloadMobilePhotos;
  final bool autoDownloadMobileVideos;
  final String uploadQuality; // 'Standar', 'Tinggi (HD)'

  const DataStorageSettings({
    this.cacheSizeMb = 16.4,
    this.autoDownloadWifiPhotos = true,
    this.autoDownloadWifiVideos = true,
    this.autoDownloadMobilePhotos = true,
    this.autoDownloadMobileVideos = false,
    this.uploadQuality = 'Tinggi (HD)',
  });

  DataStorageSettings copyWith({
    double? cacheSizeMb,
    bool? autoDownloadWifiPhotos,
    bool? autoDownloadWifiVideos,
    bool? autoDownloadMobilePhotos,
    bool? autoDownloadMobileVideos,
    String? uploadQuality,
  }) {
    return DataStorageSettings(
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      autoDownloadWifiPhotos: autoDownloadWifiPhotos ?? this.autoDownloadWifiPhotos,
      autoDownloadWifiVideos: autoDownloadWifiVideos ?? this.autoDownloadWifiVideos,
      autoDownloadMobilePhotos: autoDownloadMobilePhotos ?? this.autoDownloadMobilePhotos,
      autoDownloadMobileVideos: autoDownloadMobileVideos ?? this.autoDownloadMobileVideos,
      uploadQuality: uploadQuality ?? this.uploadQuality,
    );
  }
}

class DataStorageNotifier extends StateNotifier<DataStorageSettings> {
  DataStorageNotifier() : super(const DataStorageSettings());

  void clearCache() => state = state.copyWith(cacheSizeMb: 0.0);
  void toggleWifiPhotos(bool val) => state = state.copyWith(autoDownloadWifiPhotos: val);
  void toggleWifiVideos(bool val) => state = state.copyWith(autoDownloadWifiVideos: val);
  void toggleMobilePhotos(bool val) => state = state.copyWith(autoDownloadMobilePhotos: val);
  void toggleMobileVideos(bool val) => state = state.copyWith(autoDownloadMobileVideos: val);
  void setUploadQuality(String val) => state = state.copyWith(uploadQuality: val);
}

final dataStorageProvider = StateNotifierProvider<DataStorageNotifier, DataStorageSettings>((ref) {
  return DataStorageNotifier();
});

// ── In-App Notification Center Items ─────────────────────────────────────────
class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type; // 'call', 'group', 'message', 'system'
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      title: title,
      message: message,
      time: time,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationCenterNotifier extends StateNotifier<List<AppNotificationItem>> {
  NotificationCenterNotifier()
      : super([
          const AppNotificationItem(
            id: 'notif_1',
            title: 'Panggilan Tak Terjawab',
            message: 'Teman Anda mencoba menghubungi via Panggilan Suara.',
            time: '10 mnt lalu',
            type: 'call',
            isRead: false,
          ),
          const AppNotificationItem(
            id: 'notif_2',
            title: 'Grup Baru Dibuat',
            message: 'Anda telah ditambahkan ke grup obrolan.',
            time: '1 jam lalu',
            type: 'group',
            isRead: false,
          ),
          const AppNotificationItem(
            id: 'notif_3',
            title: 'Keamanan Akun',
            message: 'Enkripsi ujung-ke-ujung aktif untuk semua obrolan Anda.',
            time: 'Kemarin',
            type: 'system',
            isRead: true,
          ),
        ]);

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenterNotifier, List<AppNotificationItem>>((ref) {
  return NotificationCenterNotifier();
});
