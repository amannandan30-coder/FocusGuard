import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _sent = false;
  @override void dispose() { _email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, AsyncValue<void> next) {
      next.whenOrNull(
        data: (_) {
          if (mounted && !_sent) {
            setState(() => _sent = true);
          }
        },
        error: (Object error, StackTrace stackTrace) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error)))),
      );
    });
    final bool loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      IconButton(onPressed: () => Navigator.of(context).pop(), alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back)),
      Icon(Icons.mark_email_read_outlined, size: 56, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 20),
      Text(_sent ? 'Check your inbox' : 'Reset your password', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 10),
      Text(_sent ? 'We sent password-reset instructions to ${_email.text.trim()}.' : 'Enter your email and we’ll send you a secure reset link.'),
      if (!_sent) ...<Widget>[const SizedBox(height: 24), Form(key: _formKey, child: TextFormField(controller: _email, enabled: !loading, keyboardType: TextInputType.emailAddress, autofocus: true, decoration: const InputDecoration(labelText: 'Email'), validator: (String? value) => value == null || !value.contains('@') ? 'Enter a valid email address.' : null)), const SizedBox(height: 24), ElevatedButton(onPressed: loading ? null : _send, child: loading ? const CircularProgressIndicator() : const Text('Send reset link'))] else ...<Widget>[const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to sign in'))],
    ]));
  }
  void _send() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).resetPassword(_email.text);
    }
  }
}
