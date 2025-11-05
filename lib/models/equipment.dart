import './ability.dart';
import './status_effect.dart';

enum EquipmentSlot {
  head,
  chest,
  arms,
  legs,
  mainHand,
  offHand,
  trinket1,
  trinket2,
  trinket3,
}

enum EquipmentType {
  helmet,
  armor,
  gauntlets,
  greaves,
  sword,
  staff,
  shield,
  axe,
  twoHandedAxe,
  mace,
  trinket,
}

enum WeaponSkillType {
  oneHandedMelee,
  twoHandedMelee,
  ranged,
  magic,
  unarmed,
}

class Equipment {
  final String name;
  final EquipmentSlot slot;
  final EquipmentType type;
  final int armorValue; // Damage absorption
  final List<Ability> abilities;
  final WeaponSkillType? grantsSkill; // What skill this weapon uses/grants

  const Equipment({
    required this.name,
    required this.slot,
    required this.type,
    this.armorValue = 0,
    this.abilities = const [],
    this.grantsSkill,
  });

  // Predefined Items
  static final Map<String, Equipment> items = {
    // --- Iron Tier ---
    'Iron Helmet': const Equipment(
      name: 'Iron Helmet',
      slot: EquipmentSlot.head,
      type: EquipmentType.helmet,
      armorValue: 5,
    ),
    'Iron Armor': const Equipment(
      name: 'Iron Armor',
      slot: EquipmentSlot.chest,
      type: EquipmentType.armor,
      armorValue: 10,
    ),
    'Iron Gauntlets': const Equipment(
      name: 'Iron Gauntlets',
      slot: EquipmentSlot.arms,
      type: EquipmentType.gauntlets,
      armorValue: 3,
    ),
    'Iron Greaves': const Equipment(
      name: 'Iron Greaves',
      slot: EquipmentSlot.legs,
      type: EquipmentType.greaves,
      armorValue: 7,
    ),

    // --- Leather Tier ---
    'Leather Cap': const Equipment(
      name: 'Leather Cap',
      slot: EquipmentSlot.head,
      type: EquipmentType.helmet,
      armorValue: 2,
    ),
    'Leather Tunic': const Equipment(
      name: 'Leather Tunic',
      slot: EquipmentSlot.chest,
      type: EquipmentType.armor,
      armorValue: 4,
    ),
    'Leather Bracers': const Equipment(
      name: 'Leather Bracers',
      slot: EquipmentSlot.arms,
      type: EquipmentType.gauntlets,
      armorValue: 1,
    ),
    'Leather Pants': const Equipment(
      name: 'Leather Pants',
      slot: EquipmentSlot.legs,
      type: EquipmentType.greaves,
      armorValue: 3,
    ),

    // --- Cloth Tier ---
    'Cloth Hood': const Equipment(
      name: 'Cloth Hood',
      slot: EquipmentSlot.head,
      type: EquipmentType.helmet,
      armorValue: 1,
    ),
    'Cloth Robe': const Equipment(
      name: 'Cloth Robe',
      slot: EquipmentSlot.chest,
      type: EquipmentType.armor,
      armorValue: 2,
    ),
    'Cloth Wraps': const Equipment(
      name: 'Cloth Wraps',
      slot: EquipmentSlot.arms,
      type: EquipmentType.gauntlets,
      armorValue: 0,
    ),
    'Cloth Pants': const Equipment(
      name: 'Cloth Pants',
      slot: EquipmentSlot.legs,
      type: EquipmentType.greaves,
      armorValue: 1,
    ),

    // --- Weapons ---
    'Iron Sword': const Equipment(
      name: 'Iron Sword',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.sword,
      grantsSkill: WeaponSkillType.oneHandedMelee,
      abilities: [
        Ability(
          name: 'Sword Slash',
          range: 1.5,
          aoeRadius: 0.5,
          damage: 15,
          manaCost: 0,
          cooldownDuration: Duration(seconds: 1),
          requiredSkillType: WeaponSkillType.oneHandedMelee,
        ),
      ],
    ),
    'Fire Staff': const Equipment(
      name: 'Fire Staff',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.staff,
      grantsSkill: WeaponSkillType.magic,
      abilities: [
        Ability(
          name: 'Fireball',
          range: 8,
          aoeRadius: 2.5,
          damage: 25,
          manaCost: 20,
          cooldownDuration: Duration(seconds: 2),
          requiredSkillType: WeaponSkillType.magic,
        ),
      ],
    ),
    'Wooden Shield': const Equipment(
      name: 'Wooden Shield',
      slot: EquipmentSlot.offHand,
      type: EquipmentType.shield,
      armorValue: 5,
    ),
    'Battle Axe': const Equipment(
      name: 'Battle Axe',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.axe,
      grantsSkill: WeaponSkillType.oneHandedMelee,
      abilities: [
        Ability(
          name: 'Axe Chop',
          range: 1.5,
          aoeRadius: 0.5,
          damage: 20,
          manaCost: 0,
          cooldownDuration: Duration(seconds: 1),
          requiredSkillType: WeaponSkillType.oneHandedMelee,
        ),
      ],
    ),
    'Great Axe': const Equipment(
      name: 'Great Axe',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.twoHandedAxe,
      grantsSkill: WeaponSkillType.twoHandedMelee,
      abilities: [
        Ability(
          name: 'Great Cleave',
          range: 2.0,
          aoeRadius: 1.0,
          damage: 30,
          manaCost: 10,
          cooldownDuration: Duration(seconds: 3),
          requiredSkillType: WeaponSkillType.twoHandedMelee,
        ),
      ],
    ),
    'War Mace': const Equipment(
      name: 'War Mace',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.mace,
      grantsSkill: WeaponSkillType.oneHandedMelee,
      abilities: [
        Ability(
          name: 'Mace Bash',
          range: 1.5,
          aoeRadius: 0.5,
          damage: 18,
          manaCost: 0,
          appliesEffect: StatusEffect(type: EffectType.stun, duration: Duration(seconds: 1)),
          cooldownDuration: Duration(seconds: 2),
          requiredSkillType: WeaponSkillType.oneHandedMelee,
        ),
      ],
    ),
    'Minion Claw': const Equipment(
      name: 'Minion Claw',
      slot: EquipmentSlot.mainHand,
      type: EquipmentType.sword, // Placeholder type for minion attack
      grantsSkill: WeaponSkillType.unarmed,
      abilities: [
        Ability(
          name: 'Minion Attack',
          range: 1.5,
          aoeRadius: 0.5,
          damage: 15,
          cooldownDuration: Duration(milliseconds: 500),
          requiredSkillType: WeaponSkillType.unarmed,
        ),
      ],
    ),

    // --- Trinkets ---
    'Mana Amulet': const Equipment(
      name: 'Mana Amulet',
      slot: EquipmentSlot.trinket1,
      type: EquipmentType.trinket,
      abilities: [
        Ability(
          name: 'Stun Grenade',
          range: 6,
          aoeRadius: 2.0,
          damage: 0,
          manaCost: 30,
          appliesEffect: StatusEffect(type: EffectType.stun, duration: Duration(seconds: 3)),
          cooldownDuration: Duration(seconds: 5),
          requiredSkillType: WeaponSkillType.magic,
        ),
      ],
    ),
    'Summoning Stone': const Equipment(
      name: 'Summoning Stone',
      slot: EquipmentSlot.trinket2,
      type: EquipmentType.trinket,
      abilities: [
        Ability(
          name: 'Summon Minion',
          range: 4,
          aoeRadius: 0.5,
          damage: 0,
          manaCost: 40,
          cooldownDuration: Duration(seconds: 10),
          requiredSkillType: WeaponSkillType.magic,
        ),
      ],
    ),
    'Health Charm': const Equipment(
      name: 'Health Charm',
      slot: EquipmentSlot.trinket3,
      type: EquipmentType.trinket,
      armorValue: 2, // Example: small armor bonus
    ),
  };
}
