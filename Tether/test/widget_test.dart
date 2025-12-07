// Basic widget test for Tether app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tether/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TetherApp(showOnboarding: false));

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
