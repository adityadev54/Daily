// Spera - Widget Tests
//
// Basic smoke tests for the Spera application.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spera/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SperaApp()));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app loads with the home screen
    expect(find.text('Spera'), findsOneWidget);
  });
}
