import './status_effect.dart';
import './hit_location.dart';
import './equipment.dart'; // For WeaponSkillType

/// Represents a skill or action a character can perform.
class Ability {
  final String name;
  final double range;
  final double aoeRadius;
  final int damage;
  final int manaCost;
  final StatusEffect? appliesEffect; // Optional effect to apply on hit
  final bool isHeal;
  final List<HitLocation> targetLocations; // Which body parts this attack can hit
  final Duration cooldownDuration; // How long until the ability can be used again
  final WeaponSkillType? requiredSkillType; // What skill type is required/boosts this ability

  const Ability({
    required this.name,
    required this.range,
    required this.aoeRadius,
    required this.damage,
    this.manaCost = 0,
    this.appliesEffect,
    this.isHeal = false,
    this.targetLocations = const [HitLocation.torso], // Default to torso
    this.cooldownDuration = Duration.zero,
    this.requiredSkillType,
  });

  Ability copyWith({
    String? name,
    double? range,
    double? aoeRadius,
    int? damage,
    int? manaCost,
    StatusEffect? appliesEffect,
    bool? isHeal,
    List<HitLocation>? targetLocations,
    Duration? cooldownDuration,
    WeaponSkillType? requiredSkillType,
  }) {
    return Ability(
      name: name ?? this.name,
      range: range ?? this.range,
      aoeRadius: aoeRadius ?? this.aoeRadius,
      damage: damage ?? this.damage,
      manaCost: manaCost ?? this.manaCost,
      appliesEffect: appliesEffect ?? this.appliesEffect,
      isHeal: isHeal ?? this.isHeal,
      targetLocations: targetLocations ?? this.targetLocations,
      cooldownDuration: cooldownDuration ?? this.cooldownDuration,
      requiredSkillType: requiredSkillType ?? this.requiredSkillType,
    );
  }
}
