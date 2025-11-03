import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_combat_test/controllers/game_controller.dart';
import 'package:grid_combat_test/models/direction.dart';
import 'package:grid_combat_test/models/game_character.dart';

void main() {
  group('GameController', () {
    late ProviderContainer container;
    late GameController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(gameControllerProvider.notifier);
      controller.timer?.cancel();
    });

    tearDown(() {
      container.dispose();
    });

    // ... (other test groups) ...

    group('Action Buffering', () {
      test('buffers and executes action when player moves into range', () {
        // 1. Manually set up a state where the enemy is out of range.
        final player = container.read(gameControllerProvider).characters.first;
        final enemy = container.read(gameControllerProvider).characters.last.copyWith(logicalPosition: const Point(15, 15));
        controller.state = controller.state.copyWith(characters: [player, enemy]);

        final fireball = player.abilities.first;
        final targetPoint = enemy.logicalPosition;

        // 2. Use the ability on the out-of-range target.
        controller.usePlayerAbility(fireball, targetPoint);

        // 3. Verify the action was buffered and no damage was dealt.
        var currentState = container.read(gameControllerProvider);
        expect(currentState.pendingAbility, fireball);
        expect(currentState.pendingTarget, targetPoint);
        expect(currentState.characters.last.health, 100);

        // 4. Move the player close enough for the target to be in range.
        // Player at (5,5), Target at (15,15). Range is 8.
        // Moving to (8,8) makes the distance sqrt(7^2+7^2) = ~9.9 (still out of range)
        // Moving to (9,9) makes the distance sqrt(6^2+6^2) = ~8.4 (still out of range)
        // Moving to (10,10) makes the distance sqrt(5^2+5^2) = ~7.07 (IN RANGE)
        controller.movePlayer(Direction.downRight); // pos: (6,6)
        controller.movePlayer(Direction.downRight); // pos: (7,7)
        controller.movePlayer(Direction.downRight); // pos: (8,8)
        controller.movePlayer(Direction.downRight); // pos: (9,9)

        // Health should still be 100, as we are not yet in range.
        expect(container.read(gameControllerProvider).characters.last.health, 100);

        // 5. The final move that puts the player in range.
        controller.movePlayer(Direction.downRight); // pos: (10,10)

        // 6. Verify the buffered action was executed and the state was cleared.
        currentState = container.read(gameControllerProvider);
        expect(currentState.pendingAbility, isNull);
        expect(currentState.pendingTarget, isNull);
        expect(currentState.characters.last.health, 75);
      });
    });
  });
}
