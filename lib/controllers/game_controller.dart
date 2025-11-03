import 'dart:async';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ability.dart';
import '../models/direction.dart';
import '../models/game_character.dart';
import '../models/game_state.dart';
import '../models/grid_cell.dart';
import '../models/projectile.dart';
import '../main.dart'; // For cellSize

part 'game_controller.g.dart';

@riverpod
class GameController extends _$GameController {
  late final Ticker ticker;
  DateTime _lastAiUpdateTime = DateTime.now();

  @override
  GameState build() {
    ticker = Ticker(_onTick);
    ticker.start();
    ref.onDispose(() => ticker.dispose());
    return GameState.initial();
  }

  void _onTick(Duration elapsed) {
    _updateProjectiles();
    _updateAI();
  }

  void _updateProjectiles() {
    if (state.projectiles.isEmpty) return;

    final now = DateTime.now();
    final List<Projectile> remainingProjectiles = [];
    final List<Projectile> arrivedProjectiles = [];

    for (final projectile in state.projectiles) {
      final progress = now.difference(projectile.startTime).inMilliseconds / projectile.travelTime.inMilliseconds;
      if (progress >= 1.0) {
        arrivedProjectiles.add(projectile);
      } else {
        remainingProjectiles.add(projectile);
      }
    }

    if (arrivedProjectiles.isNotEmpty) {
      _applyProjectileEffects(arrivedProjectiles);
      state = state.copyWith(projectiles: remainingProjectiles);
    }
  }

  void _applyProjectileEffects(List<Projectile> projectiles) {
    var currentCharacters = List<GameCharacter>.from(state.characters);
    for (final projectile in projectiles) {
      currentCharacters = currentCharacters.map((char) {
        final distanceToChar = sqrt(pow(projectile.targetCell.x - char.logicalPosition.x, 2) + pow(projectile.targetCell.y - char.logicalPosition.y, 2));
        if (distanceToChar <= projectile.ability.aoeRadius) {
          final newHealth = char.health - projectile.ability.damage;
          return char.copyWith(health: newHealth > 0 ? newHealth : 0);
        }
        return char;
      }).toList();
    }
    currentCharacters.removeWhere((char) => char.health <= 0);
    state = state.copyWith(characters: currentCharacters);
  }

  void _updateAI() {
    final now = DateTime.now();
    if (now.difference(_lastAiUpdateTime).inSeconds < 1) return;
    _lastAiUpdateTime = now;

    if (state.characters.length <= 1) return;

    final player = state.characters.first;
    final playerPos = player.logicalPosition;
    var currentCharacters = List<GameCharacter>.from(state.characters);

    for (int i = 1; i < currentCharacters.length; i++) {
      final enemy = currentCharacters[i];
      final distanceToPlayer = sqrt(pow(playerPos.x - enemy.logicalPosition.x, 2) + pow(playerPos.y - enemy.logicalPosition.y, 2));
      final enemyAbility = enemy.abilities.first;

      if (distanceToPlayer <= enemyAbility.range) {
        _fireProjectile(i, enemyAbility, playerPos);
      } else {
        Direction bestDirection = Direction.up;
        double minDistance = double.infinity;

        for (var direction in Direction.values) {
          final newPos = _getNewPosition(enemy.logicalPosition, direction);
          if (isCellBlocked(newPos.x, newPos.y)) continue;

          final distance = sqrt(pow(playerPos.x - newPos.x, 2) + pow(playerPos.y - newPos.y, 2));
          if (distance < minDistance) {
            minDistance = distance;
            bestDirection = direction;
          }
        }
        final finalPos = _getNewPosition(enemy.logicalPosition, bestDirection);
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
    usePlayerAbility(state.targetingAbility!, position);
    state = state.copyWith(clearTargeting: true);
  }

  void cancelTargeting() {
    state = state.copyWith(clearTargeting: true, clearPending: true);
  }

  void usePlayerAbility(Ability ability, Point<int> target) {
    _fireProjectile(0, ability, target);
  }

  void useMeleeAttack() {
    final player = state.characters.first;
    final ability = player.abilities.firstWhere((a) => a.name == 'Sword Slash');
    final target = _getNewPosition(player.logicalPosition, player.facingDirection);
    _fireProjectile(0, ability, target);
  }

  void _fireProjectile(int characterIndex, Ability ability, Point<int> target) {
    final caster = state.characters[characterIndex];
    final casterPos = caster.logicalPosition;
    final distanceToTarget = sqrt(pow(casterPos.x - target.x, 2) + pow(casterPos.y - target.y, 2));

    if (characterIndex == 0 && distanceToTarget > ability.range) {
      state = state.copyWith(pendingAbility: ability, pendingTarget: target);
      return;
    }

    if (distanceToTarget > ability.range) return;

    if (ability.range > 1.5 && _hasWallInLineOfSight(casterPos, target)) {
      return;
    }

    final newProjectile = Projectile(
      startPosition: Point(casterPos.x * GameScreen.cellSize + GameScreen.cellSize / 2, casterPos.y * GameScreen.cellSize + GameScreen.cellSize / 2),
      endPosition: Point(target.x * GameScreen.cellSize + GameScreen.cellSize / 2, target.y * GameScreen.cellSize + GameScreen.cellSize / 2),
      targetCell: target,
      ability: ability,
      startTime: DateTime.now(),
      travelTime: const Duration(milliseconds: 50), // Melee attacks are almost instant
    );

    final newProjectiles = List<Projectile>.from(state.projectiles)..add(newProjectile);
    state = state.copyWith(characters: state.characters, projectiles: newProjectiles, clearPending: true);
  }

  void movePlayer(Direction direction) {
    final player = state.characters.first;
    final newPos = _getNewPosition(player.logicalPosition, direction);

    if (!isCellBlocked(newPos.x, newPos.y)) {
      final newPlayer = player.copyWith(logicalPosition: newPos, facingDirection: direction);
      final newCharacters = List<GameCharacter>.from(state.characters);
      newCharacters[0] = newPlayer;
      state = state.copyWith(characters: newCharacters);

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
        _fireProjectile(0, ability, target);
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

  bool _hasWallInLineOfSight(Point<int> start, Point<int> end) {
    int x0 = start.x;
    int y0 = start.y;
    int x1 = end.x;
    int y1 = end.y;

    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = (x0 < x1) ? 1 : -1;
    int sy = (y0 < y1) ? 1 : -1;
    int err = dx - dy;

    while (true) {
      if (!((x0 == start.x && y0 == start.y) || (x0 == x1 && y0 == y1))) {
        if (isCellBlocked(x0, y0)) {
          return true;
        }
      }

      if (x0 == x1 && y0 == y1) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x0 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y0 += sy;
      }
    }
    return false;
  }

  void setCell(int x, int y, {required bool traversable}) {
    final newGrid = state.grid.map((row) => List.of(row)).toList();
    if (y >= 0 && y < newGrid.length && x >= 0 && x < newGrid[y].length) {
      newGrid[y][x] = GridCell(terrainType: traversable ? TerrainType.grass : TerrainType.wall);
      state = state.copyWith(grid: newGrid);
    }
  }
}
