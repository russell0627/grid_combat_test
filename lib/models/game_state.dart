import 'dart:collection';
import 'dart:math';
import './ability.dart';
import './grid_cell.dart';
import './game_character.dart';
import './projectile.dart';
import './status_effect.dart';
import './game_level.dart';
import '../models/direction.dart';

/// Represents the entire state of the game at a single point in time.
class GameState {
  final List<List<GridCell>> grid;
  final List<GameCharacter> characters;
  final List<Projectile> projectiles;
  final int currentLevelIndex;

  // State for targeting and buffering
  final Ability? targetingAbility;
  final Point<int>? targetingPosition;
  final Ability? pendingAbility;
  final Point<int>? pendingTarget;

  // State for continuous movement
  final HashSet<Direction> activeMoveDirections;

  GameState({
    required this.grid,
    required this.characters,
    required this.currentLevelIndex,
    this.projectiles = const [],
    this.targetingAbility,
    this.targetingPosition,
    this.pendingAbility,
    this.pendingTarget,
    HashSet<Direction>? activeMoveDirections,
  }) : activeMoveDirections = activeMoveDirections ?? HashSet<Direction>();

  factory GameState.initial({
    int currentLevelIndex = 0,
  }) {
    final level = GameLevel.allLevels[currentLevelIndex];
    final random = Random();
    final List<List<GridCell>> initialGrid = List.generate(
      level.height,
      (_) => List.generate(level.width, (_) => GridCell(terrainType: TerrainType.grass)),
    );

    // --- Generate Water Rivers ---
    int numRivers = random.nextInt(3) + 1; // 1 to 3 rivers
    for (int r = 0; r < numRivers; r++) {
      int startX = random.nextInt(level.width);
      int startY = random.nextInt(level.height);
      bool horizontal = random.nextBool(); // Decide if river starts horizontally or vertically

      int currentX = startX;
      int currentY = startY;

      for (int i = 0; i < (horizontal ? level.width : level.height); i++) {
        if (currentX >= 0 && currentX < level.width && currentY >= 0 && currentY < level.height) {
          initialGrid[currentY][currentX] = GridCell(terrainType: TerrainType.water);
          // Add some width to the river
          if (currentX + 1 < level.width) initialGrid[currentY][currentX + 1] = GridCell(terrainType: TerrainType.water);
          if (currentY + 1 < level.height) initialGrid[currentY + 1][currentX] = GridCell(terrainType: TerrainType.water);
        }

        // Move generally straight, with a slight chance to drift
        if (horizontal) {
          currentX++;
          if (random.nextDouble() < 0.3) currentY += (random.nextBool() ? 1 : -1); // Drift up/down
        } else {
          currentY++;
          if (random.nextDouble() < 0.3) currentX += (random.nextBool() ? 1 : -1); // Drift left/right
        }
      }
    }

    // --- Generate Walls ---
    // Ensure walls don't block initial character positions
    final playerInitialPos = level.playerSpawn;
    final enemyInitialPos = level.enemySpawns.first; // For simplicity, use only the first enemy spawn

    for (int y = 0; y < level.height; y++) {
      for (int x = 0; x < level.width; x++) {
        // Avoid placing walls on initial character spawn points
        if ((x == playerInitialPos.x && y == playerInitialPos.y) ||
            (x == enemyInitialPos.x && y == enemyInitialPos.y)) {
          continue;
        }
        // Avoid placing walls on water
        if (initialGrid[y][x].terrainType == TerrainType.water) {
          continue;
        }

        // Low probability for walls
        if (random.nextDouble() < 0.05) { // 5% chance for a wall
          initialGrid[y][x] = GridCell(terrainType: TerrainType.wall);
        }
      }
    }

    return GameState(
      grid: initialGrid,
      characters: [
        // Player
        GameCharacter(
          logicalPosition: playerInitialPos,
          abilities: const [
            Ability(
              name: 'Fireball',
              range: 8,
              aoeRadius: 2.5,
              damage: 25,
              manaCost: 20,
            ),
            Ability(
              name: 'Sword Slash',
              range: 1.5,
              aoeRadius: 0.5,
              damage: 15,
              manaCost: 0, // Now free!
            ),
            Ability(
              name: 'Stun Grenade',
              range: 6,
              aoeRadius: 2.0,
              damage: 0, // No damage
              manaCost: 30,
              appliesEffect: StatusEffect(
                type: EffectType.stun,
                duration: Duration(seconds: 3),
              ),
            ),
          ],
        ),
        // Enemy
        GameCharacter(
          logicalPosition: enemyInitialPos,
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
      currentLevelIndex: currentLevelIndex,
    );
  }

  GameState copyWith({
    List<List<GridCell>>? grid,
    List<GameCharacter>? characters,
    List<Projectile>? projectiles,
    int? currentLevelIndex,
    Ability? targetingAbility,
    Point<int>? targetingPosition,
    bool clearTargeting = false,
    Ability? pendingAbility,
    Point<int>? pendingTarget,
    bool clearPending = false,
    HashSet<Direction>? activeMoveDirections,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      characters: characters ?? this.characters,
      projectiles: projectiles ?? this.projectiles,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      targetingAbility:
          clearTargeting ? null : targetingAbility ?? this.targetingAbility,
      targetingPosition:
          clearTargeting ? null : targetingPosition ?? this.targetingPosition,
      pendingAbility: clearPending ? null : pendingAbility ?? this.pendingAbility,
      pendingTarget: clearPending ? null : pendingTarget ?? this.pendingTarget,
      activeMoveDirections: activeMoveDirections ?? this.activeMoveDirections,
    );
  }
}
