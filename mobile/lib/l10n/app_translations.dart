class AppTranslations {
  static const String indonesian = 'Bahasa Indonesia';
  static const String english = 'English';
  static const String arabic = 'العربية';
  static const String japanese = '日本語';
  static const String chinese = '简体中文';
  static const String spanish = 'Español';

  final String lang;
  AppTranslations(this.lang);

  static AppTranslations of(String lang) => AppTranslations(lang);

  // Helper to pick based on language
  String _t({
    required String id,
    required String en,
    required String ar,
    required String ja,
    required String zh,
    required String es,
  }) {
    switch (lang) {
      case english:
        return en;
      case arabic:
        return ar;
      case japanese:
        return ja;
      case chinese:
        return zh;
      case spanish:
        return es;
      case indonesian:
      default:
        return id;
    }
  }

  // ── Navigation Tabs ────────────────────────────────────────────────────────
  String get tabProfile => _t(
        id: 'Profil',
        en: 'Profile',
        ar: 'الملف الشخصي',
        ja: 'プロフィール',
        zh: '个人资料',
        es: 'Perfil',
      );

  String get tabChats => _t(
        id: 'Obrolan',
        en: 'Chats',
        ar: 'المحادثات',
        ja: 'チャット',
        zh: '聊天',
        es: 'Chats',
      );

  String get tabSettings => _t(
        id: 'Pengaturan',
        en: 'Settings',
        ar: 'الإعدادات',
        ja: '設定',
        zh: '设置',
        es: 'Ajustes',
      );

  // ── Common Actions ─────────────────────────────────────────────────────────
  String get cancel => _t(
        id: 'Batal',
        en: 'Cancel',
        ar: 'إلغاء',
        ja: 'キャンセル',
        zh: '取消',
        es: 'Cancelar',
      );

  String get close => _t(
        id: 'Tutup',
        en: 'Close',
        ar: 'إغلاق',
        ja: '閉じる',
        zh: '关闭',
        es: 'Cerrar',
      );

  String get save => _t(
        id: 'Simpan Perubahan',
        en: 'Save Changes',
        ar: 'حفظ التعديلات',
        ja: '変更を保存',
        zh: '保存修改',
        es: 'Guardar cambios',
      );

  // ── Settings Screen Header & Quick Grid ────────────────────────────────────
  String hello(String name) => _t(
        id: 'Halo, $name!',
        en: 'Hello, $name!',
        ar: 'مرحباً، $name!',
        ja: 'こんにちは、$nameさん！',
        zh: '你好，$name！',
        es: '¡Hola, $name!',
      );

  String get memberSubtitle => _t(
        id: 'Anggota QuickChat',
        en: 'QuickChat Member',
        ar: 'عضو QuickChat',
        ja: 'QuickChat メンバー',
        zh: 'QuickChat 会员',
        es: 'Miembro de QuickChat',
      );

  String get editProfile => _t(
        id: 'Edit Profil',
        en: 'Edit Profile',
        ar: 'تعديل الملف',
        ja: 'プロフィール編集',
        zh: '编辑资料',
        es: 'Editar perfil',
      );

  String get notifications => _t(
        id: 'Notifikasi',
        en: 'Notifications',
        ar: 'الإشعارات',
        ja: '通知設定',
        zh: '通知设置',
        es: 'Notificaciones',
      );

  String get privacySecurity => _t(
        id: 'Privasi & Keamanan',
        en: 'Privacy & Security',
        ar: 'الخصوصية والأمان',
        ja: 'プライバシーとセキュリティ',
        zh: '隐私与安全',
        es: 'Privacidad y seguridad',
      );

  String get chatSettings => _t(
        id: 'Pengaturan Chat',
        en: 'Chat Settings',
        ar: 'إعدادات المحادثة',
        ja: 'チャット設定',
        zh: '聊天设置',
        es: 'Ajustes de chat',
      );

  String get dataStorage => _t(
        id: 'Data & Penyimpanan',
        en: 'Data & Storage',
        ar: 'البيانات والتخزين',
        ja: 'データとストレージ',
        zh: '数据与存储',
        es: 'Datos y almacenamiento',
      );

  String get language => _t(
        id: 'Bahasa',
        en: 'Language',
        ar: 'اللغة',
        ja: '言語',
        zh: '语言',
        es: 'Idioma',
      );

  String get help => _t(
        id: 'Bantuan',
        en: 'Help',
        ar: 'المساعدة',
        ja: 'ヘルプ',
        zh: '帮助',
        es: 'Ayuda',
      );

  String get about => _t(
        id: 'Tentang',
        en: 'About',
        ar: 'حول التطبيق',
        ja: 'アプリ情報',
        zh: '关于我们',
        es: 'Acerca de',
      );

  String get logoutButton => _t(
        id: 'Keluar (Logout)',
        en: 'Log Out',
        ar: 'تسجيل الخروج',
        ja: 'ログアウト',
        zh: '退出登录',
        es: 'Cerrar sesión',
      );

  // ── 1. Notification Center Modal ──────────────────────────────────────────
  String get notificationCenterTitle => _t(
        id: 'Pusat Notifikasi',
        en: 'Notification Center',
        ar: 'مركز الإشعارات',
        ja: '通知センター',
        zh: '通知中心',
        es: 'Centro de notificaciones',
      );

  String get markAllAsRead => _t(
        id: 'Tandai Dibaca',
        en: 'Mark as Read',
        ar: 'تحديد كمقروء',
        ja: '既読にする',
        zh: '全部标为已读',
        es: 'Marcar leídos',
      );

  String get allNotifsMarked => _t(
        id: 'Semua notifikasi ditandai telah dibaca',
        en: 'All notifications marked as read',
        ar: 'تم تحديد جميع الإشعارات كمقروءة',
        ja: 'すべての通知を既読にしました',
        zh: '所有通知已标记为已读',
        es: 'Todas las notificaciones leídas',
      );

  String get noNewNotifications => _t(
        id: 'Tidak ada notifikasi baru',
        en: 'No new notifications',
        ar: 'لا توجد إشعارات جديدة',
        ja: '新しい通知はありません',
        zh: '暂无新通知',
        es: 'No hay notificaciones nuevas',
      );

  String get clearAllNotifs => _t(
        id: 'Bersihkan Semua Notifikasi',
        en: 'Clear All Notifications',
        ar: 'مسح جميع الإشعارات',
        ja: 'すべての通知を削除',
        zh: '清空所有通知',
        es: 'Borrar todas las notificaciones',
      );

  // ── 2. Edit Profile Modal ──────────────────────────────────────────────────
  String get editProfileTitle => _t(
        id: 'Edit Profil',
        en: 'Edit Profile',
        ar: 'تعديل الملف الشخصي',
        ja: 'プロフィール編集',
        zh: '编辑个人资料',
        es: 'Editar perfil',
      );

  String get chooseFromGallery => _t(
        id: 'Pilih Foto dari Galeri',
        en: 'Choose Photo from Gallery',
        ar: 'اختر صورة من المعرض',
        ja: 'ギャラリーから写真を選択',
        zh: '从相册选择照片',
        es: 'Elegir foto de la galería',
      );

  String get uploading => _t(
        id: 'Mengunggah...',
        en: 'Uploading...',
        ar: 'جارٍ التحميل...',
        ja: 'アップロード中...',
        zh: '上传中...',
        es: 'Subiendo...',
      );

  String get fullNameLabel => _t(
        id: 'Nama Lengkap',
        en: 'Full Name',
        ar: 'الاسم الكامل',
        ja: '氏名',
        zh: '姓名',
        es: 'Nombre completo',
      );

  String get bioLabel => _t(
        id: 'Status / Bio',
        en: 'Status / Bio',
        ar: 'الحالة / النبذة',
        ja: 'ステータスメッセージ',
        zh: '个人签名',
        es: 'Estado / Info',
      );

  String get profileUpdatedSuccess => _t(
        id: 'Profil berhasil diperbarui!',
        en: 'Profile updated successfully!',
        ar: 'تم تحديث الملف بنجاح!',
        ja: 'プロフィールを更新しました！',
        zh: '个人资料更新成功！',
        es: '¡Perfil actualizado con éxito!',
      );

  // ── 3. Notification Settings Modal ─────────────────────────────────────────
  String get notifSettingsTitle => _t(
        id: 'Pengaturan Notifikasi',
        en: 'Notification Settings',
        ar: 'إعدادات الإشعارات',
        ja: '通知設定',
        zh: '通知设置',
        es: 'Ajustes de notificaciones',
      );

  String get directMessagesTitle => _t(
        id: 'Notifikasi Pesan Pribadi',
        en: 'Direct Messages',
        ar: 'الرسائل الخاصة',
        ja: 'ダイレクトメッセージ通知',
        zh: '私聊消息通知',
        es: 'Mensajes directos',
      );

  String get directMessagesSub => _t(
        id: 'Tampilkan pemberitahuan saat ada pesan 1-on-1 baru',
        en: 'Show notifications for incoming 1-on-1 messages',
        ar: 'إظهار إشعارات للرسائل الفردية الجديدة',
        ja: '新しいメッセージを受信したときに通知',
        zh: '收到新私聊消息时显示通知',
        es: 'Mostrar notificaciones para mensajes nuevos',
      );

  String get groupNotifsTitle => _t(
        id: 'Notifikasi Grup',
        en: 'Group Notifications',
        ar: 'إشعارات المجموعات',
        ja: 'グループ通知',
        zh: '群组通知',
        es: 'Notificaciones de grupo',
      );

  String get groupNotifsSub => _t(
        id: 'Tampilkan pemberitahuan untuk aktivitas grup',
        en: 'Show notifications for group activities',
        ar: 'إظهار إشعارات لنشاطات المجموعات',
        ja: 'グループのアクティビティを通知',
        zh: '显示群组聊天与活动通知',
        es: 'Mostrar notificaciones de grupos',
      );

  String get callNotifsTitle => _t(
        id: 'Panggilan Suara & Video',
        en: 'Voice & Video Calls',
        ar: 'المكالمات الصوتية والمرئية',
        ja: '音声・ビデオ通話',
        zh: '语音与视频通话',
        es: 'Llamadas de voz y video',
      );

  String get callNotifsSub => _t(
        id: 'Deringkan dan getarkan saat ada panggilan masuk',
        en: 'Ring and vibrate on incoming calls',
        ar: 'الرنين والاهتزاز للمكالمات الواردة',
        ja: '着信時に着信音とバイブレーションを作動',
        zh: '来电时响铃并振动提醒',
        es: 'Sonar y vibrar en llamadas entrantes',
      );

  String get previewTitle => _t(
        id: 'Pratinjau Pesan',
        en: 'Message Preview',
        ar: 'معاينة الرسائل',
        ja: 'メッセージプレビュー',
        zh: '消息内容预览',
        es: 'Vista previa de mensajes',
      );

  String get previewSub => _t(
        id: 'Sertakan cuplikan isi teks di spanduk notifikasi',
        en: 'Include text snippet in notification banner',
        ar: 'تضمين مقتطف من النص في شريط الإشعار',
        ja: '通知バナーにテキスト本文を含める',
        zh: '在通知横幅中显示消息文字摘要',
        es: 'Mostrar fragmento de texto en la notificación',
      );

  String get inAppSoundsTitle => _t(
        id: 'Suara Dalam Aplikasi',
        en: 'In-App Sounds',
        ar: 'أصوات داخل التطبيق',
        ja: 'アプリ内サウンド',
        zh: '应用内音效',
        es: 'Sonidos en la app',
      );

  String get inAppSoundsSub => _t(
        id: 'Bunyikan efek suara saat mengirim/menerima pesan',
        en: 'Play sound effect when sending/receiving messages',
        ar: 'تشغيل صوت عند إرسال أو استلام رسالة',
        ja: '送受信時に効果音を再生',
        zh: '收发消息时播放音效',
        es: 'Reproducir sonido al enviar y recibir',
      );

  String get resetToDefault => _t(
        id: 'Kembalikan ke Default',
        en: 'Reset to Default',
        ar: 'استعادة الافتراضي',
        ja: '初期設定に戻す',
        zh: '恢复默认设置',
        es: 'Restablecer a valores por defecto',
      );

  String get notifSettingsReset => _t(
        id: 'Pengaturan notifikasi dikembalikan ke awal',
        en: 'Notification settings reset to default',
        ar: 'تمت استعادة إعدادات الإشعارات الافتراضية',
        ja: '通知設定を初期設定に戻しました',
        zh: '通知设置已重置为默认值',
        es: 'Ajustes de notificaciones restablecidos',
      );

  // ── 4. Privacy & Security Modal ────────────────────────────────────────────
  String get privacySecurityTitle => _t(
        id: 'Privasi & Keamanan',
        en: 'Privacy & Security',
        ar: 'الخصوصية والأمان',
        ja: 'プライバシーとセキュリティ',
        zh: '隐私与安全',
        es: 'Privacidad y seguridad',
      );

  String get lastSeenTitle => _t(
        id: 'Terakhir Dilihat & Online',
        en: 'Last Seen & Online',
        ar: 'آخر ظهور وحالة الاتصال',
        ja: '最終ログイン＆オンライン',
        zh: '最后上线与在线状态',
        es: 'Última vez y En línea',
      );

  String get lastSeenModalTitle => _t(
        id: 'Siapa yang dapat melihat terakhir dilihat?',
        en: 'Who can see my last seen?',
        ar: 'من يمكنه رؤية آخر ظهور لي؟',
        ja: '最終ログインを閲覧できる対象',
        zh: '谁可以看到我的最后上线时间？',
        es: '¿Quién puede ver mi última vez?',
      );

  String get profilePhotoTitle => _t(
        id: 'Foto Profil',
        en: 'Profile Photo',
        ar: 'صورة الملف الشخصي',
        ja: 'プロフィール写真',
        zh: '个人头像',
        es: 'Foto de perfil',
      );

  String get profilePhotoModalTitle => _t(
        id: 'Siapa yang dapat melihat foto profil?',
        en: 'Who can see my profile photo?',
        ar: 'من يمكنه رؤية صورتي الشخصية؟',
        ja: 'プロフィール写真を閲覧できる対象',
        zh: '谁可以看到我的个人头像？',
        es: '¿Quién puede ver mi foto de perfil?',
      );

  String get bioStatusTitle => _t(
        id: 'Info Status / Bio',
        en: 'Status / Bio',
        ar: 'الحالة / النبذة',
        ja: 'ステータスメッセージ',
        zh: '个性签名',
        es: 'Info / Estado',
      );

  String get bioStatusModalTitle => _t(
        id: 'Siapa yang dapat melihat status/bio Anda?',
        en: 'Who can see your status/bio?',
        ar: 'من يمكنه رؤية حالتك/نبذتك الشخصية؟',
        ja: 'ステータスを閲覧できる対象',
        zh: '谁可以看到您的个性签名？',
        es: '¿Quién puede ver tu información?',
      );

  String optEveryone = 'Semua Orang';
  String optMyContacts = 'Kontak Saya';
  String optNobody = 'Tidak Ada';

  String translatePrivacyOption(String opt) {
    if (opt == 'Semua Orang' || opt == 'Everyone') {
      return _t(id: 'Semua Orang', en: 'Everyone', ar: 'الجميع', ja: '全員', zh: '所有人', es: 'Todos');
    }
    if (opt == 'Kontak Saya' || opt == 'My Contacts') {
      return _t(id: 'Kontak Saya', en: 'My Contacts', ar: 'جهاتي', ja: '連絡先のみ', zh: '我的联系人', es: 'Mis contactos');
    }
    if (opt == 'Tidak Ada' || opt == 'Nobody') {
      return _t(id: 'Tidak Ada', en: 'Nobody', ar: 'لا أحد', ja: '非公開', zh: '没有人', es: 'Nadie');
    }
    return opt;
  }

  List<String> get privacyOptions => [
        _t(id: 'Semua Orang', en: 'Everyone', ar: 'الجميع', ja: '全員', zh: '所有人', es: 'Todos'),
        _t(id: 'Kontak Saya', en: 'My Contacts', ar: 'جهاتي', ja: '連絡先のみ', zh: '我的联系人', es: 'Mis contactos'),
        _t(id: 'Tidak Ada', en: 'Nobody', ar: 'لا أحد', ja: '非公開', zh: '没有人', es: 'Nadie'),
      ];

  String get readReceiptsTitle => _t(
        id: 'Laporan Dibaca (Centang Biru)',
        en: 'Read Receipts (Blue Ticks)',
        ar: 'مؤشرات قراءة الرسائل',
        ja: '開封確認（既読マーク）',
        zh: '已读回执 (蓝勾)',
        es: 'Confirmaciones de lectura',
      );

  String get readReceiptsSub => _t(
        id: 'Jika dinonaktifkan, Anda tidak akan mengirim atau melihat laporan telah dibaca',
        en: 'If disabled, you won\'t send or receive read receipts',
        ar: 'عند التعطيل، لن ترسل أو ترى مؤشرات القراءة',
        ja: 'オフにすると既読マークを送受信しなくなります',
        zh: '关闭后，双方均无法查看消息已读状态',
        es: 'Si se desactiva, no verás ni enviarás confirmaciones',
      );

  String get appLockTitle => _t(
        id: 'Kunci Aplikasi (Biometrik)',
        en: 'App Lock (Biometrics)',
        ar: 'قفل التطبيق (القياسات الحيوية)',
        ja: 'アプリロック（生体認証）',
        zh: '应用加锁 (生物识别)',
        es: 'Bloqueo de app (Biometría)',
      );

  String get appLockSub => _t(
        id: 'Wajibkan sidik jari/sensor wajah untuk membuka QuickChat',
        en: 'Require fingerprint or face recognition to open QuickChat',
        ar: 'طلب بصمة الإصبع أو الوجه لفتح QuickChat',
        ja: '指紋または顔認証でQuickChatを開く',
        zh: '要求使用指纹或人脸识别开启应用',
        es: 'Requerir huella o rostro para abrir QuickChat',
      );

  String get encryptionNote => _t(
        id: 'Enkripsi Ujung-ke-Ujung aktif. Pesan teks dan panggilan hanya bisa dibaca oleh Anda dan teman bicara.',
        en: 'End-to-End Encryption active. Messages and calls can only be read by you and the recipient.',
        ar: 'التشفير التام مفعل. لا يمكن لأحد غيرك وقرينك في المحادثة قراءة الرسائل والمكالمات.',
        ja: 'エンドツーエンド暗号化が有効です。メッセージと通話はあなたと相手の間だけで保護されます。',
        zh: '端到端加密已启用。消息和通话内容仅您与对方可见。',
        es: 'Cifrado de extremo a extremo activo. Los mensajes y llamadas solo son legibles entre tú y tu contacto.',
      );

  // ── 5. Chat Settings Modal ─────────────────────────────────────────────────
  String get chatSettingsTitle => _t(
        id: 'Pengaturan Chat',
        en: 'Chat Settings',
        ar: 'إعدادات المحادثة',
        ja: 'チャット設定',
        zh: '聊天设置',
        es: 'Ajustes de chat',
      );

  String get chatThemeTitle => _t(
        id: 'Tema Obrolan',
        en: 'Chat Theme',
        ar: 'مظهر المحادثة',
        ja: 'チャットテーマ',
        zh: '聊天主题',
        es: 'Tema del chat',
      );

  String get themeLight => _t(id: 'Terang', en: 'Light', ar: 'فاتح', ja: 'ライト', zh: '浅色', es: 'Claro');
  String get themeDark => _t(id: 'Gelap', en: 'Dark', ar: 'داكن', ja: 'ダーク', zh: '深色', es: 'Oscuro');
  String get themeSystem => _t(id: 'Sistem', en: 'System', ar: 'النظام', ja: 'システム', zh: '系统', es: 'Sistema');

  String get wallpaperTitle => _t(
        id: 'Warna Latar Obrolan (Wallpaper)',
        en: 'Chat Wallpaper',
        ar: 'خلفية المحادثة',
        ja: 'チャット壁紙',
        zh: '聊天背景壁纸',
        es: 'Fondo del chat',
      );

  String get wpDefault => _t(id: 'Default', en: 'Default', ar: 'الافتراضي', ja: '標準', zh: '默认', es: 'Por defecto');
  String get wpTeal => _t(id: 'Toska', en: 'Teal', ar: 'تركوازي', ja: 'ティール', zh: '青碧', es: 'Verde azulado');
  String get wpSky => _t(id: 'Langit', en: 'Sky', ar: 'سماوي', ja: 'スカイ', zh: '天空蓝', es: 'Cielo');
  String get wpPeach => _t(id: 'Peach', en: 'Peach', ar: 'خوخي', ja: 'ピーチ', zh: '桃色', es: 'Melocotón');
  String get wpDark => _t(id: 'Gelap', en: 'Dark', ar: 'داكن', ja: 'ダーク', zh: '深黑', es: 'Oscuro');

  String get fontSizeTitle => _t(
        id: 'Ukuran Teks Pesan',
        en: 'Message Font Size',
        ar: 'حجم خط الرسائل',
        ja: 'メッセージ文字サイズ',
        zh: '消息字体大小',
        es: 'Tamaño del texto',
      );

  String get fontSizeModalTitle => _t(
        id: 'Pilih Ukuran Huruf',
        en: 'Select Font Size',
        ar: 'اختر حجم الخط',
        ja: 'フォントサイズを選択',
        zh: '选择字体大小',
        es: 'Seleccionar tamaño de letra',
      );

  String get sizeSmall => _t(id: 'Kecil', en: 'Small', ar: 'صغير', ja: '小', zh: '小', es: 'Pequeño');
  String get sizeMedium => _t(id: 'Sedang', en: 'Medium', ar: 'متوسط', ja: '中', zh: '中', es: 'Mediano');
  String get sizeLarge => _t(id: 'Besar', en: 'Large', ar: 'كبير', ja: '大', zh: '大', es: 'Grande');

  List<String> get fontSizes => [sizeSmall, sizeMedium, sizeLarge];

  String get enterIsSendTitle => _t(
        id: 'Enter untuk Mengirim',
        en: 'Enter to Send',
        ar: 'مفتاح Enter للإرسال',
        ja: 'Enterキーで送信',
        zh: '按 Enter 键发送',
        es: 'Enter para enviar',
      );

  String get enterIsSendSub => _t(
        id: 'Menekan tombol Enter akan langsung mengirim pesan',
        en: 'Pressing Enter sends the message immediately',
        ar: 'الضغط على زر Enter سيرسل الرسالة فوراً',
        ja: 'Enterキーを押すとメッセージがすぐに送信されます',
        zh: '按回车键将立即发送该消息',
        es: 'Presionar Enter enviará el mensaje inmediatamente',
      );

  String get chatBackupTitle => _t(
        id: 'Cadangkan Obrolan',
        en: 'Chat Backup',
        ar: 'نسخ المحادثات احتياطياً',
        ja: 'チャットのバックアップ',
        zh: '聊天记录备份',
        es: 'Copia de seguridad del chat',
      );

  String lastBackupText(String time) => _t(
        id: 'Terakhir: $time',
        en: 'Last: $time',
        ar: 'آخر نسخة: $time',
        ja: '前回: $time',
        zh: '最近备份: $time',
        es: 'Última: $time',
      );

  String get backupNow => _t(
        id: 'Cadangkan',
        en: 'Back Up',
        ar: 'نسخ احتياطي',
        ja: 'バックアップ',
        zh: '立即备份',
        es: 'Respaldar',
      );

  String get backupSuccess => _t(
        id: 'Riwayat obrolan berhasil dicadangkan secara lokal!',
        en: 'Chat history backed up locally!',
        ar: 'تم حفظ النسخة الاحتياطية بنجاح!',
        ja: 'チャット履歴をローカルにバックアップしました！',
        zh: '聊天记录已成功本地备份！',
        es: '¡Historial respaldado localmente con éxito!',
      );

  // ── 6. Data & Storage Modal ────────────────────────────────────────────────
  String get dataStorageTitle => _t(
        id: 'Data & Penyimpanan',
        en: 'Data & Storage',
        ar: 'البيانات والتخزين',
        ja: 'データとストレージ',
        zh: '数据与存储',
        es: 'Datos y almacenamiento',
      );

  String get storageUsageTitle => _t(
        id: 'Penggunaan Cache & Media',
        en: 'Cache & Media Usage',
        ar: 'استهلاك الذاكرة والوسائط',
        ja: 'キャッシュとメディアの使用状況',
        zh: '缓存与媒体占用',
        es: 'Uso de caché y medios',
      );

  String get mediaStoredSub => _t(
        id: 'Foto & Pesan tersimpan rapi',
        en: 'Photos & messages stored safely',
        ar: 'الصور والرسائل محفوظة بأمان',
        ja: '写真やメッセージが安全に保存されています',
        zh: '照片与消息均安全保存',
        es: 'Fotos y mensajes guardados',
      );

  String get clearCache => _t(
        id: 'Bersihkan Cache',
        en: 'Clear Cache',
        ar: 'مسح الذاكرة المؤقتة',
        ja: 'キャッシュを消去',
        zh: '清理缓存',
        es: 'Limpiar caché',
      );

  String get cacheClearedSuccess => _t(
        id: 'Cache aplikasi berhasil dibersihkan!',
        en: 'App cache cleared successfully!',
        ar: 'تم مسح ذاكرة التخزين المؤقت بنجاح!',
        ja: 'アプリのキャッシュを消去しました！',
        zh: '应用缓存已成功清除！',
        es: '¡Caché de la app limpiada con éxito!',
      );

  String get autoDownloadTitle => _t(
        id: 'Unduh Otomatis Media',
        en: 'Auto-Download Media',
        ar: 'التنزيل التلقائي للوسائط',
        ja: 'メディアの自動ダウンロード',
        zh: '媒体自动下载',
        es: 'Descarga automática de medios',
      );

  String get photoWifi => _t(
        id: 'Foto saat Wi-Fi',
        en: 'Photos on Wi-Fi',
        ar: 'الصور عبر Wi-Fi',
        ja: '写真 (Wi-Fi)',
        zh: '照片 (Wi-Fi 网络)',
        es: 'Fotos en Wi-Fi',
      );

  String get videoWifi => _t(
        id: 'Video saat Wi-Fi',
        en: 'Videos on Wi-Fi',
        ar: 'الفيديوهات عبر Wi-Fi',
        ja: '動画 (Wi-Fi)',
        zh: '视频 (Wi-Fi 网络)',
        es: 'Videos en Wi-Fi',
      );

  String get photoCellular => _t(
        id: 'Foto saat Data Seluler',
        en: 'Photos on Cellular Data',
        ar: 'الصور عبر بيانات الهاتف',
        ja: '写真 (モバイル通信)',
        zh: '照片 (移动数据网络)',
        es: 'Fotos en datos móviles',
      );

  String get uploadQualityTitle => _t(
        id: 'Kualitas Unggahan Media',
        en: 'Media Upload Quality',
        ar: 'جودة رفع الوسائط',
        ja: 'メディアアップロード画質',
        zh: '媒体上传画质',
        es: 'Calidad de subida de medios',
      );

  String get uploadQualityModalTitle => _t(
        id: 'Kualitas Foto & Video',
        en: 'Photo & Video Quality',
        ar: 'جودة الصور والفيديو',
        ja: '写真・動画の画質',
        zh: '照片与视频画质',
        es: 'Calidad de fotos y videos',
      );

  String get qualityStandard => _t(
        id: 'Standar (Hemat Data)',
        en: 'Standard (Data Saver)',
        ar: 'قياسي (توفير البيانات)',
        ja: '標準 (データ節約)',
        zh: '标准 (节省流量)',
        es: 'Estándar (Ahorro de datos)',
      );

  String get qualityHD => _t(
        id: 'Tinggi (HD)',
        en: 'High Quality (HD)',
        ar: 'عالية (HD)',
        ja: '高画質 (HD)',
        zh: '高清 (HD)',
        es: 'Alta definición (HD)',
      );

  List<String> get uploadQualities => [qualityStandard, qualityHD];

  // ── 7. Language Selector Modal ─────────────────────────────────────────────
  String get selectLanguageTitle => _t(
        id: 'Pilih Bahasa (Language)',
        en: 'Select Language',
        ar: 'اختر اللغة (Language)',
        ja: '言語を選択 (Language)',
        zh: '选择语言 (Language)',
        es: 'Seleccionar idioma (Language)',
      );

  String langChangedToast(String targetName) => _t(
        id: 'Bahasa berhasil diubah ke $targetName!',
        en: 'Language successfully changed to $targetName!',
        ar: 'تم تغيير اللغة بنجاح إلى $targetName!',
        ja: '言語を $targetName に切り替えました！',
        zh: '语言已成功切换为 $targetName！',
        es: '¡Idioma cambiado con éxito a $targetName!',
      );

  // ── 8. Help & FAQ Modal ────────────────────────────────────────────────────
  String get helpCenterTitle => _t(
        id: 'Pusat Bantuan & FAQ',
        en: 'Help Center & FAQ',
        ar: 'مركز المساعدة والأسئلة الشائعة',
        ja: 'ヘルプ＆よくある質問',
        zh: '帮助中心与常见问题',
        es: 'Centro de ayuda y FAQ',
      );

  String get faq1Q => _t(
        id: 'Bagaimana cara telepon & video call?',
        en: 'How to make voice & video calls?',
        ar: 'كيف يمكنني إجراء مكالمات صوت وفيديو؟',
        ja: '音声・ビデオ通話の方法は？',
        zh: '如何拨打语音和视频电话？',
        es: '¿Cómo hacer llamadas y videollamadas?',
      );

  String get faq1A => _t(
        id: 'Buka obrolan teman, lalu ketuk ikon Telepon di kanan atas untuk panggilan suara, atau ikon Kamera Video untuk video call. Penerima akan langsung menerima pop-up panggilan masuk.',
        en: 'Open a chat with a friend, then tap the Phone icon at the top right for voice call, or the Video Camera icon for video call. The recipient will receive an incoming call pop-up instantly.',
        ar: 'افتح محادثة الصديق، ثم اضغط على أيقونة الهاتف في أعلى اليمين لمكالمة صوتية، أو أيقونة الكاميرا لمكالمة فيديو. سيتلقى المستلم إشعاراً فورياً للمكالمة الواردة.',
        ja: '友達のチャットを開き、右上の電話アイコンをタップすると音声通話、ビデオカメラアイコンをタップするとビデオ通話が発信されます。相手には即座に着信ポップアップが表示されます。',
        zh: '打开好友聊天窗口，点击右上角电话图标即可拨打语音通话，点击摄像机图标即可拨打视频电话。对方会立即收到来电提醒弹窗。',
        es: 'Abre el chat de un amigo y toca el ícono de Teléfono arriba a la derecha para llamada de voz, o la Cámara para videollamada. El destinatario recibirá la llamada al instante.',
      );

  String get faq2Q => _t(
        id: 'Bagaimana cara membuat grup obrolan?',
        en: 'How to create a group chat?',
        ar: 'كيف أقوم بإنشاء مجموعة محادثة؟',
        ja: 'グループチャットの作成方法は？',
        zh: '如何创建群聊？',
        es: '¿Cómo crear un grupo de chat?',
      );

  String get faq2A => _t(
        id: 'Buka tab Obrolan di layar utama, lalu ketuk tombol Buat Grup Baru di atas. Beri nama grup, pilih anggota dari kontak Anda, lalu ketuk Buat Grup.',
        en: 'Go to the Chats tab on the main screen, then tap the Create New Group button. Enter the group name, select members from your contacts, and tap Create Group.',
        ar: 'انتقل إلى تبويب المحادثات في الشاشة الرئيسية، ثم اضغط على زر إنشاء مجموعة جديدة. أدخل اسم المجموعة وحدد الأعضاء ثم اضغط تأكيد الإنشاء.',
        ja: 'メイン画面のチャットタブを開き、「新規グループ作成」ボタンをタップします。グループ名を入力し連絡先からメンバーを選んで作成を完了します。',
        zh: '进入主屏幕的聊天选项卡，点击上方的“创建新群聊”按钮。输入群名称，从联系人中勾选成员并确认创建。',
        es: 'Ve a la pestaña Chats y toca "Crear nuevo grupo". Ingresa el nombre del grupo, selecciona miembros de tus contactos y pulsa Crear grupo.',
      );

  String get faq3Q => _t(
        id: 'Bagaimana cara upload foto status & lihat viewers?',
        en: 'How to share stories and view viewers?',
        ar: 'كيف أشارك حالة (قصة) وأعرف من شاهدها؟',
        ja: 'ストーリーの投稿と閲覧者の確認方法は？',
        zh: '如何发布动态故事并查看访客？',
        es: '¿Cómo publicar historias y ver quién las vio?',
      );

  String get faq3A => _t(
        id: 'Di tab Obrolan, ketuk tanda "+" pada lingkaran "Status Saya". Pilih foto dari galeri Anda. Setelah dibagikan, buka status Anda untuk melihat daftar teman yang telah melihat status Anda.',
        en: 'In the Chats tab, tap the "+" icon on the "My Story" circle. Select a photo from your gallery. Once posted, tap your story to see who viewed it.',
        ar: 'في تبويب المحادثات، اضغط على علامة "+" على دائرة "حالتي". اختر صورة من المعرض. بعد النشر، افتح حالتك لعرض قائمة من شاهدها.',
        ja: 'チャットタブの「マストーリー」の「＋」アイコンをタップし、写真を選択して投稿します。投稿後に自分のストーリーを開くと閲覧者一覧を確認できます。',
        zh: '在聊天页面点击“我的故事”圆圈上的“+”号，从相册选择照片发布。发布后点击该动态即可查看已浏览的好友列表。',
        es: 'En la pestaña Chats, pulsa el "+" en "Mi historia". Elige una foto de la galería. Tras publicarla, tócala para ver quién la ha visto.',
      );

  String get faq4Q => _t(
        id: 'Apakah percakapan saya aman?',
        en: 'Are my conversations secure?',
        ar: 'هل محادثاتي آمنة ومشفرة؟',
        ja: '会話は安全に保護されていますか？',
        zh: '我的聊天记录安全吗？',
        es: '¿Mis conversaciones son seguras?',
      );

  String get faq4A => _t(
        id: 'Ya! QuickChat menerapkan enkripsi ujung-ke-ujung (end-to-end encryption) untuk pesan teks, suara, dan panggilan video.',
        en: 'Yes! QuickChat implements end-to-end encryption for text messages, voice notes, and video calls.',
        ar: 'نعم! يطبق QuickChat التشفير من طرف لطرف للرسائل النصية والصوت ومكالمات الفيديو.',
        ja: 'はい！QuickChatはテキストメッセージ、音声、ビデオ通話にエンドツーエンドの暗号化を採用しています。',
        zh: '是的！QuickChat 对文本消息、语音通话和视频呼叫均采用严格的端到端加密保护。',
        es: '¡Sí! QuickChat implementa cifrado de extremo a extremo para mensajes, voz y videollamadas.',
      );

  String get contactSupport => _t(
        id: 'Hubungi Dukungan QuickChat',
        en: 'Contact QuickChat Support',
        ar: 'تواصل مع فريق دعم QuickChat',
        ja: 'QuickChat サポートに問い合わせ',
        zh: '联系 QuickChat 客服支持',
        es: 'Contactar al soporte de QuickChat',
      );

  String get connectingSupport => _t(
        id: 'Menghubungkan ke Pusat Bantuan QuickChat...',
        en: 'Connecting to QuickChat Help Center...',
        ar: 'جارٍ الاتصال بمركز دعم QuickChat...',
        ja: 'QuickChat ヘルプセンターに接続しています...',
        zh: '正在连接 QuickChat 帮助中心...',
        es: 'Conectando al Centro de Ayuda...',
      );

  // ── 9. About Modal ─────────────────────────────────────────────────────────
  String get aboutTitle => _t(
        id: 'Tentang QuickChat',
        en: 'About QuickChat',
        ar: 'حول QuickChat',
        ja: 'QuickChat について',
        zh: '关于 QuickChat',
        es: 'Acerca de QuickChat',
      );

  String get appName => 'QuickChat';

  String get appVersion => _t(
        id: 'Versi 1.2.0 (Build 2026.09-Release)',
        en: 'Version 1.2.0 (Build 2026.09-Release)',
        ar: 'الإصدار 1.2.0 (نسخة 2026.09)',
        ja: 'バージョン 1.2.0 (Build 2026.09-Release)',
        zh: '版本 1.2.0 (Build 2026.09-Release)',
        es: 'Versión 1.2.0 (Build 2026.09-Release)',
      );

  String get appDescription => _t(
        id: 'Aplikasi perpesanan instan yang cepat, aman, dan ringan. Dilengkapi panggilan suara, video call HD, dan sinkronisasi status 24 jam.',
        en: 'A fast, secure, and lightweight instant messaging app. Featuring voice calls, HD video calls, and 24-hour status stories.',
        ar: 'تطبيق مراسلة فورية فائق السرعة، آمن وخفيف. مزود بمكالمات صوتية، مكالمات فيديو عالية الدقة وقصص على مدار 24 ساعة.',
        ja: '高速で安全、軽量なインスタントメッセージアプリ。クリアな音声通話、HDビデオ通話、24時間ストーリー共有を搭載。',
        zh: '极速、安全且轻量级的即时通讯应用。具备实时语音通话、高清视频通话以及24小时动态故事分享。',
        es: 'Una aplicación de mensajería instantánea rápida, segura y ligera. Con llamadas de voz, videollamadas HD e historias de 24 horas.',
      );

  String get checkUpdates => _t(
        id: 'Periksa Pembaruan',
        en: 'Check for Updates',
        ar: 'التحقق من التحديثات',
        ja: 'アップデートを確認',
        zh: '检查最新版本',
        es: 'Comprobar actualizaciones',
      );

  String get alreadyLatestVersion => _t(
        id: 'QuickChat Anda sudah dalam versi terbaru! (v1.2.0)',
        en: 'QuickChat is already on the latest version! (v1.2.0)',
        ar: 'تطبيق QuickChat في أحدث إصدار حالياً! (v1.2.0)',
        ja: 'QuickChatは最新バージョンです！ (v1.2.0)',
        zh: '您的 QuickChat 已是最新版本！(v1.2.0)',
        es: '¡QuickChat ya está en la última versión! (v1.2.0)',
      );

  String get copyright => '© 2026 QuickChat Team. All Rights Reserved.';

  // ── 10. Logout Confirmation ────────────────────────────────────────────────
  String get logoutConfirmTitle => _t(
        id: 'Keluar Akun?',
        en: 'Log Out?',
        ar: 'تسجيل الخروج؟',
        ja: 'ログアウトしますか？',
        zh: '退出当前账号？',
        es: '¿Cerrar sesión?',
      );

  String get logoutConfirmContent => _t(
        id: 'Apakah Anda yakin ingin keluar dari akun QuickChat ini?',
        en: 'Are you sure you want to log out of your QuickChat account?',
        ar: 'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك في QuickChat؟',
        ja: 'QuickChatアカウントからログアウトしてもよろしいですか？',
        zh: '您确定要退出此 QuickChat 账号吗？',
        es: '¿Estás seguro de que deseas salir de tu cuenta de QuickChat?',
      );

  String get logoutConfirmButton => _t(
        id: 'Keluar',
        en: 'Log Out',
        ar: 'خروج',
        ja: 'ログアウト',
        zh: '退出',
        es: 'Cerrar sesión',
      );
}
