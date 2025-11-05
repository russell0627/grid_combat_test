import 'package:grid_combat_test/models/status_effect.dart';

import './ability.dart';
import './equipment.dart'; // For WeaponSkillType

enum PlayerClassType {
  warrior,
  mage,
}

class PlayerClass {
  final PlayerClassType type;
  final List<Ability> startingAbilities;
  final int baseStrength;
  final int baseDexterity;
  final int baseIntelligence;
  final int baseConstitution;
  final Map<WeaponSkillType, int> startingSkills;

  const PlayerClass({
    required this.type,
    required this.startingAbilities,
    required this.baseStrength,
    required this.baseDexterity,
    required this.baseIntelligence,
    required this.baseConstitution,
    this.startingSkills = const {},
  });

  // Predefined class data
  static final Map<PlayerClassType, PlayerClass> classes = {
    PlayerClassType.warrior: const PlayerClass(
      type: PlayerClassType.warrior,
      startingAbilities: [
        // Warrior abilities will come from equipped weapon
      ],
      baseStrength: 15,
      baseDexterity: 10,
      baseIntelligence: 5,
      baseConstitution: 15,
      startingSkills: {
        WeaponSkillType.oneHandedMelee: 3,
        WeaponSkillType.twoHandedMelee: 1,
        WeaponSkillType.unarmed: 2,
      },
    ),
    PlayerClassType.mage: const PlayerClass(
      type: PlayerClassType.mage,
      startingAbilities: [
        // Mage abilities will come from equipped trinkets
      ],
      baseStrength: 5,
      baseDexterity: 10,
      baseIntelligence: 20,
      baseConstitution: 10,
      startingSkills: {
        WeaponSkillType.magic: 3,
        WeaponSkillType.ranged: 1,
        WeaponSkillType.unarmed: 1,
      },
    ),
  };
}
