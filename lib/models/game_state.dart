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
    int width = 30, // Increased from 20
    int height = 30, // Increased from 20
  }) {
    final random = Random();
    final List<List<GridCell>> initialGrid = List.generate(
      height,
      (_) => List.generate(width, (_) => GridCell(terrainType: TerrainType.grass)),
    );

    // --- Generate Water Rivers ---
    int numRivers = random.nextInt(3) + 1; // 1 to 3 rivers
    for (int r = 0; r < numRivers; r++) {
      int startX = random.nextInt(width);
      int startY = random.nextInt(height);
      bool horizontal = random.nextBool(); // Decide if river starts horizontally or vertically

      int currentX = startX;
      int currentY = startY;

      for (int i = 0; i < (horizontal ? width : height); i++) {
        if (currentX >= 0 && currentX < width && currentY >= 0 && currentY < height) {
          initialGrid[currentY][currentX] = GridCell(terrainType: TerrainType.water);
          // Add some width to the river
          if (currentX + 1 < width) initialGrid[currentY][currentX + 1] = GridCell(terrainType: TerrainType.water);
          if (currentY + 1 < height) initialGrid[currentY + 1][currentX] = GridCell(terrainType: TerrainType.water);
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
    final playerInitialPos = const Point<int>(5, 5);
    final enemyInitialPos = const Point<int>(8, 8);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
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
            ),
            Ability(
              name: 'Sword Slash',
              range: 1.5,
              aoeRadius: 0.5,
              damage: 15,
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
