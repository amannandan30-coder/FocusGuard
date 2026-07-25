import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/firebase_setup_screen.dart';

class FocusGuardApp extends ConsumerWidget {
  const FocusGuardApp({required this.isFirebaseConfigured, super.key});

  final bool isFirebaseConfigured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'FocusGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: isFirebaseConfigured ? const AuthGate() : const FirebaseSetupScreen(),
    );
  }
}
