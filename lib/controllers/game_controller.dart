import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/ability.dart';
import '../models/direction.dart';
import '../models/game_character.dart';
import '../models/game_state.dart';
import '../models/grid_cell.dart';
import '../models/projectile.dart';
import '../models/status_effect.dart';
import '../models/game_level.dart';
import '../models/player_class.dart';
import '../models/equipment.dart';
import '../models/hit_location.dart';
import '../main.dart';

part 'game_controller.g.dart';

@Riverpod(keepAlive: true)
class GameController extends _$GameController {
  late final Ticker ticker;
  DateTime _lastAiUpdateTime = DateTime.now();
  DateTime _lastManaUpdateTime = DateTime.now();
  DateTime _lastMoveTime = DateTime.now();

  @override
  GameState build(PlayerClassType selectedClass) {
    ticker = Ticker(_onTick);
    ticker.start();
    ref.onDispose(() => ticker.dispose());
    return GameState.initial(selectedClass: selectedClass);
  }

  void _onTick(Duration elapsed) {
    _handleContinuousMovement();
    _updateProjectiles();
    _updateAI();
    _regenerateMana();
    _updateStatusEffects();
    _checkWinCondition();
  }

  // --- Debug Methods ---
  void toggleDebugMenu() {
    state = state.copyWith(isDebugMenuOpen: !state.isDebugMenuOpen);
  }

  void skipLevel() {
    if (state.currentLevelIndex < GameLevel.allLevels.length - 1) {
      state = GameState.initial(currentLevelIndex: state.currentLevelIndex + 1, selectedClass: state.characters.first.playerClass!.type);
    } else {
      state = GameState.initial(currentLevelIndex: 0, selectedClass: state.characters.first.playerClass!.type);
    }
  }

  void _handleContinuousMovement() {
    if (state.activeMoveDirections.isEmpty) return;

    final now = DateTime.now();
    if (now.difference(_lastMoveTime).inMilliseconds < 200) return;
    _lastMoveTime = now;

    Direction? finalDirection;
    if (state.activeMoveDirections.contains(Direction.up) && state.activeMoveDirections.contains(Direction.left)) {
      finalDirection = Direction.upLeft;
    } else if (state.activeMoveDirections.contains(Direction.up) && state.activeMoveDirections.contains(Direction.right)) {
      finalDirection = Direction.upRight;
    } else if (state.activeMoveDirections.contains(Direction.down) && state.activeMoveDirections.contains(Direction.left)) {
      finalDirection = Direction.downLeft;
    } else if (state.activeMoveDirections.contains(Direction.down) && state.activeMoveDirections.contains(Direction.right)) {
      finalDirection = Direction.downRight;
    } else if (state.activeMoveDirections.contains(Direction.up)) {
      finalDirection = Direction.up;
    } else if (state.activeMoveDirections.contains(Direction.down)) {
      finalDirection = Direction.down;
    } else if (state.activeMoveDirections.contains(Direction.left)) {
      finalDirection = Direction.left;
    } else if (state.activeMoveDirections.contains(Direction.right)) {
      finalDirection = Direction.right;
    }

    if (finalDirection != null) {
      movePlayer(finalDirection);
    }
  }

  void startMoving(Direction direction) {
    final newDirections = HashSet<Direction>.from(state.activeMoveDirections)..add(direction);
    state = state.copyWith(activeMoveDirections: newDirections);
  }

  void stopMoving(Direction direction) {
    final newDirections = HashSet<Direction>.from(state.activeMoveDirections)..remove(direction);
    state = state.copyWith(activeMoveDirections: newDirections);
  }

