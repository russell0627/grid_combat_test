import 'dart:math';
import './ability.dart';
import './grid_cell.dart';
import './game_character.dart';

/// Represents the entire state of the game at a single point in time.
class GameState {
  final List<List<GridCell>> grid;
  final List<GameCharacter> characters;

  // State for the "Projected Decal" targeting mode
  final Ability? targetingAbility;
  final Point<int>? targetingPosition;

  // State for "Buffered Actions"
  final Ability? pendingAbility;
  final Point<int>? pendingTarget;

  GameState({
    required this.grid,
    required this.characters,
    this.targetingAbility,
    this.targetingPosition,
    this.pendingAbility,
    this.pendingTarget,
  });

  // A factory constructor for the initial state of the game.
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
        // Player
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
        // Enemy
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
      targetingAbility:
          clearTargeting ? null : targetingAbility ?? this.targetingAbility,
      targetingPosition:
          clearTargeting ? null : targetingPosition ?? this.targetingPosition,
      pendingAbility: clearPending ? null : pendingAbility ?? this.pendingAbility,
      pendingTarget: clearPending ? null : pendingTarget ?? this.pendingTarget,
    );
  }
}
