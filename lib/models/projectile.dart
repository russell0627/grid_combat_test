import 'dart:math';
import './ability.dart';

/// Represents a projectile in flight.
class Projectile {
  // The visual starting point in pixels.
  final Point<double> startPosition;
  // The visual ending point in pixels.
  final Point<double> endPosition;

  // The logical grid cell the projectile is aimed at.
  final Point<int> targetCell;

  // The ability that was fired, containing damage and AoE info.
  final Ability ability;

  // Timestamps to calculate progress.
  final DateTime startTime;
  final Duration travelTime;

  const Projectile({
    required this.startPosition,
    required this.endPosition,
    required this.targetCell,
    required this.ability,
    required this.startTime,
    required this.travelTime,
  });
}
