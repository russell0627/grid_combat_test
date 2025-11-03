/// Represents a skill or action a character can perform.
class Ability {
  final String name;
  final double range; // How far from the user it can be targeted.
  final double aoeRadius; // The radius of the effect from the target point.
  final int damage;

  const Ability({
    required this.name,
    required this.range,
    required this.aoeRadius,
    required this.damage,
  });
}
