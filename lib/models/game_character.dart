import 'dart:math';
import '../models/direction.dart';
import './ability.dart';

// Note: The custom Point class has been removed. We now use the Point class from 'dart:math'.

/// Represents a character in the game, like the player or an enemy.
class GameCharacter {
  final Point<int> logicalPosition;
  final int health;
  final List<Ability> abilities;
  final Direction facingDirection;

  GameCharacter({
    required this.logicalPosition,
    this.health = 100,
    this.abilities = const [],
    this.facingDirection = Direction.down, // Default facing direction
  });

  GameCharacter copyWith({
    Point<int>? logicalPosition,
    int? health,
    List<Ability>? abilities,
    Direction? facingDirection,
  }) {
    return GameCharacter(
      logicalPosition: logicalPosition ?? this.logicalPosition,
      health: health ?? this.health,
      abilities: abilities ?? this.abilities,
      facingDirection: facingDirection ?? this.facingDirection,
    );
  }
}
