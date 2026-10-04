import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'screens/call/incoming_call_overlay.dart';

void main() {
  runApp(
    const ProviderScope(
      child: QuickChatApp(),
    ),
  );
}

class QuickChatApp extends ConsumerWidget {
  const QuickChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'QuickChat',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GlobalCallManager(child: child ?? const SizedBox());
      },
    );
  }
}
