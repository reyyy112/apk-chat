import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get serverUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && !origin.startsWith('file:') && !origin.startsWith('about:')) {
        return origin;
      }
    }
    return 'https://tumor-oliver-interest-flickr.trycloudflare.com';
  }

  static String get baseUrl => '$serverUrl/api/v1';

  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('localhost:3000') || url.contains('127.0.0.1:3000')) {
      return url.replaceAll(RegExp(r'https?:\/\/(localhost|127\.0\.0\.1):3000'), serverUrl);
    }
    if (url.startsWith('/uploads/')) {
      return '$serverUrl$url';
    }
    return url;
  }

  static String currentUserId = 'user_rq';
  static String currentUserName = 'rq';
  static String currentUserPhone = '+6281234567890';
  static String currentUserAvatar = '';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-user-id': currentUserId,
  };

  static String get1on1ConversationId(String u1, String u2) {
    final ids = [u1, u2]..sort();
    return 'conv_${ids[0]}_${ids[1]}';
  }

  static Future<List<Map<String, dynamic>>> getConversationMessages(String conversationId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts/messages/$conversationId'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      }
    } catch (e) {
      print('Error getConversationMessages: $e');
    }
    return [];
  }

  // Auth: Login / Register with custom phone
  static Future<Map<String, dynamic>?> loginOrRegister({
    required String phoneNumber,
    String? name,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'name': name,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'];
        if (user != null) {
          currentUserId = user['id'];
          currentUserName = user['name'] ?? 'User';
          currentUserPhone = user['phoneNumber'] ?? phoneNumber;
          currentUserAvatar = user['avatarUrl'] ?? '';
        }
        return data;
      }
    } catch (e) {
      print('Error loginOrRegister: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> registerUser({
    required String phoneNumber,
    required String name,
    String? aboutStatus,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'name': name,
          'aboutStatus': aboutStatus,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'];
        if (user != null) {
          currentUserId = user['id'];
          currentUserName = user['name'] ?? name;
          currentUserPhone = user['phoneNumber'] ?? phoneNumber;
          currentUserAvatar = user['avatarUrl'] ?? '';
        }
        return data;
      }
    } catch (e) {
      print('Error registerUser: $e');
    }
    return null;
  }

  // Contacts & Friends
  static Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['contacts'] ?? []);
      }
    } catch (e) {
      print('Error getContacts: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchContactByPhone(String phone) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/contacts/search?phone=${Uri.encodeComponent(phone)}'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      }
    } catch (e) {
      print('Error searchContactByPhone: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts/all-users'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      }
    } catch (e) {
      print('Error getAllUsers: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addContact({String? targetPhoneNumber, String? targetUserId}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/contacts/add'),
        headers: _headers,
        body: jsonEncode({
          'targetPhoneNumber': targetPhoneNumber,
          'targetUserId': targetUserId,
        }),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Error addContact: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts/requests'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'incoming': List<Map<String, dynamic>>.from(data['incoming'] ?? []),
          'outgoing': List<Map<String, dynamic>>.from(data['outgoing'] ?? []),
        };
      }
    } catch (e) {
      print('Error getFriendRequests: $e');
    }
    return {'incoming': [], 'outgoing': []};
  }

  static Future<bool> acceptFriendRequest(String targetUserId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/contacts/accept'),
        headers: _headers,
        body: jsonEncode({'targetUserId': targetUserId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error acceptFriendRequest: $e');
    }
    return false;
  }

  static Future<bool> rejectFriendRequest(String targetUserId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/contacts/reject'),
        headers: _headers,
        body: jsonEncode({'targetUserId': targetUserId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error rejectFriendRequest: $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/contacts/profile/$userId'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['profile'];
      }
    } catch (e) {
      print('Error getUserProfile: $e');
    }
    return null;
  }

  // Stories
  static Future<List<Map<String, dynamic>>> getStories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stories'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      print('Error getStories: $e');
    }
    return [];
  }

  static Future<bool> createStory({required String mediaUrl, required String caption}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/stories'),
        headers: _headers,
        body: jsonEncode({
          'mediaUrl': mediaUrl,
          'caption': caption,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Error createStory: $e');
      return false;
    }
  }

  static Future<void> viewStory(String storyId) async {
    try {
      await http.post(Uri.parse('$baseUrl/stories/$storyId/view'), headers: _headers);
    } catch (e) {
      print('Error viewStory: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stories/$storyId/viewers'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['viewers'] ?? []);
      }
    } catch (e) {
      print('Error getStoryViewers: $e');
    }
    return [];
  }

  static Future<bool> deleteStory(String storyId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/stories/$storyId'), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      print('Error deleteStory: $e');
      return false;
    }
  }


  // Groups
  static Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/groups'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['groups'] ?? []);
      }
    } catch (e) {
      print('Error getGroups: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createGroup({
    required String name,
    String? avatar,
    required List<String> participantIds,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/groups'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'avatar': avatar ?? '',
          'participantIds': participantIds,
        }),
      );
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['group'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error createGroup: $e');
    }
    return null;
  }

  static Future<bool> addParticipantsToGroup({
    required String groupId,
    required List<String> userIds,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/groups/$groupId/participants'),
        headers: _headers,
        body: jsonEncode({
          'userIds': userIds,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error addParticipantsToGroup: $e');
    }
    return false;
  }

  // Calls
  static Future<List<Map<String, dynamic>>> getCalls() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/calls'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['calls'] ?? []);
      }
    } catch (e) {
      print('Error getCalls: $e');
    }
    return [];
  }

  static Future<bool> recordCall({
    required String callerId,
    required String receiverId,
    required String status,
    required int duration,
    String type = 'audio',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/calls'),
        headers: _headers,
        body: jsonEncode({
          'callerId': callerId,
          'receiverId': receiverId,
          'status': status,
          'duration': duration,
          'type': type,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('Error recordCall: $e');
      return false;
    }
  }

  // Profile & Photos
  static Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          if (user['name'] != null && (user['name'] as String).isNotEmpty) {
            currentUserName = user['name'];
          }
          if (user['phoneNumber'] != null && (user['phoneNumber'] as String).isNotEmpty) {
            currentUserPhone = user['phoneNumber'];
          }
          if (user['avatarUrl'] != null && (user['avatarUrl'] as String).isNotEmpty) {
            currentUserAvatar = user['avatarUrl'];
          }
        }
        return user;
      }
    } catch (e) {
      print('Error getMyProfile: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    String? name,
    String? aboutStatus,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (aboutStatus != null) body['aboutStatus'] = aboutStatus;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final res = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['user'];
        if (user != null) {
          if (user['name'] != null) currentUserName = user['name'];
          if (user['avatarUrl'] != null) currentUserAvatar = user['avatarUrl'];
        }
        return data;
      }
    } catch (e) {
      print('Error updateProfile: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getUserPhotos({String? userId}) async {
    try {
      final targetId = userId ?? currentUserId;
      final res = await http.get(Uri.parse('$baseUrl/auth/photos?userId=$targetId'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['photos'] ?? []);
      }
    } catch (e) {
      print('Error getUserPhotos: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addUserPhoto({
    required String url,
    String? caption,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/photos'),
        headers: _headers,
        body: jsonEncode({
          'url': url,
          'caption': caption,
        }),
      );
      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print('Error addUserPhoto: $e');
    }
    return null;
  }

  static Future<bool> deleteUserPhoto(String photoId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/auth/photos/$photoId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error deleteUserPhoto: $e');
      return false;
    }
  }

  static Future<String?> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final base64Image = base64Encode(bytes);
      final ext = filename.contains('.') ? filename.split('.').last : 'jpg';
      final res = await http.post(
        Uri.parse('$baseUrl/auth/upload'),
        headers: _headers,
        body: jsonEncode({
          'base64': base64Image,
          'filename': filename,
          'ext': ext,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String?;
      }
    } catch (e) {
      print('Error uploadImage: $e');
    }
    return null;
  }

  static Future<String?> uploadMedia({
    required Uint8List bytes,
    required String filename,
    String? ext,
  }) async {
    try {
      final base64Data = base64Encode(bytes);
      final fileExt = ext ?? (filename.contains('.') ? filename.split('.').last : 'm4a');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/upload'),
        headers: _headers,
        body: jsonEncode({
          'base64': base64Data,
          'filename': filename,
          'ext': fileExt,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['url'] as String?;
      }
    } catch (e) {
      print('Error uploadMedia: $e');
    }
    return null;
  }
}


