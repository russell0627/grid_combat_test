// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grid_combat_test/main.dart';

void main() {
  testWidgets('GameScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap it in a ProviderScope for Riverpod to work.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the AppBar title is correct.
    expect(find.text('Project Ghost Grid'), findsOneWidget);

    // Verify that the Player and Enemy are rendered by checking for their health.
    // Since both start at 100 health, we expect to find two widgets with '100'.
    expect(find.text('100'), findsNWidgets(2));
  });
}
