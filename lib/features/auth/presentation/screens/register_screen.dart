import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  @override void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, AsyncValue<void> next) {
      next.whenOrNull(error: (Object error, StackTrace stackTrace) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error)))));
    });
    final bool loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      IconButton(onPressed: () => Navigator.of(context).pop(), alignment: Alignment.centerLeft, icon: const Icon(Icons.arrow_back)),
      Text('Start your focus journey', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      const Text('Your settings stay private and in your control.'), const SizedBox(height: 24),
      Form(key: _formKey, child: Column(children: <Widget>[
        TextFormField(controller: _name, enabled: !loading, textCapitalization: TextCapitalization.words, autofillHints: const <String>[AutofillHints.name], decoration: const InputDecoration(labelText: 'Name'), validator: (String? value) => value == null || value.trim().length < 2 ? 'Enter your name.' : null), const SizedBox(height: 12),
        TextFormField(controller: _email, enabled: !loading, keyboardType: TextInputType.emailAddress, autofillHints: const <String>[AutofillHints.email], decoration: const InputDecoration(labelText: 'Email'), validator: (String? value) => value == null || !value.contains('@') ? 'Enter a valid email address.' : null), const SizedBox(height: 12),
        TextFormField(controller: _password, enabled: !loading, obscureText: _obscurePassword, autofillHints: const <String>[AutofillHints.newPassword], decoration: InputDecoration(labelText: 'Password', helperText: 'At least 8 characters', suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: (String? value) => value == null || value.length < 8 ? 'Use at least 8 characters.' : null),
      ])), const SizedBox(height: 24),
      ElevatedButton(onPressed: loading ? null : _register, child: loading ? const CircularProgressIndicator() : const Text('Create account')),
    ]));
  }
  void _register() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).register(_email.text, _password.text, _name.text);
    }
  }
}
