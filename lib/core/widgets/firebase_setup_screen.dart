import 'package:flutter/material.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(Icons.settings_suggest_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text('Firebase setup required', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text('FocusGuard can start safely, but sign-in is unavailable until it is connected to a Firebase project.', textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Card(child: Padding(padding: const EdgeInsets.all(20), child: SelectableText('flutterfire configure --platforms=android,web,windows\nflutter pub get\nflutter run', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')))),
                  const SizedBox(height: 16),
                  Text('This command generates lib/firebase_options.dart using your Firebase project settings. Then restart the app.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
