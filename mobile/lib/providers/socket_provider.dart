import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api_service.dart';
import '../services/webrtc_service.dart';

// Online Users Set
final onlineUsersProvider = StateProvider<Set<String>>((ref) => {});

// Global Sync Provider for Contacts & Friend Requests
final contactSyncProvider = StateProvider<int>((ref) => 0);

// Typing State by conversationId: Map<conversationId, isTyping>
final typingStatusProvider = StateProvider.family<bool, String>((ref, conversationId) => false);

// Active Chat Room Conversation ID (null if not viewing any chat)
final activeConversationProvider = StateProvider<String?>((ref) => null);

// Active Call State Provider
class CallState {
  final bool isCalling;
  final bool isIncoming;
  final String targetUserId;
  final String targetUserName;
  final String targetUserAvatar;
  final String mediaType; // 'audio' | 'video'
  final String status; // 'dialing', 'ringing', 'connected', 'ended'
  final int durationSeconds;
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;

  const CallState({
    this.isCalling = false,
    this.isIncoming = false,
    this.targetUserId = '',
    this.targetUserName = '',
    this.targetUserAvatar = '',
    this.mediaType = 'audio',
    this.status = 'dialing',
    this.durationSeconds = 0,
    this.offer,
    this.answer,
  });

  CallState copyWith({
    bool? isCalling,
    bool? isIncoming,
    String? targetUserId,
    String? targetUserName,
    String? targetUserAvatar,
    String? mediaType,
    String? status,
    int? durationSeconds,
    Map<String, dynamic>? offer,
    Map<String, dynamic>? answer,
  }) {
    return CallState(
      isCalling: isCalling ?? this.isCalling,
      isIncoming: isIncoming ?? this.isIncoming,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      targetUserAvatar: targetUserAvatar ?? this.targetUserAvatar,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      offer: offer ?? this.offer,
      answer: answer ?? this.answer,
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  CallNotifier() : super(const CallState());

  void startOutgoingCall({
    required String targetUserId,
    required String targetUserName,
    required String targetUserAvatar,
    String mediaType = 'audio',
    Map<String, dynamic>? offer,
  }) {
    state = CallState(
      isCalling: true,
      isIncoming: false,
      targetUserId: targetUserId,
      targetUserName: targetUserName,
      targetUserAvatar: targetUserAvatar,
      mediaType: mediaType,
      status: 'dialing',
      durationSeconds: 0,
      offer: offer,
    );
  }

  void receiveIncomingCall({
    required String callerId,
    required String callerName,
    required String callerAvatar,
    String mediaType = 'audio',
    Map<String, dynamic>? offer,
  }) {
    state = CallState(
      isCalling: true,
      isIncoming: true,
      targetUserId: callerId,
      targetUserName: callerName,
      targetUserAvatar: callerAvatar,
      mediaType: mediaType,
      status: 'ringing',
      durationSeconds: 0,
      offer: offer,
    );
  }

  void setMediaType(String type) {
    state = state.copyWith(mediaType: type);
  }

  void connectCall({Map<String, dynamic>? answer}) {
    state = state.copyWith(status: 'connected', answer: answer);
  }

  void updateDuration(int seconds) {
    state = state.copyWith(durationSeconds: seconds);
  }

  void endCall() {
    state = const CallState();
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier();
});

class SocketNotifier extends StateNotifier<io.Socket?> {
  final Ref ref;
  SocketNotifier(this.ref) : super(null);

  void connect(String userId) {
    if (state != null && state!.connected) {
      print('[Socket] Already connected, identifying as: $userId');
      state!.emit('identify', userId);
      return;
    }

    final socket = io.io(ApiService.serverUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    state = socket;

    socket.connect();

    socket.onConnect((_) {
      print('[Socket] Connected to QuickChat Gateway as: $userId');
      socket.emit('identify', userId);
      socket.emit('request_online_users');
    });

    socket.on('online_users', (data) {
      if (data is List) {
        ref.read(onlineUsersProvider.notifier).state = Set<String>.from(data.map((e) => e.toString()));
      }
    });

    socket.on('user_status_changed', (data) {
      if (data is Map && data['userId'] != null) {
        final uId = data['userId'].toString();
        final isOnline = data['isOnline'] == true;
        final current = ref.read(onlineUsersProvider);
        if (isOnline) {
          ref.read(onlineUsersProvider.notifier).state = {...current, uId};
        } else {
          ref.read(onlineUsersProvider.notifier).state = current.where((id) => id != uId).toSet();
        }
      }
    });

    // ── Real-time Messages & Lifecycle ─────────────────────────
    socket.on('message_sent', (data) {
      // { client_msg_id, server_msg_id, conversation_id, status: 1, timestamp }
      print('[Socket] message_sent received: $data');
      if (data is Map) {
        final cId = data['client_msg_id']?.toString() ?? '';
        final sId = data['server_msg_id']?.toString() ?? '';
        final convId = data['conversation_id']?.toString() ?? '';
        if (convId.isNotEmpty) {
          ref.read(messagesProvider(convId).notifier).updateStatus(cId, sId, 1);
        }
        ref.read(contactSyncProvider.notifier).state++;
      }
    });

    socket.on('message_delivered', (data) {
      // { server_msg_id, conversation_id, status: 2 }
      print('[Socket] message_delivered received: $data');
      if (data is Map) {
        final sId = data['server_msg_id']?.toString() ?? '';
        final convId = data['conversation_id']?.toString() ?? '';
        if (convId.isNotEmpty) {
          ref.read(messagesProvider(convId).notifier).updateStatus('', sId, 2);
        }
      }
    });

    socket.on('message_read_update', (data) {
      // { conversation_id, message_ids, status: 3 }
      print('[Socket] message_read_update received: $data');
      if (data is Map) {
        final convId = data['conversation_id']?.toString() ?? '';
        if (convId.isNotEmpty && data['message_ids'] is List) {
          for (final mId in data['message_ids']) {
            ref.read(messagesProvider(convId).notifier).updateStatus('', mId.toString(), 3);
          }
          ref.read(contactSyncProvider.notifier).state++;
        }
      }
    });

    socket.on('receive_message', (data) {
      print('[Socket] receive_message received: $data');
      if (data is Map) {
        final convId = data['conversation_id']?.toString() ?? 'default';
        ref.read(messagesProvider(convId).notifier).addMessage({
          'server_msg_id': data['server_msg_id'],
          'content': data['content'],
          'media_url': data['media_url'],
          'reply_to': data['reply_to'],
          'isMe': false,
          'status': 2,
          'timestamp': data['timestamp'],
        });

        ref.read(contactSyncProvider.notifier).state++;

        // Only mark as read if the user is CURRENTLY looking at this specific conversation!
        final activeConvId = ref.read(activeConversationProvider);
        if (activeConvId != null && activeConvId == convId) {
          final myId = ApiService.currentUserId;
          socket.emit('mark_as_read', {
            'conversation_id': convId,
            'message_ids': [data['server_msg_id']],
            'read_by_user_id': myId,
            'read_at': DateTime.now().toIso8601String(),
          });
        }
      }
    });

    socket.on('message_deleted', (data) {
      print('[Socket] message_deleted received: $data');
      if (data is Map) {
        final convId = data['conversation_id']?.toString() ?? '';
        final msgId = data['message_id']?.toString() ?? '';
        if (convId.isNotEmpty && msgId.isNotEmpty) {
          ref.read(messagesProvider(convId).notifier).markDeleted(msgId);
          ref.read(contactSyncProvider.notifier).state++;
        }
      }
    });

    // ── Typing Indicator ───────────────────────────────────────
    socket.on('user_typing_start', (data) {
      if (data is Map && data['conversation_id'] != null) {
        final convId = data['conversation_id'].toString();
        ref.read(typingStatusProvider(convId).notifier).state = true;
      }
    });

    socket.on('user_typing_stop', (data) {
      if (data is Map && data['conversation_id'] != null) {
        final convId = data['conversation_id'].toString();
        ref.read(typingStatusProvider(convId).notifier).state = false;
      }
    });

    // ── Voice & Video Call Signaling ──────────────────────────
    socket.on('incoming_call', (data) {
      print('[Socket] incoming_call received: $data');
      if (data is Map) {
        ref.read(callProvider.notifier).receiveIncomingCall(
          callerId: data['callerId'] ?? 'Unknown',
          callerName: data['callerName'] ?? 'Teman',
          callerAvatar: data['callerAvatar'] ?? '',
          mediaType: data['mediaType'] ?? 'audio',
          offer: data['offer'] != null ? Map<String, dynamic>.from(data['offer']) : null,
        );
      }
    });

    socket.on('call_accepted', (data) {
      print('[Socket] call_accepted received: $data');
      final answer = data is Map && data['answer'] != null ? Map<String, dynamic>.from(data['answer']) : null;
      if (answer != null) {
        WebRtcService().setRemoteAnswer(answer);
      }
      ref.read(callProvider.notifier).connectCall(answer: answer);
    });

    socket.on('ice_candidate', (data) {
      print('[Socket] ice_candidate received');
      if (data is Map && data['candidate'] != null) {
        WebRtcService().addIceCandidate(Map<String, dynamic>.from(data['candidate']));
      }
    });

    socket.on('call_rejected', (_) {
      print('[Socket] call_rejected received');
      WebRtcService().cleanUp();
      ref.read(callProvider.notifier).endCall();
    });

    socket.on('call_ended', (_) {
      print('[Socket] call_ended received');
      WebRtcService().cleanUp();
      ref.read(callProvider.notifier).endCall();
    });

    // ── Friend Request & Contact Real-time Events ──────────────
    socket.on('friend_request_received', (_) {
      ref.read(contactSyncProvider.notifier).state++;
    });

    socket.on('friend_request_accepted', (_) {
      ref.read(contactSyncProvider.notifier).state++;
    });

    socket.on('friend_request_rejected', (_) {
      ref.read(contactSyncProvider.notifier).state++;
    });

    state = socket;
  }

  void sendTypingStart(String conversationId, String receiverId) {
    state?.emit('typing_start', {
      'conversation_id': conversationId,
      'receiver_id': receiverId,
    });
  }

  void sendTypingStop(String conversationId, String receiverId) {
    state?.emit('typing_stop', {
      'conversation_id': conversationId,
      'receiver_id': receiverId,
    });
  }

  void disconnect() {
    state?.disconnect();
    state = null;
  }
}

final socketProvider = StateNotifierProvider<SocketNotifier, io.Socket?>((ref) {
  return SocketNotifier(ref);
});

// A global message store updater
class AllMessagesNotifier extends StateNotifier<int> {
  final Ref ref;
  AllMessagesNotifier(this.ref) : super(0);

  void updateStatus(String clientId, String serverId, int status) {
    // Notify all active conversation notifiers
    state++;
  }
}

final allMessagesNotifierProvider = StateNotifierProvider<AllMessagesNotifier, int>((ref) {
  return AllMessagesNotifier(ref);
});

// Message store by conversationId
class MessagesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final Ref ref;
  final String conversationId;

  MessagesNotifier(this.ref, this.conversationId) : super([]);

  void setMessages(List<Map<String, dynamic>> messages) {
    state = messages;
  }

  void addMessage(Map<String, dynamic> message) {
    final exists = state.any((m) =>
      (message['server_msg_id'] != null && message['server_msg_id'] != '' && m['server_msg_id'] == message['server_msg_id']) ||
      (message['client_msg_id'] != null && message['client_msg_id'] != '' && m['client_msg_id'] == message['client_msg_id'])
    );
    if (!exists) {
      state = [...state, message];
    }
  }

  void updateStatus(String clientMsgId, String serverMsgId, int newStatus) {
    state = [
      for (final msg in state)
        if ((clientMsgId.isNotEmpty && msg['client_msg_id'] == clientMsgId) ||
            (serverMsgId.isNotEmpty && msg['server_msg_id'] == serverMsgId))
          {...msg, 'status': newStatus, if (serverMsgId.isNotEmpty) 'server_msg_id': serverMsgId}
        else
          msg
    ];
  }

  void markDeleted(String msgId) {
    state = [
      for (final msg in state)
        if (msg['server_msg_id'] == msgId || msg['client_msg_id'] == msgId)
          {...msg, 'content': '🚫 Pesan ini telah dihapus', 'media_url': null, 'is_deleted': true}
        else
          msg
    ];
  }

  void deleteForMe(String msgId) {
    state = state.where((msg) =>
      msg['server_msg_id'] != msgId && msg['client_msg_id'] != msgId
    ).toList();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Map<String, dynamic>>, String>((ref, conversationId) {
  return MessagesNotifier(ref, conversationId);
});
