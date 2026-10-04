import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/socket_provider.dart';
import '../../services/api_service.dart';
import '../../services/voice_record_service.dart';
import '../../theme/app_theme.dart';
import '../call/call_screen.dart';
import '../profile/friend_profile_screen.dart';
import 'components/full_screen_image_viewer.dart';
import 'components/message_options_sheet.dart';
import 'components/voice_message_bubble.dart';
import 'components/voice_record_button.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhone;
  final String? targetUserAvatar;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhone,
    this.targetUserAvatar,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isRecordingVoice = false;
  int _recordingSeconds = 0;

  // Reply state
  Map<String, dynamic>? _replyingTo;

  // In-chat search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<int> _matchedIndices = [];
  int _currentSearchMatchIndex = 0;

  bool get isGroupChat => widget.conversationId.startsWith('group_') || widget.targetUserId.startsWith('group_');

  String get effectiveConvId {
    if (isGroupChat) {
      return widget.conversationId;
    }
    if (widget.targetUserId.isNotEmpty && ApiService.currentUserId.isNotEmpty) {
      return ApiService.get1on1ConversationId(ApiService.currentUserId, widget.targetUserId);
    }
    return widget.conversationId;
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final myId = ApiService.currentUserId;
      final convId = effectiveConvId;

      // Register currently active chat room
      ref.read(activeConversationProvider.notifier).state = convId;

      // 1. Ensure socket is connected and identified
      if (ref.read(socketProvider) == null || !ref.read(socketProvider)!.connected) {
        ref.read(socketProvider.notifier).connect(myId);
      } else {
        ref.read(socketProvider)?.emit('identify', myId);
      }

      // 2. Load conversation history from backend DB
      final history = await ApiService.getConversationMessages(convId);
      if (mounted) {
        final parsedHistory = history.map((m) {
          final rawContent = m['content']?.toString() ?? '';
          if (rawContent.startsWith('{"text":')) {
            try {
              final decoded = jsonDecode(rawContent);
              return {
                ...m,
                'content': decoded['text'],
                'reply_to': decoded['reply_to'],
              };
            } catch (_) {}
          }
          return m;
        }).toList();
        ref.read(messagesProvider(convId).notifier).setMessages(parsedHistory);
      }

      // 3. Mark unread incoming messages as read
      final socket = ref.read(socketProvider);
      if (socket != null && history.isNotEmpty) {
        final unreadIds = history
            .where((m) => m['isMe'] != true && (m['status'] == null || (m['status'] as num) < 3))
            .map((m) => m['server_msg_id'])
            .where((id) => id != null)
            .toList();
        if (unreadIds.isNotEmpty) {
          socket.emit('mark_as_read', {
            'conversation_id': convId,
            'message_ids': unreadIds,
            'read_by_user_id': myId,
            'read_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });
  }

  void _onTextChanged(String text) {
    final hasText = text.trim().isNotEmpty;
    if (_isTyping != hasText) {
      setState(() {
        _isTyping = hasText;
      });
    }

    final socket = ref.read(socketProvider);
    if (socket == null) return;
    final convId = effectiveConvId;

    if (text.isNotEmpty) {
      socket.emit('typing_start', {
        'conversation_id': convId,
        'receiver_id': widget.targetUserId,
        'sender_id': ApiService.currentUserId,
      });

      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        socket.emit('typing_stop', {
          'conversation_id': convId,
          'receiver_id': widget.targetUserId,
          'sender_id': ApiService.currentUserId,
        });
      });
    } else {
      socket.emit('typing_stop', {
        'conversation_id': convId,
        'receiver_id': widget.targetUserId,
        'sender_id': ApiService.currentUserId,
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final replyPayload = _replyingTo != null
        ? {
            'message_id': _replyingTo!['server_msg_id'] ?? _replyingTo!['client_msg_id'],
            'content': _replyingTo!['content'] ?? (_replyingTo!['media_url'] != null ? '[Media]' : ''),
            'sender_name': _replyingTo!['isMe'] == true ? 'Anda' : widget.targetUserName,
          }
        : null;

    setState(() {
      _isTyping = false;
      _replyingTo = null;
    });

    final socket = ref.read(socketProvider);
    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final convId = effectiveConvId;
    final myId = ApiService.currentUserId;

    // 1. Add locally with Status 0 (Sending / Clock)
    ref.read(messagesProvider(convId).notifier).addMessage({
      'client_msg_id': clientId,
      'content': text,
      'reply_to': replyPayload,
      'isMe': true,
      'status': 0, // 0: Sending
      'timestamp': DateTime.now().toIso8601String(),
    });
    ref.read(contactSyncProvider.notifier).state++;

    _controller.clear();

    // 2. Emit over socket
    final payload = {
      'client_msg_id': clientId,
      'conversation_id': convId,
      'sender_id': myId,
      'receiver_id': widget.targetUserId,
      'content': text,
      'reply_to': replyPayload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (socket != null && socket.connected) {
      socket.emit('send_message', payload);
    } else {
      // Reconnect and send
      ref.read(socketProvider.notifier).connect(myId);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(socketProvider)?.emit('send_message', payload);
      });
    }
  }

  void _sendVoiceMessage(VoiceRecordResult result) {
    final url = result.uploadedUrl;
    if (url == null || url.isEmpty) return;

    final replyPayload = _replyingTo != null
        ? {
            'message_id': _replyingTo!['server_msg_id'] ?? _replyingTo!['client_msg_id'],
            'content': _replyingTo!['content'] ?? (_replyingTo!['media_url'] != null ? '[Media]' : ''),
            'sender_name': _replyingTo!['isMe'] == true ? 'Anda' : widget.targetUserName,
          }
        : null;

    setState(() {
      _replyingTo = null;
    });

    final socket = ref.read(socketProvider);
    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final convId = effectiveConvId;
    final myId = ApiService.currentUserId;

    ref.read(messagesProvider(convId).notifier).addMessage({
      'client_msg_id': clientId,
      'content': '[Pesan Suara]',
      'media_url': url,
      'reply_to': replyPayload,
      'isMe': true,
      'status': 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
    ref.read(contactSyncProvider.notifier).state++;

    final payload = {
      'client_msg_id': clientId,
      'conversation_id': convId,
      'sender_id': myId,
      'receiver_id': widget.targetUserId,
      'content': '[Pesan Suara]',
      'media_url': url,
      'reply_to': replyPayload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (socket != null && socket.connected) {
      socket.emit('send_message', payload);
    } else {
      ref.read(socketProvider.notifier).connect(myId);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(socketProvider)?.emit('send_message', payload);
      });
    }
  }

  void _sendImageMessage(String imageUrl) {
    final replyPayload = _replyingTo != null
        ? {
            'message_id': _replyingTo!['server_msg_id'] ?? _replyingTo!['client_msg_id'],
            'content': _replyingTo!['content'] ?? (_replyingTo!['media_url'] != null ? '[Media]' : ''),
            'sender_name': _replyingTo!['isMe'] == true ? 'Anda' : widget.targetUserName,
          }
        : null;

    setState(() {
      _replyingTo = null;
    });

    final socket = ref.read(socketProvider);
    final clientId = 'client_${DateTime.now().millisecondsSinceEpoch}';
    final convId = effectiveConvId;
    final myId = ApiService.currentUserId;

    ref.read(messagesProvider(convId).notifier).addMessage({
      'client_msg_id': clientId,
      'content': '[Foto]',
      'media_url': imageUrl,
      'reply_to': replyPayload,
      'isMe': true,
      'status': 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
    ref.read(contactSyncProvider.notifier).state++;

    final payload = {
      'client_msg_id': clientId,
      'conversation_id': convId,
      'sender_id': myId,
      'receiver_id': widget.targetUserId,
      'content': '[Foto]',
      'media_url': imageUrl,
      'reply_to': replyPayload,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (socket != null && socket.connected) {
      socket.emit('send_message', payload);
    } else {
      ref.read(socketProvider.notifier).connect(myId);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(socketProvider)?.emit('send_message', payload);
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final filename = 'chat_${DateTime.now().millisecondsSinceEpoch}.${picked.name.split('.').last}';
        final uploadedUrl = await ApiService.uploadMedia(bytes: bytes, filename: filename);
        if (uploadedUrl != null) {
          _sendImageMessage(uploadedUrl);
        }
      }
    } catch (e) {
      debugPrint('[Chat] Error picking image: $e');
    }
  }

  // ── Search in Chat Methods ──────────────────────────────────────────
  void _onSearchChanged(String query, List<Map<String, dynamic>> messages) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
      _matchedIndices.clear();
      _currentSearchMatchIndex = 0;

      if (_searchQuery.isNotEmpty) {
        for (int i = 0; i < messages.length; i++) {
          final content = (messages[i]['content'] ?? '').toString().toLowerCase();
          if (content.contains(_searchQuery) && !content.contains('telah dihapus')) {
            _matchedIndices.add(i);
          }
        }
      }
    });

    if (_matchedIndices.isNotEmpty) {
      _scrollToMatchedIndex(0);
    }
  }

  void _scrollToMatchedIndex(int matchIndex) {
    if (_matchedIndices.isEmpty) return;
    final messageIndex = _matchedIndices[matchIndex];
    final messages = ref.read(messagesProvider(effectiveConvId));
    final reverseIndex = (messages.length - 1 - messageIndex).clamp(0, messages.length - 1);
    if (_scrollController.hasClients) {
      final targetOffset = (reverseIndex * 68.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _jumpToNextMatch() {
    if (_matchedIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex + 1) % _matchedIndices.length;
    });
    _scrollToMatchedIndex(_currentSearchMatchIndex);
  }

  void _jumpToPrevMatch() {
    if (_matchedIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex = (_currentSearchMatchIndex - 1 + _matchedIndices.length) % _matchedIndices.length;
    });
    _scrollToMatchedIndex(_currentSearchMatchIndex);
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
      _matchedIndices.clear();
      _currentSearchMatchIndex = 0;
    });
  }

  // ── Long-Press Options & Reply ──────────────────────────────────────
  void _showMessageOptionsMenu(BuildContext context, Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true;
    final msgId = (msg['server_msg_id'] ?? msg['client_msg_id'] ?? '').toString();
    final convId = effectiveConvId;
    final socket = ref.read(socketProvider);

    MessageOptionsSheet.show(
      context,
      message: msg,
      isMe: isMe,
      onReply: () {
        setState(() {
          _replyingTo = msg;
        });
        _inputFocusNode.requestFocus();
      },
      onCopy: () {
        final text = msg['content']?.toString() ?? '';
        if (text.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesan disalin ke papan klip'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onDeleteForMe: () {
        ref.read(messagesProvider(convId).notifier).deleteForMe(msgId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesan dihapus untuk Anda'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onDeleteForEveryone: isMe
          ? () {
              socket?.emit('delete_message', {
                'message_id': msgId,
                'conversation_id': convId,
                'receiver_id': widget.targetUserId,
                'delete_type': 'for_everyone',
              });
              ref.read(messagesProvider(convId).notifier).markDeleted(msgId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesan ditarik untuk semua orang'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
    );
  }

  Widget _buildReplyQuoteCard(Map<String, dynamic> replyTo, bool isMe) {
    final sender = replyTo['sender_name']?.toString() ?? 'Pesan';
    final quoteContent = replyTo['content']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.18) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white : AppTheme.primaryTeal,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            quoteContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreviewBanner() {
    if (_replyingTo == null) return const SizedBox.shrink();

    final isMe = _replyingTo!['isMe'] == true;
    final sender = isMe ? 'Anda' : widget.targetUserName;
    final quoteContent = _replyingTo!['content']?.toString() ??
        (_replyingTo!['media_url'] != null ? '[Media]' : '');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          left: BorderSide(color: AppTheme.primaryTeal, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: AppTheme.primaryTeal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Membalas ke $sender',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quoteContent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '10:30';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '10:30';
    }
  }

  String _formatTimerSeconds(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildMessageStatus(int status) {
    switch (status) {
      case 0: // Sending (Clock icon)
        return const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70);
      case 1: // Sent (Single grey check)
        return const Icon(Icons.check, size: 14, color: Colors.white70);
      case 2: // Delivered (Double grey check)
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case 3: // Read (Double blue check)
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF38BDF8));
      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _inputFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    if (ref.read(activeConversationProvider) == effectiveConvId) {
      ref.read(activeConversationProvider.notifier).state = null;
    }
    super.dispose();
  }

  void _openAddMemberToGroupModal(BuildContext context) async {
    final contacts = await ApiService.getContacts();
    final Set<String> selected = {};
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setModal) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.person_add_rounded, color: AppTheme.primaryTeal),
                      SizedBox(width: 8),
                      Text('Tambah Anggota ke Grup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              if (contacts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Belum ada kontak untuk ditambahkan', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final item = contacts[idx];
                      final uid = item['id'] as String? ?? '';
                      final name = item['name'] ?? 'Teman';
                      final phone = item['phoneNumber'] ?? '';
                      final avatar = item['avatarUrl'] ?? '';
                      final isSel = selected.contains(uid);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.mintLight,
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                  style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(phone),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.primaryTeal : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? AppTheme.primaryTeal : Colors.grey),
                          ),
                          child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                        onTap: () {
                          setModal(() {
                            if (isSel) selected.remove(uid);
                            else selected.add(uid);
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: selected.isEmpty
                    ? null
                    : () async {
                        final ok = await ApiService.addParticipantsToGroup(
                          groupId: effectiveConvId,
                          userIds: selected.toList(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '${selected.length} anggota baru berhasil ditambahkan!'
                                  : 'Gagal menambahkan anggota'),
                            ),
                          );
                        }
                      },
                child: Text('Tambahkan (${selected.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final convId = effectiveConvId;
    final messages = ref.watch(messagesProvider(convId));
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isOnline = onlineUsers.contains(widget.targetUserId);
    final isTyping = ref.watch(typingStatusProvider(convId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 1,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Tutup Pencarian',
                onPressed: _closeSearch,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
        titleSpacing: _isSearching ? 0 : 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Cari pesan di sini...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (q) => _onSearchChanged(q, messages),
              )
            : InkWell(
                onTap: () {
                  if (!isGroupChat) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FriendProfileScreen(
                          userId: widget.targetUserId,
                          userName: widget.targetUserName,
                          userPhone: widget.targetUserPhone,
                          userAvatar: widget.targetUserAvatar,
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.mintLight,
                        image: widget.targetUserAvatar != null && widget.targetUserAvatar!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(ApiService.normalizeUrl(widget.targetUserAvatar!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.targetUserAvatar == null || widget.targetUserAvatar!.isEmpty
                          ? Center(
                              child: Icon(
                                isGroupChat ? Icons.groups_rounded : Icons.person,
                                color: AppTheme.primaryTeal,
                                size: 22,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),

                    // Name & Online/Typing Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.targetUserName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTyping
                                ? 'Sedang mengetik...'
                                : isGroupChat
                                    ? 'Grup Chat'
                                    : isOnline
                                        ? 'Online'
                                        : 'Terakhir dilihat baru saja',
                            style: TextStyle(
                              fontSize: 12,
                              color: isTyping ? const Color(0xFF67E8F9) : Colors.white70,
                              fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: _isSearching
            ? [
                if (_searchQuery.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _matchedIndices.isEmpty
                              ? '0 hasil'
                              : '${_currentSearchMatchIndex + 1}/${_matchedIndices.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                  tooltip: 'Sebelumnya',
                  onPressed: _matchedIndices.isNotEmpty ? _jumpToPrevMatch : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                  tooltip: 'Berikutnya',
                  onPressed: _matchedIndices.isNotEmpty ? _jumpToNextMatch : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: 'Tutup',
                  onPressed: _closeSearch,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  tooltip: 'Cari Pesan',
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
                if (isGroupChat) ...[
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                    tooltip: 'Tambah Anggota ke Grup',
                    onPressed: () => _openAddMemberToGroupModal(context),
                  ),
                ] else ...[
                  // Video Call Action Button
                  IconButton(
                    icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                    tooltip: 'Panggilan Video (Video Call)',
                    onPressed: () {
                      CallDialog.startVideoCall(
                        context,
                        ref,
                        targetUserId: widget.targetUserId,
                        targetUserName: widget.targetUserName,
                        targetUserAvatar: widget.targetUserAvatar ?? '',
                      );
                    },
                  ),
                  // Voice Call Action Button
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, color: Colors.white),
                    tooltip: 'Panggilan Suara (Telepon)',
                    onPressed: () {
                      CallDialog.startCall(
                        context,
                        ref,
                        targetUserId: widget.targetUserId,
                        targetUserName: widget.targetUserName,
                        targetUserAvatar: widget.targetUserAvatar ?? '',
                      );
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Latest at bottom
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final originalIndex = messages.length - 1 - index;
                final msg = messages[originalIndex];
                final isMe = msg['isMe'] == true;
                final status = msg['status'] is int ? msg['status'] as int : 1;
                final mediaUrl = msg['media_url'] as String?;
                final content = msg['content']?.toString() ?? '';
                final isDeleted = msg['is_deleted'] == true ||
                    content == '🚫 Pesan ini telah dihapus' ||
                    content.contains('🚫 Pesan ini telah dihapus');
                final replyTo = msg['reply_to'] is Map<String, dynamic>
                    ? msg['reply_to'] as Map<String, dynamic>
                    : null;

                final isVoice = !isDeleted && ((mediaUrl != null && (
                  mediaUrl.contains('.webm') ||
                  mediaUrl.contains('.m4a') ||
                  mediaUrl.contains('.mp3') ||
                  mediaUrl.contains('.wav') ||
                  mediaUrl.contains('.aac') ||
                  mediaUrl.contains('.ogg') ||
                  mediaUrl.contains('audio_') ||
                  mediaUrl.contains('voice_')
                )) || content == '[Pesan Suara]');

                final isImage = !isDeleted && !isVoice && mediaUrl != null && (
                  mediaUrl.contains('.png') ||
                  mediaUrl.contains('.jpg') ||
                  mediaUrl.contains('.jpeg') ||
                  mediaUrl.contains('.webp') ||
                  mediaUrl.contains('img_') ||
                  content == '[Foto]'
                );

                final isSearchMatch = _isSearching &&
                    _searchQuery.isNotEmpty &&
                    content.toLowerCase().contains(_searchQuery);
                final isCurrentMatch = _matchedIndices.isNotEmpty &&
                    _matchedIndices[_currentSearchMatchIndex] == originalIndex;

                Widget buildBubbleWithAvatar(Widget bubbleWidget) {
                  if (isMe) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: bubbleWidget,
                    );
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Foto Teman: Klik langsung menuju profil teman
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!isGroupChat) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FriendProfileScreen(
                                    userId: widget.targetUserId,
                                    userName: widget.targetUserName,
                                    userPhone: widget.targetUserPhone,
                                    userAvatar: widget.targetUserAvatar,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10, right: 6),
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: AppTheme.mintLight,
                              backgroundImage: widget.targetUserAvatar != null && widget.targetUserAvatar!.isNotEmpty
                                  ? NetworkImage(ApiService.normalizeUrl(widget.targetUserAvatar!))
                                  : null,
                              child: widget.targetUserAvatar == null || widget.targetUserAvatar!.isEmpty
                                  ? Text(
                                      widget.targetUserName.isNotEmpty ? widget.targetUserName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Flexible(child: bubbleWidget),
                      ],
                    ),
                  );
                }

                // ── Deleted Message Bubble ─────────────────────────
                if (isDeleted) {
                  return buildBubbleWithAvatar(
                    GestureDetector(
                      onLongPress: () => _showMessageOptionsMenu(context, msg),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.block_rounded, size: 15, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 6),
                            const Text(
                              'Pesan ini telah dihapus',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(msg['timestamp']),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ── Voice Message Bubble ───────────────────────────
                if (isVoice && mediaUrl != null && mediaUrl.isNotEmpty) {
                  return buildBubbleWithAvatar(
                    GestureDetector(
                      onLongPress: () => _showMessageOptionsMenu(context, msg),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryTeal : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isCurrentMatch
                              ? Border.all(color: const Color(0xFFF59E0B), width: 2.5)
                              : (isSearchMatch
                                  ? Border.all(color: const Color(0xFFFDE68A), width: 2)
                                  : null),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (replyTo != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                child: _buildReplyQuoteCard(replyTo, isMe),
                              ),
                            VoiceMessageBubble(
                              audioUrl: mediaUrl,
                              isMe: isMe,
                              status: status,
                              timestamp: msg['timestamp']?.toString() ?? '',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ── Photo / Image Message Bubble ───────────────────
                if (isImage && mediaUrl!.isNotEmpty) {
                  return buildBubbleWithAvatar(
                    GestureDetector(
                      onLongPress: () => _showMessageOptionsMenu(context, msg),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72,
                        ),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryTeal : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          border: isCurrentMatch
                              ? Border.all(color: const Color(0xFFF59E0B), width: 2.5)
                              : (isSearchMatch
                                  ? Border.all(color: const Color(0xFFFDE68A), width: 2)
                                  : null),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (replyTo != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _buildReplyQuoteCard(replyTo, isMe),
                              ),
                            // Photo Container with Tap to Preview Full-Screen
                            GestureDetector(
                              onTap: () {
                                FullScreenImageViewer.show(
                                  context,
                                  imageUrl: ApiService.normalizeUrl(mediaUrl),
                                  senderName: isMe ? 'Anda' : widget.targetUserName,
                                  timestamp: _formatTimestamp(msg['timestamp']),
                                  userId: isMe ? null : widget.targetUserId,
                                  userPhone: widget.targetUserPhone,
                                  userAvatar: widget.targetUserAvatar,
                                );
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Hero(
                                      tag: 'chat_img_${msg['server_msg_id'] ?? msg['client_msg_id'] ?? mediaUrl}',
                                      child: Image.network(
                                        ApiService.normalizeUrl(mediaUrl),
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Container(
                                            height: 180,
                                            color: Colors.black12,
                                            child: const Center(
                                              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  // Visual zoom hint
                                  Positioned(
                                    right: 6,
                                    bottom: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 6, bottom: 2, left: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTimestamp(msg['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildMessageStatus(status),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ── Normal Text Message Bubble ─────────────────────
                return buildBubbleWithAvatar(
                  GestureDetector(
                    onLongPress: () => _showMessageOptionsMenu(context, msg),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? AppTheme.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        border: isCurrentMatch
                            ? Border.all(color: const Color(0xFFF59E0B), width: 2.5)
                            : (isSearchMatch
                                ? Border.all(color: const Color(0xFFFDE68A), width: 2)
                                : null),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (replyTo != null) _buildReplyQuoteCard(replyTo, isMe),
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isMe ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTimestamp(msg['timestamp']),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMe ? Colors.white70 : AppTheme.textSecondary,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                _buildMessageStatus(status),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Quoted Message Preview Banner ─────────────────────────
          _buildReplyPreviewBanner(),

          // ── Message Input Field / Voice Recording Dock ───────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: _isRecordingVoice
                  // ── Active Voice Recording Panel ─────────────────
                  ? Row(
                      children: [
                        // Red blinking recording indicator
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.3, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        // Stopwatch duration
                        Text(
                          _formatTimerSeconds(_recordingSeconds),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Slide to cancel hint
                        const Expanded(
                          child: Text(
                            '◀ Geser kiri untuk batal',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Hold-to-record button active in place
                        VoiceRecordButton(
                          onRecordingStarted: () {
                            setState(() {
                              _isRecordingVoice = true;
                              _recordingSeconds = 0;
                            });
                          },
                          onDurationChanged: (sec) {
                            setState(() {
                              _recordingSeconds = sec;
                            });
                          },
                          onRecordingCancelled: () {
                            setState(() {
                              _isRecordingVoice = false;
                              _recordingSeconds = 0;
                            });
                          },
                          onRecordingCompleted: (result) {
                            setState(() {
                              _isRecordingVoice = false;
                              _recordingSeconds = 0;
                            });
                            _sendVoiceMessage(result);
                          },
                        ),
                      ],
                    )
                  // ── Normal Input Bar (Text / Attach / Mic) ──────
                  : Row(
                      children: [
                        // Photo Attachment Button
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.mintLight,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryTeal),
                            tooltip: 'Kirim Gambar',
                            onPressed: _pickAndSendImage,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Text Field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _inputFocusNode,
                              onChanged: _onTextChanged,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle: TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dynamic Action Button: Send if typing, else Voice Record Button
                        if (_isTyping)
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          )
                        else
                          VoiceRecordButton(
                            onRecordingStarted: () {
                              setState(() {
                                _isRecordingVoice = true;
                                _recordingSeconds = 0;
                              });
                            },
                            onDurationChanged: (sec) {
                              setState(() {
                                _recordingSeconds = sec;
                              });
                            },
                            onRecordingCancelled: () {
                              setState(() {
                                _isRecordingVoice = false;
                                _recordingSeconds = 0;
                              });
                            },
                            onRecordingCompleted: (result) {
                              setState(() {
                                _isRecordingVoice = false;
                                _recordingSeconds = 0;
                              });
                              _sendVoiceMessage(result);
                            },
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
