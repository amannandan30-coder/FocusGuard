import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460, minHeight: size.height - 48),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(24)),
          child: Icon(Icons.shield_outlined, size: 40, color: colors.onPrimaryContainer),
        ),
        const SizedBox(height: 20),
        Text('FocusGuard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Create space for what matters.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
      ],
    );
  }
}

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    if (error.code == 'operation-not-allowed') {
      return 'Sign-in method is disabled in Firebase Console (Authentication -> Sign-in method).';
    }
    if (error.code == 'invalid-credential' || error.code == 'wrong-password' || error.code == 'user-not-found') {
      return 'The email or password is incorrect.';
    }
    if (error.code == 'email-already-in-use') {
      return 'An account already exists for this email.';
    }
    if (error.code == 'weak-password') {
      return 'Use a password with at least 8 characters.';
    }
    if (error.code == 'network-request-failed') {
      return 'Check your internet connection and try again.';
    }
    if (error.code == 'account-exists-with-different-credential') {
      return 'This email already uses another sign-in method.';
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  final String text = error.toString();
  if (text.contains('10:') || text.contains('DEVELOPER_ERROR') || text.contains('ApiException')) {
    return 'Google Sign-In failed: SHA-1 fingerprint or OAuth Client ID is missing in Firebase Console.';
  }
  if (text.contains('operation-not-allowed')) {
    return 'Sign-in method is disabled in Firebase Console.';
  }
  return 'Auth Error: $text';
}
