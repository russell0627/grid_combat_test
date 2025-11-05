import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_combat_test/main.dart';
import 'package:grid_combat_test/models/player_class.dart';

void main() {
  testWidgets('GameScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap it in a ProviderScope for Riverpod to work.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GameScreen(selectedClass: PlayerClassType.warrior),
        ),
      ),
    );

    // Verify that the AppBar title is correct.
    expect(find.text('Project Ghost Grid - Level 1'), findsOneWidget);

    // Verify that the Player and Enemy are rendered by checking for their health.
    expect(find.text('120'), findsOneWidget); // Warrior health
    expect(find.text('100'), findsOneWidget); // Enemy health
  });
}
