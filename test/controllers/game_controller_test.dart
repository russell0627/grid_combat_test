import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grid_combat_test/controllers/game_controller.dart';
import 'package:grid_combat_test/models/direction.dart';
import 'package:grid_combat_test/models/player_class.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Add this line

  group('GameController', () {
    late ProviderContainer container;
    late GameController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(gameControllerProvider(PlayerClassType.warrior).notifier);
      // Stop the ticker to prevent automatic updates during tests.
      controller.ticker.stop();
    });

    tearDown(() {
      container.dispose();
    });

    // ... (rest of the tests remain the same) ...

    group('Grid Logic', () {
      test('isCellBlocked returns true for out-of-bounds coordinates', () {
        expect(controller.isCellBlocked(-1, 0), isTrue);
        expect(controller.isCellBlocked(0, -1), isTrue);
        expect(controller.isCellBlocked(30, 0), isTrue);
        expect(controller.isCellBlocked(0, 30), isTrue);
      });

      test('isCellBlocked returns false for traversable cells', () {
        expect(controller.isCellBlocked(5, 5), isFalse);
      });

      test('isCellBlocked returns true for non-traversable cells', () {
        controller.setCell(5, 5, traversable: false);
        expect(controller.isCellBlocked(5, 5), isTrue);
      });
    });

    group('Player Movement', () {
      test('movePlayer updates player position on valid move', () {
        final initialPosition = container
            .read(gameControllerProvider(PlayerClassType.warrior))
            .characters
            .first
            .logicalPosition;
        controller.movePlayer(Direction.right);
        final newPosition = container
            .read(gameControllerProvider(PlayerClassType.warrior))
            .characters
            .first
            .logicalPosition;
        expect(newPosition, Point(initialPosition.x + 1, initialPosition.y));
      });

      test('movePlayer does not update player position on invalid move', () {
        final initialPosition = container
            .read(gameControllerProvider(PlayerClassType.warrior))
            .characters
            .first
            .logicalPosition;
        controller.setCell(initialPosition.x + 1, initialPosition.y, traversable: false);
        controller.movePlayer(Direction.right);
        final newPosition = container
            .read(gameControllerProvider(PlayerClassType.warrior))
            .characters
            .first
            .logicalPosition;
        expect(newPosition, initialPosition);
      });
    });

    group('Abilities', () {
      test('usePlayerAbility creates a projectile', () {
        final mageController = container.read(gameControllerProvider(PlayerClassType.mage).notifier);
        final player = container.read(gameControllerProvider(PlayerClassType.mage)).characters.first;
        final enemy = container.read(gameControllerProvider(PlayerClassType.mage)).characters.last;
        final fireball = player.abilities.firstWhere((a) => a.name == 'Fireball');
        final targetPoint = enemy.logicalPosition;

        expect(container.read(gameControllerProvider(PlayerClassType.mage)).projectiles, isEmpty);

        mageController.usePlayerAbility(fireball, targetPoint);

        expect(container.read(gameControllerProvider(PlayerClassType.mage)).projectiles, isNotEmpty);
        expect(container.read(gameControllerProvider(PlayerClassType.mage)).projectiles.first.ability.name, 'Fireball');
      });
    });

    group('Action Buffering', () {
      test('buffers and executes action when player moves into range', () {
        final mageController = container.read(gameControllerProvider(PlayerClassType.mage).notifier);
        final player = container.read(gameControllerProvider(PlayerClassType.mage)).characters.first;
        final enemy = container
            .read(gameControllerProvider(PlayerClassType.mage))
            .characters
            .last
            .copyWith(logicalPosition: const Point(15, 15));
        mageController.state = mageController.state.copyWith(characters: [player, enemy]);

        final fireball = player.abilities.firstWhere((a) => a.name == 'Fireball');
        final targetPoint = enemy.logicalPosition;

        mageController.usePlayerAbility(fireball, targetPoint);

        var currentState = container.read(gameControllerProvider(PlayerClassType.mage));
        expect(currentState.pendingAbility, fireball);
        expect(currentState.pendingTarget, targetPoint);
        expect(currentState.projectiles, isEmpty); // No projectile should be fired yet.

        mageController.movePlayer(Direction.downRight);
        mageController.movePlayer(Direction.downRight);
        mageController.movePlayer(Direction.downRight);
        mageController.movePlayer(Direction.downRight);
        mageController.movePlayer(Direction.downRight);

        currentState = container.read(gameControllerProvider(PlayerClassType.mage));
        expect(currentState.pendingAbility, isNull);
        expect(currentState.projectiles, isNotEmpty); // A projectile should now be in flight.
      });
    });
  });
}
