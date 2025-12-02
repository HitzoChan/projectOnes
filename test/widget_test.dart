// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_one/screens/unified_login_screen.dart';

void main() {
  testWidgets('UnifiedLoginScreen displays welcome text', (WidgetTester tester) async {
    // Build our login screen and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: UnifiedLoginScreen()));

    // Verify the screen displays the attendance monitoring text
    expect(find.text('Attendance Monitoring'), findsOneWidget);
    expect(find.text('Senior High School'), findsOneWidget);
  });
}
