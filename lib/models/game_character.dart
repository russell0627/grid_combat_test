import 'dart:math';
import '../models/direction.dart';
import './ability.dart';
import './status_effect.dart';

// Note: The custom Point class has been removed. We now use the Point class from 'dart:math'.

/// Represents a character in the game, like the player or an enemy.
class GameCharacter {
  final Point<int> logicalPosition;
  final int health;
  final int maxHealth;
  final int mana;
  final int maxMana;
  final List<Ability> abilities;
  final Direction facingDirection;
  final DateTime? lastDashTime;
  final List<StatusEffect> activeEffects;

  GameCharacter({
    required this.logicalPosition,
    this.health = 100,
    this.maxHealth = 100,
    this.mana = 50,
    this.maxMana = 50,
    this.abilities = const [],
    this.facingDirection = Direction.down, // Default facing direction
    this.lastDashTime,
    this.activeEffects = const [],
  });

  bool get isStunned => activeEffects.any((effect) => effect.type == EffectType.stun);

  GameCharacter copyWith({
    Point<int>? logicalPosition,
    int? health,
    int? maxHealth,
    int? mana,
    int? maxMana,
    List<Ability>? abilities,
    Direction? facingDirection,
    DateTime? lastDashTime,
    List<StatusEffect>? activeEffects,
  }) {
    return GameCharacter(
      logicalPosition: logicalPosition ?? this.logicalPosition,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      abilities: abilities ?? this.abilities,
      facingDirection: facingDirection ?? this.facingDirection,
      lastDashTime: lastDashTime ?? this.lastDashTime,
      activeEffects: activeEffects ?? this.activeEffects,
    );
  }
}
