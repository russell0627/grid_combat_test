import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/game_controller.dart';
import 'models/direction.dart';
import 'models/game_character.dart';
import 'models/grid_cell.dart'; // Import GridCell to access TerrainType
import 'screens/controls_screen.dart';

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

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static const double cellSize = 30.0;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final gameController = ref.read(gameControllerProvider.notifier);
      final player = ref.read(gameControllerProvider).characters.first;
      Direction? direction;

      // Check for combined diagonal inputs first
      if ((event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) &&
          (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
        direction = Direction.upLeft;
      } else if ((event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) &&
                 (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight)) {
        direction = Direction.upRight;
      } else if ((event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) &&
                 (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
        direction = Direction.downLeft;
      } else if ((event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) &&
                 (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight)) {
        direction = Direction.downRight;
      }
      // Then check for cardinal inputs
      else if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        direction = Direction.up;
      } else if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
        direction = Direction.down;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        direction = Direction.left;
      } else if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        direction = Direction.right;
      }
      // Check for ability hotkeys
      else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Fireball'));
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Sword Slash'));
        return KeyEventResult.handled;
      }

      if (direction != null) {
        gameController.movePlayer(direction);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.skipRemainingHandlers;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);
    final player = gameState.characters.isNotEmpty ? gameState.characters.first : null;
    final isTargeting = gameState.targetingAbility != null;

    // Calculate grid dimensions for outlining
    final gridWidth = gameState.grid.isNotEmpty ? gameState.grid[0].length * GameScreen.cellSize : 0.0;
    final gridHeight = gameState.grid.isNotEmpty ? gameState.grid.length * GameScreen.cellSize : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Ghost Grid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Controls Guide',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ControlsScreen()),
              );
            },
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: Stack(
          children: [
            // Render the terrain grid
            Positioned.fill(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gameState.grid.isNotEmpty ? gameState.grid[0].length : 1,
                  childAspectRatio: 1.0,
                ),
                itemCount: gameState.grid.length * (gameState.grid.isNotEmpty ? gameState.grid[0].length : 0),
                itemBuilder: (context, index) {
                  final y = index ~/ (gameState.grid.isNotEmpty ? gameState.grid[0].length : 1);
                  final x = index % (gameState.grid.isNotEmpty ? gameState.grid[0].length : 1);
                  final cell = gameState.grid[y][x];

                  Color color;
                  switch (cell.terrainType) {
                    case TerrainType.grass:
                      color = Colors.green[700]!;
                      break;
                    case TerrainType.water:
                      color = Colors.blue[700]!;
                      break;
                    case TerrainType.wall:
                      color = Colors.brown[700]!;
                      break;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.black12, width: 0.5),
                    ),
                  );
                },
              ),
            ),

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
                    final gridX = (tapPos.dx / GameScreen.cellSize).floor();
                    final gridY = (tapPos.dy / GameScreen.cellSize).floor();
                    gameController.setTargetPosition(Point(gridX, gridY));
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Render targeting decal
                      if (isTargeting && gameState.targetingPosition != null)
                        Positioned(
                          left: gameState.targetingPosition!.x * GameScreen.cellSize,
                          top: gameState.targetingPosition!.y * GameScreen.cellSize,
                          width: GameScreen.cellSize,
                          height: GameScreen.cellSize,
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
                            left: character.logicalPosition.x * GameScreen.cellSize,
                            top: character.logicalPosition.y * GameScreen.cellSize,
                            width: GameScreen.cellSize,
                            height: GameScreen.cellSize,
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
                        final curvedProgress = Curves.easeOutQuad.transform(DateTime.now().difference(projectile.startTime).inMilliseconds / projectile.travelTime.inMilliseconds);
                        final currentPos = Point(
                          lerpDouble(projectile.startPosition.x, projectile.endPosition.x, curvedProgress)!,
                          lerpDouble(projectile.startPosition.y, projectile.endPosition.y, curvedProgress)!
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
                color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: isTargeting
                    ? _buildTargetingControls(gameController)
                    : _buildStandardControls(gameController, player, gameState.characters.length > 1),
              ),
            ),
          ],
        ),
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
                  const SizedBox(width: 48, height: 48),
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
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasEnemies && player != null)
              ElevatedButton(
                child: const Text('Fireball (1)'),
                onPressed: () => gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Fireball')),
              ),
            if (hasEnemies && player != null)
              ElevatedButton(
                child: const Text('Sword Slash (2)'),
                onPressed: () => gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Sword Slash')),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetingControls(GameController gameController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Removed Confirm button
        ElevatedButton(
          child: const Text('Cancel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => gameController.cancelTargeting(),
        ),
      ],
    );
  }
}
