import 'dart:math';
import './ability.dart';
import './grid_cell.dart';
import './game_character.dart';
import './projectile.dart';

/// Represents the entire state of the game at a single point in time.
class GameState {
  final List<List<GridCell>> grid;
  final List<GameCharacter> characters;
  final List<Projectile> projectiles;

  // State for targeting and buffering
  final Ability? targetingAbility;
  final Point<int>? targetingPosition;
  final Ability? pendingAbility;
  final Point<int>? pendingTarget;

  GameState({
    required this.grid,
    required this.characters,
    this.projectiles = const [],
    this.targetingAbility,
    this.targetingPosition,
    this.pendingAbility,
    this.pendingTarget,
  });

  factory GameState.initial({
    int width = 20,
    int height = 20,
  }) {
    return GameState(
      grid: List.generate(
        height,
        (_) => List.generate(width, (_) => GridCell()),
      ),
      characters: [
        GameCharacter(
          logicalPosition: const Point(5, 5),
          abilities: const [
            Ability(
              name: 'Fireball',
              range: 8,
              aoeRadius: 2.5,
              damage: 25,
            ),
          ],
        ),
        GameCharacter(
          logicalPosition: const Point(8, 8),
          abilities: const [
            Ability(
              name: 'Claw',
              range: 1.5,
              aoeRadius: 0.5,
              damage: 10,
            ),
          ],
        ),
      ],
    );
  }

  GameState copyWith({
    List<List<GridCell>>? grid,
    List<GameCharacter>? characters,
    List<Projectile>? projectiles,
    Ability? targetingAbility,
    Point<int>? targetingPosition,
    bool clearTargeting = false,
    Ability? pendingAbility,
    Point<int>? pendingTarget,
    bool clearPending = false,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      characters: characters ?? this.characters,
      projectiles: projectiles ?? this.projectiles,
      targetingAbility:
          clearTargeting ? null : targetingAbility ?? this.targetingAbility,
      targetingPosition:
          clearTargeting ? null : targetingPosition ?? this.targetingPosition,
      pendingAbility: clearPending ? null : pendingAbility ?? this.pendingAbility,
      pendingTarget: clearPending ? null : pendingTarget ?? this.pendingTarget,
    );
  }
}
