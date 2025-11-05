import 'package:flutter/material.dart';
import '../models/player_class.dart';
import '../main.dart';

class ClassSelectionScreen extends StatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  State<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends State<ClassSelectionScreen> {
  PlayerClassType? _selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Class'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...PlayerClass.classes.values.map((playerClass) {
              // Calculate derived stats for display
              final int derivedMaxHealth = playerClass.baseConstitution * 10;
              final int derivedMaxMana = playerClass.baseIntelligence * 5;

              return Card(
                color: _selectedClass == playerClass.type ? Colors.deepPurple.withOpacity(0.5) : null,
                child: ListTile(
                  title: Text(playerClass.type.toString().split('.').last.toUpperCase()),
                  subtitle: Text(
                      'HP: $derivedMaxHealth, Mana: $derivedMaxMana | Str: ${playerClass.baseStrength}, Dex: ${playerClass.baseDexterity}, Int: ${playerClass.baseIntelligence}, Con: ${playerClass.baseConstitution}'),
                  onTap: () {
                    setState(() {
                      _selectedClass = playerClass.type;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedClass == null
                  ? null
                  : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => GameScreen(selectedClass: _selectedClass!),
                        ),
                      );
                    },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}
