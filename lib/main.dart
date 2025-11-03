import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/game_controller.dart';
import 'models/direction.dart';
import 'models/game_character.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghost Grid',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const double cellSize = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);
    final player = gameState.characters.isNotEmpty ? gameState.characters.first : null;
    final isTargeting = gameState.targetingAbility != null;

    // Calculate grid dimensions for outlining
    final gridWidth = gameState.grid.isNotEmpty ? gameState.grid[0].length * cellSize : 0.0;
    final gridHeight = gameState.grid.isNotEmpty ? gameState.grid.length * cellSize : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Ghost Grid'),
      ),
      body: Stack(
        children: [
          // The main game area (grid, characters, projectiles)
          Center(
            child: Container(
              width: gridWidth,
              height: gridHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2.0),
              ),
              child: GestureDetector(
                onTapDown: (details) {
                  if (!isTargeting) return;
                  final tapPos = details.localPosition;
                  final gridX = (tapPos.dx / cellSize).floor();
                  final gridY = (tapPos.dy / cellSize).floor();
                  gameController.setTargetPosition(Point(gridX, gridY));
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Render targeting decal
                    if (isTargeting && gameState.targetingPosition != null)
                      Positioned(
                        left: gameState.targetingPosition!.x * cellSize,
                        top: gameState.targetingPosition!.y * cellSize,
                        width: cellSize,
                        height: cellSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Render characters
                    if (player != null)
                      ...gameState.characters.asMap().entries.map((entry) {
                        final character = entry.value;
                        return AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          left: character.logicalPosition.x * cellSize,
                          top: character.logicalPosition.y * cellSize,
                          width: cellSize,
                          height: cellSize,
                          child: Container(
                            color: entry.key == 0 ? Colors.blue : Colors.red,
                            child: Center(
                              child: Text(
                                '${character.health}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      }),

                    // Render projectiles
                    ...gameState.projectiles.map((projectile) {
                      final progress = DateTime.now().difference(projectile.startTime).inMilliseconds / projectile.travelTime.inMilliseconds;
                      final currentPos = Point(
                        lerpDouble(projectile.startPosition.x, projectile.endPosition.x, progress)!,
                        lerpDouble(projectile.startPosition.y, projectile.endPosition.y, progress)!
                      );
                      return Positioned(
                        left: currentPos.x - 5, // Center the projectile
                        top: currentPos.y - 5,
                        width: 10,
                        height: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Controls overlaid on top of the game area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surfaceVariant, // Use theme color or default
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: isTargeting
                  ? _buildTargetingControls(gameController)
                  : _buildStandardControls(gameController, player, gameState.characters.length > 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardControls(GameController gameController, GameCharacter? player, bool hasEnemies) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(message: 'Move Up-Left', child: IconButton(icon: const Icon(Icons.north_west), onPressed: () => gameController.movePlayer(Direction.upLeft))),
                  Tooltip(message: 'Move Up', child: IconButton(icon: const Icon(Icons.north), onPressed: () => gameController.movePlayer(Direction.up))),
                  Tooltip(message: 'Move Up-Right', child: IconButton(icon: const Icon(Icons.north_east), onPressed: () => gameController.movePlayer(Direction.upRight))),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(message: 'Move Left', child: IconButton(icon: const Icon(Icons.west), onPressed: () => gameController.movePlayer(Direction.left))),
                  const SizedBox(width: 48, height: 48), // Center empty space, matching IconButton size
                  Tooltip(message: 'Move Right', child: IconButton(icon: const Icon(Icons.east), onPressed: () => gameController.movePlayer(Direction.right))),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(message: 'Move Down-Left', child: IconButton(icon: const Icon(Icons.south_west), onPressed: () => gameController.movePlayer(Direction.downLeft))),
                  Tooltip(message: 'Move Down', child: IconButton(icon: const Icon(Icons.south), onPressed: () => gameController.movePlayer(Direction.down))),
                  Tooltip(message: 'Move Down-Right', child: IconButton(icon: const Icon(Icons.south_east), onPressed: () => gameController.movePlayer(Direction.downRight))),
                ],
              ),
            ],
          ),
        ),
        if (hasEnemies && player != null)
          ElevatedButton(
            child: const Text('Fireball'),
            onPressed: () => gameController.enterTargetingMode(player.abilities.first),
          ),
      ],
    );
  }

  Widget _buildTargetingControls(GameController gameController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: const Text('Confirm'),
          onPressed: () => gameController.confirmTarget(),
        ),
        ElevatedButton(
          child: const Text('Cancel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => gameController.cancelTargeting(),
        ),
      ],
    );
  }
}