  void _regenerateMana() {
    final now = DateTime.now();
    if (now.difference(_lastManaUpdateTime).inSeconds < 1) return;
    _lastManaUpdateTime = now;

    final updatedCharacters = state.characters.map((char) {
      if (char.mana < char.maxMana) {
        return char.copyWith(mana: char.mana + 1);
      }
      return char;
    }).toList();

    state = state.copyWith(characters: updatedCharacters);
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
      for (int i = 0; i < currentCharacters.length; i++) {
        final char = currentCharacters[i];
        // Determine a random hit location for the character
        final hitLocation = projectile.ability.targetLocations[Random().nextInt(projectile.ability.targetLocations.length)];
        final damageModifier = DamageModifier.modifiers[hitLocation]!;

        for (int y = 0; y < char.size.y; y++) {
          for (int x = 0; x < char.size.x; x++) {
            final charCell = Point(char.logicalPosition.x + x, char.logicalPosition.y + y);
            final distanceToChar = sqrt(pow(projectile.targetCell.x - charCell.x, 2) + pow(projectile.targetCell.y - charCell.y, 2));
            if (distanceToChar <= projectile.ability.aoeRadius) {
              // Calculate total armor value for the hit location
              int totalArmor = 0;
              for (final equipment in char.equipment.values) {
                if (equipment.slot == EquipmentSlot.head && hitLocation == HitLocation.head) {
                  totalArmor += equipment.armorValue;
                } else if (equipment.slot == EquipmentSlot.chest && hitLocation == HitLocation.torso) {
                  totalArmor += equipment.armorValue;
                } else if (equipment.slot == EquipmentSlot.arms && hitLocation == HitLocation.arms) {
                  totalArmor += equipment.armorValue;
                } else if (equipment.slot == EquipmentSlot.legs && hitLocation == HitLocation.legs) {
                  totalArmor += equipment.armorValue;
                } else if (equipment.slot == EquipmentSlot.offHand && (hitLocation == HitLocation.arms || hitLocation == HitLocation.torso)) { // Shields can protect arms/torso
                  totalArmor += equipment.armorValue;
                }
                // Add more specific armor slot/hit location mappings as needed
              }

              // Calculate damage after armor absorption
              int effectiveDamage = projectile.ability.damage - totalArmor;
              if (effectiveDamage < 0) effectiveDamage = 0; // Damage cannot be negative

              // Apply hit location multiplier
              effectiveDamage = (effectiveDamage * damageModifier.multiplier).round();

              // Apply damage to specific hit location
              final newHealthByLocation = Map<HitLocation, int>.from(char.healthByLocation);
              newHealthByLocation[hitLocation] = (newHealthByLocation[hitLocation]! - effectiveDamage).clamp(0, char.maxHealthByLocation[hitLocation]!); // Clamp health to 0

              // Update character with new health and effects
              List<StatusEffect> newEffects = List.from(char.activeEffects);
              if (projectile.ability.appliesEffect != null) {
                newEffects.add(projectile.ability.appliesEffect!.copyWith(startTime: DateTime.now()));
              }
              currentCharacters[i] = char.copyWith(healthByLocation: newHealthByLocation, activeEffects: newEffects);
              break; // Apply effect only once per character
            }
          }
        }
      }
    }
    currentCharacters.removeWhere((char) => char.health <= 0);
    state = state.copyWith(characters: currentCharacters);
  }

  void _updateStatusEffects() {
    final now = DateTime.now();
    final updatedCharacters = state.characters.map((char) {
      final remainingEffects = char.activeEffects.where((effect) => now.difference(effect.startTime!).compareTo(effect.duration) < 0).toList();
      return char.copyWith(activeEffects: remainingEffects);
    }).toList();
    state = state.copyWith(characters: updatedCharacters);
  }

  void _updateAI() {
    final now = DateTime.now();
    if (now.difference(_lastAiUpdateTime).inMilliseconds < 400) return; // Slower AI movement
    _lastAiUpdateTime = now;

    if (state.characters.length <= 1) return;

    final player = state.characters.first;
    var currentCharacters = List<GameCharacter>.from(state.characters);

    for (int i = 0; i < currentCharacters.length; i++) {
      final character = currentCharacters[i];
      if (character == player || character.isStunned) continue;

      GameCharacter? target;
      if (character.abilities.first.isHeal) {
        // Healer AI: Target most damaged non-player, non-summon character
        double minHealthPercent = 1.0;
        for (final otherChar in state.characters) {
          if (otherChar != player && !otherChar.isSummon && otherChar.health < otherChar.maxHealth) {
            final healthPercent = otherChar.health / otherChar.maxHealth;
            if (healthPercent < minHealthPercent) {
              minHealthPercent = healthPercent;
              target = otherChar;
            }
          }
        }
      } else if (character.isSummon) {
        // Summon AI: Target closest non-summon, non-player character
        double minDistance = double.infinity;
        for (final otherChar in state.characters) {
          if (otherChar != player && !otherChar.isSummon) {
            final distance = sqrt(pow(character.logicalPosition.x - otherChar.logicalPosition.x, 2) + pow(character.logicalPosition.y - otherChar.logicalPosition.y, 2));
            if (distance < minDistance) {
              minDistance = distance;
              target = otherChar;
            }
          }
        }
      } else if (character.abilities.first.name == 'Summon') {
        // Summoner AI: Summon if there are less than 3 summons
        if (state.characters.where((c) => c.isSummon).length < 3) {
          final spawnPos = Point(character.logicalPosition.x, character.logicalPosition.y + 1);
          if (!isCellBlocked(spawnPos.x, spawnPos.y)) {
            summonMinions(spawnPos);
          }
        }
      } else {
        // Regular Enemy AI: Target player
        target = player;
      }

      if (target != null) {
        final distanceToTarget = sqrt(pow(character.logicalPosition.x - target.logicalPosition.x, 2) + pow(character.logicalPosition.y - target.logicalPosition.y, 2));
        final ability = character.abilities.first;

        if (character.isRanged) {
          if (distanceToTarget <= ability.range) {
            _fireProjectile(i, ability, target.logicalPosition);
          } else {
            // Move closer
            Direction bestDirection = Direction.up;
            double minChaseDistance = double.infinity;

            for (var direction in Direction.values) {
              final newPos = _getNewPosition(character.logicalPosition, direction);
              if (isCellBlocked(newPos.x, newPos.y, size: character.size, movingCharacter: character)) continue;

              final distance = sqrt(pow(target.logicalPosition.x - newPos.x, 2) + pow(target.logicalPosition.y - newPos.y, 2));
              if (distance < minChaseDistance) {
                minChaseDistance = distance;
                bestDirection = direction;
              }
            }
            final finalPos = _getNewPosition(character.logicalPosition, bestDirection);
            currentCharacters[i] = character.copyWith(logicalPosition: finalPos);
          }
        }
        // Melee AI (including Healer and Summoner, if they move)
        else {
          if (distanceToTarget <= ability.range && !ability.isHeal) {
            _fireProjectile(i, ability, target.logicalPosition);
          } else if (ability.isHeal && distanceToTarget <= ability.range) {
            _fireProjectile(i, ability, target.logicalPosition); // Healers fire at target
          } else {
            // Move closer
            Direction bestDirection = Direction.up;
            double minChaseDistance = double.infinity;

            for (var direction in Direction.values) {
              final newPos = _getNewPosition(character.logicalPosition, direction);
              if (isCellBlocked(newPos.x, newPos.y, size: character.size, movingCharacter: character)) continue;

              final distance = sqrt(pow(target.logicalPosition.x - newPos.x, 2) + pow(target.logicalPosition.y - newPos.y, 2));
              if (distance < minChaseDistance) {
                minChaseDistance = distance;
                bestDirection = direction;
              }
            }
            final finalPos = _getNewPosition(character.logicalPosition, bestDirection);
            currentCharacters[i] = character.copyWith(logicalPosition: finalPos);
          }
        }
      }
    }
    currentCharacters.removeWhere((char) => char.health <= 0);
    state = state.copyWith(characters: currentCharacters);
  }

  void _checkWinCondition() {
    if (state.characters.where((c) => !c.isSummon && c.playerClass == null).isEmpty) {
      if (state.currentLevelIndex < GameLevel.allLevels.length - 1) {
        state = GameState.initial(currentLevelIndex: state.currentLevelIndex + 1, selectedClass: state.characters.first.playerClass!.type);
      } else {
        state = GameState.initial(currentLevelIndex: 0, selectedClass: state.characters.first.playerClass!.type);
      }
    } else if (!state.characters.contains(state.characters.first) || state.characters.first.health <= 0) {
      state = GameState.initial(currentLevelIndex: 0, selectedClass: state.characters.first.playerClass!.type);
    }
  }

  void updateFacingDirection(Point<double> cursorPosition) {
    final player = state.characters.first;
    final playerScreenPos = Point(player.logicalPosition.x * GameScreen.cellSize + (player.size.x * GameScreen.cellSize) / 2, player.logicalPosition.y * GameScreen.cellSize + (player.size.y * GameScreen.cellSize) / 2);

    final angle = atan2(cursorPosition.y - playerScreenPos.y, cursorPosition.x - playerScreenPos.x);
    final degrees = angle * 180 / pi;

    Direction newDirection;
    if (degrees >= -22.5 && degrees < 22.5) {
      newDirection = Direction.right;
    } else if (degrees >= 22.5 && degrees < 67.5) {
      newDirection = Direction.downRight;
    } else if (degrees >= 67.5 && degrees < 112.5) {
      newDirection = Direction.down;
    } else if (degrees >= 112.5 && degrees < 157.5) {
      newDirection = Direction.downLeft;
    } else if (degrees >= 157.5 || degrees < -157.5) {
      newDirection = Direction.left;
    } else if (degrees >= -157.5 && degrees < -112.5) {
      newDirection = Direction.upLeft;
    } else if (degrees >= -112.5 && degrees < -67.5) {
      newDirection = Direction.up;
    } else { // -67.5 to -22.5
      newDirection = Direction.upRight;
    }

    if (player.facingDirection != newDirection) {
      final newPlayer = player.copyWith(facingDirection: newDirection);
      final newCharacters = List<GameCharacter>.from(state.characters);
      newCharacters[0] = newPlayer;
      state = state.copyWith(characters: newCharacters);
    }
  }

  void enterTargetingMode(Ability ability) {
    state = state.copyWith(targetingAbility: ability, clearPending: true);
  }

  void setTargetPosition(Point<int> position) {
    if (state.targetingAbility == null) return;

    if (state.targetingAbility!.name == 'Summon Minion') {
      summonMinions(position);
    } else {
      usePlayerAbility(state.targetingAbility!, position);
    }
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
    final ability = player.equipment[EquipmentSlot.mainHand]!.abilities.first;
    final target = _getNewPosition(player.logicalPosition, player.facingDirection);
    _fireProjectile(0, ability, target);
  }

  void dash() {
    final player = state.characters.first;

    if (player.lastDashTime != null && DateTime.now().difference(player.lastDashTime!).inSeconds < 2) {
      return;
    }

    Point<int> newPos = player.logicalPosition;
    for (int i = 0; i < 3; i++) { // Dash 3 cells
      final nextPos = _getNewPosition(newPos, player.facingDirection);
      if (isCellBlocked(nextPos.x, newPos.y, size: player.size, movingCharacter: player)) break;
      newPos = nextPos;
    }

    final newPlayer = player.copyWith(logicalPosition: newPos, lastDashTime: DateTime.now());
    final newCharacters = List<GameCharacter>.from(state.characters);
    newCharacters[0] = newPlayer;
    state = state.copyWith(characters: newCharacters);
  }

  void summonMinions(Point<int> position) {
    final player = state.characters.first;
    final ability = player.abilities.firstWhere((a) => a.name == 'Summon Minion');

    if (player.mana < ability.manaCost) return;

    final newCharacters = List<GameCharacter>.from(state.characters);
    final newPlayer = player.copyWith(mana: player.mana - ability.manaCost);
    newCharacters[0] = newPlayer;

    for (int i = 0; i < 2; i++) {
      final spawnPos = Point(position.x + i, position.y);
      if (isCellBlocked(spawnPos.x, spawnPos.y)) continue;

      newCharacters.add(
        GameCharacter(
          logicalPosition: spawnPos,
          isSummon: true,
          healthByLocation: {
            HitLocation.head: 5,
            HitLocation.torso: 10,
            HitLocation.arms: 5,
            HitLocation.legs: 5,
          },
          maxHealthByLocation: {
            HitLocation.head: 5,
            HitLocation.torso: 10,
            HitLocation.arms: 5,
            HitLocation.legs: 5,
          },
          equipment: {
            EquipmentSlot.mainHand: Equipment.items['Minion Claw']!,
          },
        ),
      );
    }

    state = state.copyWith(characters: newCharacters);
  }

  void _fireProjectile(int characterIndex, Ability ability, Point<int> target) {
    final caster = state.characters[characterIndex];
    final casterPos = caster.logicalPosition;

    if (caster.mana < ability.manaCost) return;

    // Check cooldown
    if (caster.abilityCooldowns.containsKey(ability.name) &&
        DateTime.now().difference(caster.abilityCooldowns[ability.name]!) < ability.cooldownDuration) {
      return; // Ability is on cooldown
    }

    final distanceToTarget = sqrt(pow(casterPos.x - target.x, 2) + pow(casterPos.y - target.y, 2));

    if (characterIndex == 0 && distanceToTarget > ability.range) {
      state = state.copyWith(pendingAbility: ability, pendingTarget: target);
      return;
    }

    if (distanceToTarget > ability.range) return;

    if (ability.range > 1.5 && _hasWallInLineOfSight(casterPos, target)) {
      return;
    }

    // Apply skill-based damage bonus
    int finalDamage = ability.damage;
    if (ability.requiredSkillType != null && caster.skills.containsKey(ability.requiredSkillType)) {
      final skillLevel = caster.skills[ability.requiredSkillType]!;
      finalDamage += (skillLevel * 0.5).round(); // Example: +0.5 damage per skill level
    }

    final newProjectile = Projectile(
      startPosition: Point(casterPos.x * GameScreen.cellSize + (caster.size.x * GameScreen.cellSize) / 2, casterPos.y * GameScreen.cellSize + (caster.size.y * GameScreen.cellSize) / 2),
      endPosition: Point(target.x * GameScreen.cellSize + GameScreen.cellSize / 2, target.y * GameScreen.cellSize + GameScreen.cellSize / 2),
      targetCell: target,
      ability: ability.copyWith(damage: finalDamage), // Pass modified damage to projectile
      startTime: DateTime.now(),
      travelTime: const Duration(milliseconds: 500),
    );

    final newProjectiles = List<Projectile>.from(state.projectiles)..add(newProjectile);
    final newCasterMana = caster.mana - ability.manaCost;
    final newAbilityCooldowns = Map<String, DateTime>.from(caster.abilityCooldowns)..[ability.name] = DateTime.now();

    final newCaster = caster.copyWith(mana: newCasterMana, abilityCooldowns: newAbilityCooldowns);
    final newCharacters = List<GameCharacter>.from(state.characters);
    newCharacters[characterIndex] = newCaster;

    state = state.copyWith(characters: newCharacters, projectiles: newProjectiles, clearPending: true);
  }

  void movePlayer(Direction direction) {
    final player = state.characters.first;
    final newPos = _getNewPosition(player.logicalPosition, direction);

    if (!isCellBlocked(newPos.x, newPos.y, size: player.size, movingCharacter: player)) {
      final newPlayer = player.copyWith(logicalPosition: newPos);
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

  bool isCellBlocked(int x, int y, {Point<int> size = const Point(1, 1), GameCharacter? movingCharacter}) {
    for (int i = 0; i < size.y; i++) {
      for (int j = 0; j < size.x; j++) {
        final checkX = x + j;
        final checkY = y + i;

        // Check for grid boundaries and non-traversable terrain
        if (checkY < 0 || checkY >= state.grid.length || checkX < 0 || checkX >= state.grid[checkY].length) {
          return true;
        }
        if (!state.grid[checkY][checkX].isTraversable) {
          return true;
        }

        // Check for other characters
        for (final character in state.characters) {
          if (character == movingCharacter) continue; // Don't collide with self

          for (int charY = 0; charY < character.size.y; charY++) {
            for (int charX = 0; charX < character.size.x; charX++) {
              if (checkX == character.logicalPosition.x + charX && checkY == character.logicalPosition.y + charY) {
                return true; // Collision detected
              }
            }
          }
        }
      }
    }
    return false;
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
