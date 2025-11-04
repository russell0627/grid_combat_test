import 'dart:math';

/// Defines the configuration for a single game level or stage.
class GameLevel {
  final int width;
  final int height;
  final Point<int> playerSpawn;
  final List<Point<int>> enemySpawns;
  // Potentially add more properties here for specific terrain layouts, objectives, etc.

  const GameLevel({
    required this.width,
    required this.height,
    required this.playerSpawn,
    required this.enemySpawns,
  });

  // A list of predefined levels
  static final List<GameLevel> allLevels = [
    // Level 1: Simple encounter
    const GameLevel(
      width: 30,
      height: 30,
      playerSpawn: Point(5, 5),
      enemySpawns: [Point(8, 8)],
    ),
    // Level 2: More enemies, different layout
    const GameLevel(
      width: 35,
      height: 35,
      playerSpawn: Point(10, 10),
      enemySpawns: [Point(15, 15), Point(12, 18), Point(18, 12)],
    ),
    // Level 3: Larger map, more complex
    const GameLevel(
      width: 40,
      height: 40,
      playerSpawn: Point(7, 7),
      enemySpawns: [Point(10, 10), Point(20, 20), Point(15, 25), Point(25, 15)],
    ),
    // Add more levels here...
  ];
}
