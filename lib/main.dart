import 'dart:math';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/game_controller.dart';
import 'models/direction.dart';
import 'models/game_character.dart';
import 'models/grid_cell.dart'; // Import GridCell to access TerrainType
import 'models/status_effect.dart'; // Import StatusEffect to check for stun
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
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Remove debug flag
      home: const GameScreen(),
    );
  }
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  static const double cellSize = 40.0; // Increased cell size for a larger play area

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
    final gameController = ref.read(gameControllerProvider.notifier);
    final player = ref.read(gameControllerProvider).characters.first;

    if (event is KeyDownEvent) {
      // Handle movement key presses
      if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        gameController.startMoving(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
        gameController.startMoving(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        gameController.startMoving(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        gameController.startMoving(Direction.right);
      }
      // Handle ability hotkeys
      else if (event.logicalKey == LogicalKeyboardKey.digit1) {
        gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Fireball'));
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        gameController.useMeleeAttack();
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        gameController.enterTargetingMode(player.abilities.firstWhere((ability) => ability.name == 'Stun Grenade'));
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        gameController.dash();
      } else if (event.logicalKey == LogicalKeyboardKey.backquote) {
        gameController.toggleDebugMenu();
      }
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      // Handle movement key releases
      if (event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp) {
        gameController.stopMoving(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS || event.logicalKey == LogicalKeyboardKey.arrowDown) {
        gameController.stopMoving(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        gameController.stopMoving(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight) {
        gameController.stopMoving(Direction.right);
      }
      return KeyEventResult.handled;
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
        title: Text('Project Ghost Grid - Level ${gameState.currentLevelIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Controls Guide',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ControlsScreen()));
            },
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate camera offset to keep player centered
            double cameraX = 0.0;
            double cameraY = 0.0;
            if (player != null) {
              cameraX =
                  (constraints.maxWidth / 2) -
                  (player.logicalPosition.x * GameScreen.cellSize + GameScreen.cellSize / 2);
              cameraY =
                  (constraints.maxHeight / 2) -
                  (player.logicalPosition.y * GameScreen.cellSize + GameScreen.cellSize / 2);
            }

            return Stack(
              children: [
                // The main game area, now positioned by the camera
                Positioned(
                  left: cameraX,
                  top: cameraY,
                  child: Container(
                    width: gridWidth,
                    height: gridHeight,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2.0)),
                    child: MouseRegion(
                      onHover: (event) {
                        gameController.updateFacingDirection(Point(event.localPosition.dx, event.localPosition.dy));
                      },
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
                            // Render the terrain grid using a CustomPainter
                            CustomPaint(
                              painter: _TerrainPainter(gameState.grid, GameScreen.cellSize),
                              size: Size(gridWidth, gridHeight),
                            ),

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
                              ...gameState.characters.map(
                                (character) => AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutQuad,
                                  left: character.logicalPosition.x * GameScreen.cellSize,
                                  top: character.logicalPosition.y * GameScreen.cellSize,
                                  width: GameScreen.cellSize * character.size.x,
                                  height: GameScreen.cellSize * character.size.y,
                                  child: Stack(
                                    // <--- Wrapped in a Stack
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: GameScreen.cellSize * character.size.x,
                                            height: GameScreen.cellSize * character.size.y - 10,
                                            decoration: BoxDecoration(
                                              color: character == player ? Colors.blue : Colors.red,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${character.health}',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          if (character == player)
                                            Container(
                                              width: GameScreen.cellSize * character.size.x,
                                              height: 10,
                                              color: Colors.blue[900],
                                              child: FractionallySizedBox(
                                                widthFactor: player.mana / player.maxMana,
                                                child: Container(color: Colors.lightBlueAccent),
                                              ),
                                            ),
                                        ],
                                      ),
                                      // Stunned indicator, now correctly inside the Stack
                                      if (character.isStunned)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.purple.withOpacity(0.5),
                                            child: const Center(child: Icon(Icons.star, color: Colors.white, size: 20)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                            // Render projectiles
                            ...gameState.projectiles.map((projectile) {
                              final curvedProgress = Curves.easeOutQuad.transform(
                                DateTime.now().difference(projectile.startTime).inMilliseconds /
                                    projectile.travelTime.inMilliseconds,
                              );
                              final currentPos = Point(
                                lerpDouble(projectile.startPosition.x, projectile.endPosition.x, curvedProgress) ??
                                    projectile.startPosition.x,
                                lerpDouble(projectile.startPosition.y, projectile.endPosition.y, curvedProgress) ??
                                    projectile.startPosition.y,
                              );
                              return Positioned(
                                left: currentPos.x - 5,
                                // Center the projectile
                                top: currentPos.y - 5,
                                width: 10,
                                height: 10,
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                ),
                              );
                            }),
                          ],
                        ),
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

                // Debug Menu
                if (gameState.isDebugMenuOpen)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.black.withOpacity(0.7),
                      child: Column(
                        children: [
                          const Text('Debug Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                          ElevatedButton(
                            child: const Text('Skip Level'),
                            onPressed: () => gameController.skipLevel(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStandardControls(GameController gameController, GameCharacter? player, bool hasEnemies) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // On-screen movement buttons removed
        const SizedBox(width: 180, height: 180),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasEnemies && player != null)
              ElevatedButton(
                child: const Text('Fireball (1)'),
                onPressed: () => gameController.enterTargetingMode(
                  player.abilities.firstWhere((ability) => ability.name == 'Fireball'),
                ),
              ),
            if (hasEnemies && player != null)
              ElevatedButton(child: const Text('Sword Slash (2)'), onPressed: () => gameController.useMeleeAttack()),
            if (player != null)
              ElevatedButton(
                child: const Text('Stun Grenade (3)'),
                onPressed: () => gameController.enterTargetingMode(
                  player.abilities.firstWhere((ability) => ability.name == 'Stun Grenade'),
                ),
              ),
            if (player != null)
              ElevatedButton(child: const Text('Dash (Space)'), onPressed: () => gameController.dash()),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetingControls(GameController gameController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: const Text('Cancel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => gameController.cancelTargeting(),
        ),
      ],
    );
  }
}

// Custom Painter for the terrain grid
class _TerrainPainter extends CustomPainter {
  final List<List<GridCell>> grid;
  final double cellSize;

  _TerrainPainter(this.grid, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final cell = grid[y][x];
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
        paint.color = color;
        canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // For simplicity, always repaint. Can be optimized.
  }
}
