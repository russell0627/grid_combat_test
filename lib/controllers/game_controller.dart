import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ability.dart';
import '../models/direction.dart';
import '../models/game_character.dart';
import '../models/game_state.dart';
import '../models/grid_cell.dart';

part 'game_controller.g.dart';

@riverpod
class GameController extends _$GameController {
  Timer? timer;

  @override
  GameState build() {
    _startUpdateLoop();
    ref.onDispose(() => timer?.cancel());
    return GameState.initial();
  }

  void _startUpdateLoop() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) => update());
  }

  void update() {
    if (state.characters.length <= 1) return;

    final player = state.characters.first;
    final playerPos = player.logicalPosition;
    final currentCharacters = List<GameCharacter>.from(state.characters);

    for (int i = 1; i < currentCharacters.length; i++) {
      final enemy = currentCharacters[i];
      final enemyPos = enemy.logicalPosition;
      final distanceToPlayer = sqrt(pow(playerPos.x - enemyPos.x, 2) + pow(playerPos.y - enemyPos.y, 2));
      final enemyAbility = enemy.abilities.first;

      if (distanceToPlayer <= enemyAbility.range) {
        _useAbility(i, enemyAbility, playerPos);
        return;
      } else {
        Direction bestDirection = Direction.up;
        double minDistance = double.infinity;

        for (var direction in Direction.values) {
          final newPos = _getNewPosition(enemyPos, direction);
          if (isCellBlocked(newPos.x, newPos.y)) continue;

          final distance = sqrt(pow(playerPos.x - newPos.x, 2) + pow(playerPos.y - newPos.y, 2));
          if (distance < minDistance) {
            minDistance = distance;
            bestDirection = direction;
          }
        }
        final finalPos = _getNewPosition(enemyPos, bestDirection);
        currentCharacters[i] = enemy.copyWith(logicalPosition: finalPos);
      }
    }
    state = state.copyWith(characters: currentCharacters);
  }

  void enterTargetingMode(Ability ability) {
    state = state.copyWith(targetingAbility: ability, clearPending: true);
  }

  void setTargetPosition(Point<int> position) {
    if (state.targetingAbility == null) return;
    state = state.copyWith(targetingPosition: position);
  }

  void confirmTarget() {
    if (state.targetingAbility != null && state.targetingPosition != null) {
      usePlayerAbility(state.targetingAbility!, state.targetingPosition!);
      state = state.copyWith(clearTargeting: true);
    }
  }

  void cancelTargeting() {
    state = state.copyWith(clearTargeting: true, clearPending: true);
  }

  void usePlayerAbility(Ability ability, Point target) {
    _useAbility(0, ability, target);
  }

  void _useAbility(int characterIndex, Ability ability, Point target) {
    final caster = state.characters[characterIndex];
    final casterPos = caster.logicalPosition;

    final distanceToTarget = sqrt(pow(casterPos.x - target.x, 2) + pow(casterPos.y - target.y, 2));

    // If the caster is the player and is out of range, buffer the action.
    if (characterIndex == 0 && distanceToTarget > ability.range) {
      state = state.copyWith(pendingAbility: ability, pendingTarget: target as Point<int>?);
      return;
    }

    if (distanceToTarget > ability.range) return; // For AI, just exit if out of range.

    var updatedCharacters = state.characters.map((char) {
      final distanceToChar = sqrt(pow(target.x - char.logicalPosition.x, 2) + pow(target.y - char.logicalPosition.y, 2));
      if (distanceToChar <= ability.aoeRadius) {
        final newHealth = char.health - ability.damage;
        return char.copyWith(health: newHealth > 0 ? newHealth : 0);
      }
      return char;
    }).toList();

    updatedCharacters.removeWhere((char) => char.health <= 0);
    // Clear any pending action after it's successfully used.
    state = state.copyWith(characters: updatedCharacters, clearPending: true);
  }

  void movePlayer(Direction direction) {
    final player = state.characters.first;
    final newPos = _getNewPosition(player.logicalPosition, direction);

    if (!isCellBlocked(newPos.x, newPos.y)) {
      final newPlayer = player.copyWith(logicalPosition: newPos);
      final newCharacters = List<GameCharacter>.from(state.characters);
      newCharacters[0] = newPlayer;
      state = state.copyWith(characters: newCharacters);

      // After moving, check if a buffered action can be executed.
      _checkAndExecutePendingAction();
    }
  }

  void _checkAndExecutePendingAction() {
    if (state.pendingAbility != null && state.pendingTarget != null) {
      final player = state.characters.first;
      final target = state.pendingTarget!;
      final ability = state.pendingAbility!;
      final distanceToTarget = sqrt(pow(player.logicalPosition.x - target.x, 2) + pow(player.logicalPosition.y - target.y, 2));

      if (distanceToTarget <= ability.range) {
        _useAbility(0, ability, target);
        // The _useAbility method now clears the pending state.
      }
    }
  }

  Point<int> _getNewPosition(Point<int> currentPos, Direction direction) {
    return switch (direction) {
      Direction.up => Point(currentPos.x, currentPos.y - 1),
      Direction.down => Point(currentPos.x, currentPos.y + 1),
      Direction.left => Point(currentPos.x - 1, currentPos.y),
      Direction.right => Point(currentPos.x + 1, currentPos.y),
      Direction.upLeft => Point(currentPos.x - 1, currentPos.y - 1),
      Direction.upRight => Point(currentPos.x + 1, currentPos.y - 1),
      Direction.downLeft => Point(currentPos.x - 1, currentPos.y + 1),
      Direction.downRight => Point(currentPos.x + 1, currentPos.y + 1),
    };
  }

  bool isCellBlocked(int x, int y) {
    if (y < 0 || y >= state.grid.length || x < 0 || x >= state.grid[y].length) {
      return true;
    }
    return !state.grid[y][x].isTraversable;
  }

  void setCell(int x, int y, {required bool traversable}) {
    final newGrid = state.grid.map((row) => List.of(row)).toList();
    if (y >= 0 && y < newGrid.length && x >= 0 && x < newGrid[y].length) {
      newGrid[y][x] = GridCell(isTraversable: traversable);
      state = state.copyWith(grid: newGrid);
    }
  }
}
