import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chats/chat_list_screen.dart';
import 'profile/profile_screen.dart';
import 'settings/settings_screen.dart';
import '../providers/settings_provider.dart';
import '../providers/socket_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 1; // Default to All Chat (middle tab)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiService.getMyProfile();
      if (ref.read(socketProvider) == null || !ref.read(socketProvider)!.connected) {
        ref.read(socketProvider.notifier).connect(ApiService.currentUserId);
      } else {
        ref.read(socketProvider)?.emit('identify', ApiService.currentUserId);
      }
    });
  }

  final List<Widget> _pages = const [
    ProfileScreen(),
    ChatListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationsProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: const Color(0xFF9E9E9E),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Automatically synchronize fresh data across all tabs
            ref.read(contactSyncProvider.notifier).state++;
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded, size: 28),
              activeIcon: const Icon(Icons.person_rounded, size: 28),
              label: tr.tabProfile,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 28),
              activeIcon: const Icon(Icons.chat_bubble_rounded, size: 28),
              label: tr.tabChats,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined, size: 28),
              activeIcon: const Icon(Icons.settings, size: 28),
              label: tr.tabSettings,
            ),
          ],
        ),
      ),
    );
  }
}
