// This is a basic Flutter widget test for Fennec Pro.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:fennec_pro_mobile/main.dart';

void main() {
  testWidgets('Fennec Pro smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FennecProApp());

    // Verify that our auth screen loads and shows the titles.
    expect(find.text('FENNEC PRO'), findsOneWidget);
    expect(find.text('SECURE ACTIVATION'), findsOneWidget);
  });
}

