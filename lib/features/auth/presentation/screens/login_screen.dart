import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authControllerProvider, (_, AsyncValue<void> next) {
      next.whenOrNull(error: (Object error, StackTrace stackTrace) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(error)))));
    });
    final bool loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        const AuthBrand(), const SizedBox(height: 42),
        Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Form(key: _formKey, child: Column(children: <Widget>[
          TextFormField(controller: _email, enabled: !loading, keyboardType: TextInputType.emailAddress, autofillHints: const <String>[AutofillHints.email], decoration: const InputDecoration(labelText: 'Email'), validator: _emailValidator),
          const SizedBox(height: 12),
          TextFormField(controller: _password, enabled: !loading, obscureText: _obscurePassword, autofillHints: const <String>[AutofillHints.password], decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))), validator: _passwordValidator),
        ])),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: loading ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen())), child: const Text('Forgot password?'))),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: loading ? null : _signIn, child: loading ? const CircularProgressIndicator() : const Text('Sign in')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: loading ? null : () => ref.read(authControllerProvider.notifier).signInWithGoogle(), icon: const Icon(Icons.g_mobiledata_rounded), label: const Text('Continue with Google')),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[const Text('New to FocusGuard?'), TextButton(onPressed: loading ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen())), child: const Text('Create an account'))]),
      ]),
    );
  }

  void _signIn() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
    }
  }
}

String? _emailValidator(String? value) => value == null || !value.contains('@') ? 'Enter a valid email address.' : null;
String? _passwordValidator(String? value) => value == null || value.length < 8 ? 'Use at least 8 characters.' : null;
