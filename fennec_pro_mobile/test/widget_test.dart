// This is a basic Flutter widget test for Secmon.

import 'package:flutter_test/flutter_test.dart';
import 'package:secmon_pro_mobile/main.dart';

void main() {
  testWidgets('Secmon smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecmonApp());

    // Verify that our auth screen loads and shows the titles.
    expect(find.text('SECMON'), findsOneWidget);
    expect(find.text('SECURE ACTIVATION'), findsOneWidget);
  });
}

