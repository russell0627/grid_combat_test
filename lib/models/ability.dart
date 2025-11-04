import './status_effect.dart';

/// Represents a skill or action a character can perform.
class Ability {
  final String name;
  final double range;
  final double aoeRadius;
  final int damage;
  final int manaCost;
  final StatusEffect? appliesEffect; // Optional effect to apply on hit

  const Ability({
    required this.name,
    required this.range,
    required this.aoeRadius,
    required this.damage,
    this.manaCost = 0,
    this.appliesEffect,
  });
}
