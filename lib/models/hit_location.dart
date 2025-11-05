enum HitLocation {
  head,
  torso,
  arms,
  legs,
}

class DamageModifier {
  final HitLocation location;
  final double multiplier;

  const DamageModifier({
    required this.location,
    required this.multiplier,
  });

  static const Map<HitLocation, DamageModifier> modifiers = {
    HitLocation.head: DamageModifier(location: HitLocation.head, multiplier: 1.5), // Headshots deal more damage
    HitLocation.torso: DamageModifier(location: HitLocation.torso, multiplier: 1.0), // Torso is standard
    HitLocation.arms: DamageModifier(location: HitLocation.arms, multiplier: 0.8), // Arm shots deal less damage
    HitLocation.legs: DamageModifier(location: HitLocation.legs, multiplier: 0.8), // Leg shots deal less damage
  };
}
