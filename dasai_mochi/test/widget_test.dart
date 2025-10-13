// This is a basic Flutter widget test for Dasai Mochi app.

import 'package:flutter_test/flutter_test.dart';

import 'package:dasai_mochi/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DasaiMochiApp());

    // Verify that splash screen appears
    expect(find.text('Dasai Mochi'), findsOneWidget);
    expect(find.text('Your cute AI companion'), findsOneWidget);
  });
}
