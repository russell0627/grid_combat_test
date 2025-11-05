import 'dart:math';
import '../models/direction.dart';
import './ability.dart';
import './status_effect.dart';
import './player_class.dart';
import './equipment.dart';
import './hit_location.dart';

// Note: The custom Point class has been removed. We now use the Point class from 'dart:math'.

/// Represents a character in the game, like the player or an enemy.
class GameCharacter {
  final Point<int> logicalPosition;
  final Point<int> size;
  final Map<HitLocation, int> healthByLocation;
  final Map<HitLocation, int> maxHealthByLocation;
  final int mana;
  final int maxMana;
  // Abilities are now derived from equipped weapon
  // final List<Ability> abilities;
  final Direction facingDirection;
  final DateTime? lastDashTime;
  final List<StatusEffect> activeEffects;
  final PlayerClass? playerClass; // Nullable for enemies
  final bool isSummon;
  final bool isRanged;
  final Map<EquipmentSlot, Equipment> equipment;

  // New stat properties
  final int strength;
  final int dexterity;
  final int intelligence;
  final int constitution;

  // Skill and Cooldown properties
  final Map<WeaponSkillType, int> skills;
  final Map<String, DateTime> abilityCooldowns;

  GameCharacter({
    required this.logicalPosition,
    this.size = const Point(1, 1), // Default size is 1x1
    required this.healthByLocation,
    required this.maxHealthByLocation,
    this.mana = 50,
    this.maxMana = 50,
    // this.abilities = const [], // Abilities now come from equipment
    this.facingDirection = Direction.down, // Default facing direction
    this.lastDashTime,
    this.activeEffects = const [],
    this.playerClass,
    this.isSummon = false,
    this.isRanged = false,
    this.equipment = const {},
    this.strength = 10,
    this.dexterity = 10,
    this.intelligence = 10,
    this.constitution = 10,
    this.skills = const {},
    this.abilityCooldowns = const {},
  });

  // Derived properties for overall health
  int get health => healthByLocation.values.fold(0, (sum, hp) => sum + hp);
  int get maxHealth => maxHealthByLocation.values.fold(0, (sum, hp) => sum + hp);

  // Derived abilities from equipped weapon and class
  List<Ability> get abilities {
    final List<Ability> currentAbilities = [];
    // Add abilities from equipped weapon
    final mainHand = equipment[EquipmentSlot.mainHand];
    if (mainHand != null) {
      currentAbilities.addAll(mainHand.abilities);
    }
    // Add abilities from off-hand (e.g., shield abilities)
    final offHand = equipment[EquipmentSlot.offHand];
    if (offHand != null) {
      currentAbilities.addAll(offHand.abilities);
    }
    // Add abilities from trinkets
    final trinket1 = equipment[EquipmentSlot.trinket1];
    if (trinket1 != null) {
      currentAbilities.addAll(trinket1.abilities);
    }
    final trinket2 = equipment[EquipmentSlot.trinket2];
    if (trinket2 != null) {
      currentAbilities.addAll(trinket2.abilities);
    }
    final trinket3 = equipment[EquipmentSlot.trinket3];
    if (trinket3 != null) {
      currentAbilities.addAll(trinket3.abilities);
    }

    // Add abilities from class (if any, and not already added by equipment)
    if (playerClass != null) {
      for (final classAbility in playerClass!.startingAbilities) {
        if (!currentAbilities.any((a) => a.name == classAbility.name)) {
          currentAbilities.add(classAbility);
        }
      }
    }
    return currentAbilities;
  }

  bool get isStunned => activeEffects.any((effect) => effect.type == EffectType.stun);

  GameCharacter copyWith({
    Point<int>? logicalPosition,
    Point<int>? size,
    Map<HitLocation, int>? healthByLocation,
    Map<HitLocation, int>? maxHealthByLocation,
    int? mana,
    int? maxMana,
    // List<Ability>? abilities, // No longer copy abilities directly
    Direction? facingDirection,
    DateTime? lastDashTime,
    List<StatusEffect>? activeEffects,
    PlayerClass? playerClass,
    bool? isSummon,
    bool? isRanged,
    Map<EquipmentSlot, Equipment>? equipment,
    int? strength,
    int? dexterity,
    int? intelligence,
    int? constitution,
    Map<WeaponSkillType, int>? skills,
    Map<String, DateTime>? abilityCooldowns,
  }) {
    return GameCharacter(
      logicalPosition: logicalPosition ?? this.logicalPosition,
      size: size ?? this.size,
      healthByLocation: healthByLocation ?? this.healthByLocation,
      maxHealthByLocation: maxHealthByLocation ?? this.maxHealthByLocation,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      // abilities: abilities ?? this.abilities, // No longer copy abilities directly
      facingDirection: facingDirection ?? this.facingDirection,
      lastDashTime: lastDashTime ?? this.lastDashTime,
      activeEffects: activeEffects ?? this.activeEffects,
      playerClass: playerClass ?? this.playerClass,
      isSummon: isSummon ?? this.isSummon,
      isRanged: isRanged ?? this.isRanged,
      equipment: equipment ?? this.equipment,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      intelligence: intelligence ?? this.intelligence,
      constitution: constitution ?? this.constitution,
      skills: skills ?? this.skills,
      abilityCooldowns: abilityCooldowns ?? this.abilityCooldowns,
    );
  }
}
