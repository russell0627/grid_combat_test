import 'dart:math';
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
    final player = gameState.characters.first;
    final isTargeting = gameState.targetingAbility != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Ghost Grid'),
      ),
      body: GestureDetector(
        onTapDown: (details) {
          if (!isTargeting) return;
          final tapPos = details.localPosition;
          final gridX = (tapPos.dx / cellSize).floor();
          final gridY = (tapPos.dy / cellSize).floor();
          gameController.setTargetPosition(Point(gridX, gridY));
        },
        child: Stack(
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
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: isTargeting
            ? _buildTargetingControls(gameController)
            : _buildStandardControls(gameController, player, gameState.characters.length > 1),
      ),
    );
  }

  Widget _buildStandardControls(GameController gameController, GameCharacter player, bool hasEnemies) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: 150,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            children: [
              IconButton(icon: const Icon(Icons.north_west), onPressed: () => gameController.movePlayer(Direction.upLeft)),
              IconButton(icon: const Icon(Icons.north), onPressed: () => gameController.movePlayer(Direction.up)),
              IconButton(icon: const Icon(Icons.north_east), onPressed: () => gameController.movePlayer(Direction.upRight)),
              IconButton(icon: const Icon(Icons.west), onPressed: () => gameController.movePlayer(Direction.left)),
              const SizedBox(),
              IconButton(icon: const Icon(Icons.east), onPressed: () => gameController.movePlayer(Direction.right)),
              IconButton(icon: const Icon(Icons.south_west), onPressed: () => gameController.movePlayer(Direction.downLeft)),
              IconButton(icon: const Icon(Icons.south), onPressed: () => gameController.movePlayer(Direction.down)),
              IconButton(icon: const Icon(Icons.south_east), onPressed: () => gameController.movePlayer(Direction.downRight)),
            ],
          ),
        ),
        if (hasEnemies)
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
