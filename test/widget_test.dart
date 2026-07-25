import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_guard/app.dart';

void main() {
  testWidgets('shows setup guidance when Firebase is not configured', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FocusGuardApp(isFirebaseConfigured: false)));

    expect(find.text('Firebase setup required'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
  });
}
