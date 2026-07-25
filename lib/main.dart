import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
    runApp(const ProviderScope(child: FocusGuardApp(isFirebaseConfigured: true)));
  } catch (_) {
    runApp(const ProviderScope(child: FocusGuardApp(isFirebaseConfigured: false)));
  }
}

