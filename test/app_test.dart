import 'package:flutter_test/flutter_test.dart';

import 'package:focus_guard/features/auth/presentation/widgets/auth_scaffold.dart';

void main() {
  group('authErrorMessage', () {
    test('maps credential failures to a safe user message', () {
      expect(authErrorMessage(Exception('invalid-credential')), 'The email or password is incorrect.');
    });

    test('does not expose unknown implementation errors', () {
      expect(authErrorMessage(Exception('private backend details')), 'Something went wrong. Please try again.');
    });
  });
}
