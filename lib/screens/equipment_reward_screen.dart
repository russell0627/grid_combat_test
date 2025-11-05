import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/game_controller.dart';
import '../models/equipment.dart';
import '../models/player_class.dart';

class EquipmentRewardScreen extends ConsumerWidget {
  final Equipment newEquipment;
  final PlayerClassType selectedClass;

  const EquipmentRewardScreen({
    super.key,
    required this.newEquipment,
    required this.selectedClass,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameController = ref.read(gameControllerProvider(selectedClass).notifier);
    final player = ref.watch(gameControllerProvider(selectedClass)).characters.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Equipment Found!'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You found a ${newEquipment.name}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${newEquipment.name}', style: Theme.of(context).textTheme.titleLarge),
                    Text('Slot: ${newEquipment.slot.name}'),
                    Text('Type: ${newEquipment.type.name}'),
                    if (newEquipment.armorValue > 0) Text('Armor: ${newEquipment.armorValue}'),
                    if (newEquipment.abilities.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Abilities Granted:'),
                          ...newEquipment.abilities.map((ability) => Text('- ${ability.name}')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    gameController.equipItem(newEquipment); // Implement this in GameController
                    Navigator.of(context).pop(); // Go back to game screen
                  },
                  child: const Text('Equip'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to game screen
                  },
                  child: const Text('Discard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
