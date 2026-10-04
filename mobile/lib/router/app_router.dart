import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_layout.dart';
import '../screens/chats/chat_room_screen.dart';
import '../screens/profile/friend_profile_screen.dart';

// Placeholder Auth State Provider
final authProvider = StateProvider<bool>((ref) => false);

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<bool>(ref.read(authProvider));
  ref.listen<bool>(authProvider, (_, next) => authNotifier.value = next);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final isAuth = ref.read(authProvider);
          return isAuth ? '/home' : '/login';
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final targetUserName = state.uri.queryParameters['name'] ?? 'Teman';
          final targetUserId = state.uri.queryParameters['targetId'] ?? 'user_target';
          final targetPhone = state.uri.queryParameters['phone'];
          final targetAvatar = state.uri.queryParameters['avatar'];
          return ChatRoomScreen(
            conversationId: id,
            targetUserName: targetUserName,
            targetUserId: targetUserId,
            targetUserPhone: targetPhone,
            targetUserAvatar: targetAvatar,
          );
        },
      ),
      GoRoute(
        path: '/profile/friend/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'] ?? 'Teman';
          final phone = state.uri.queryParameters['phone'];
          final avatar = state.uri.queryParameters['avatar'];
          return FriendProfileScreen(
            userId: id,
            userName: name,
            userPhone: phone,
            userAvatar: avatar,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider);
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
  );
});
