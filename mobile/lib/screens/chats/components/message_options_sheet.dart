import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

class MessageOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  const MessageOptionsSheet({
    super.key,
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onCopy,
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> message,
    required bool isMe,
    required VoidCallback onReply,
    required VoidCallback onCopy,
    required VoidCallback onDeleteForMe,
    VoidCallback? onDeleteForEveryone,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MessageOptionsSheet(
        message: message,
        isMe: isMe,
        onReply: onReply,
        onCopy: onCopy,
        onDeleteForMe: onDeleteForMe,
        onDeleteForEveryone: onDeleteForEveryone,
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Hapus pesan?'),
          ],
        ),
        content: Text(
          isMe
              ? 'Anda dapat menarik pesan ini untuk semua orang dalam obrolan atau hanya menghapus untuk diri Anda sendiri.'
              : 'Pesan ini akan dihapus dari obrolan Anda.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          if (isMe && onDeleteForEveryone != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                onDeleteForEveryone?.call();
              },
              child: const Text(
                'Tarik untuk Semua Orang',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onDeleteForMe();
            },
            child: Text(
              isMe ? 'Hapus untuk Saya' : 'Hapus',
              style: TextStyle(
                color: isMe ? const Color(0xFF475569) : const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = message['content'] != null &&
        message['content'].toString().isNotEmpty &&
        message['content'] != '[Pesan Suara]' &&
        message['content'] != '[Foto]' &&
        message['content'] != '🚫 Pesan ini telah dihapus';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Emoji Reaction Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bereaksi dengan $emoji'),
                            duration: const Duration(milliseconds: 1000),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 1. Reply Action
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.mintLight,
                child: Icon(Icons.reply_rounded, color: AppTheme.primaryTeal),
              ),
              title: const Text(
                'Balas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Kutip pesan ini dalam balasan Anda',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onReply();
              },
            ),

            // 2. Copy Text Action
            if (hasText)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(Icons.copy_rounded, color: Color(0xFF475569)),
                ),
                title: const Text(
                  'Salin Teks',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onCopy();
                },
              ),

            // 3. Delete Message Action
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFEE2E2),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              ),
              title: const Text(
                'Hapus Pesan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFFEF4444),
                ),
              ),
              subtitle: Text(
                isMe ? 'Hapus untuk saya atau semua orang' : 'Hapus untuk saya',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              onTap: () => _showDeleteConfirmDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}
