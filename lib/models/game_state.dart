import 'dart:collection';
import 'dart:math';
import './ability.dart';
import './grid_cell.dart';
import './game_character.dart';
import './projectile.dart';
import './status_effect.dart';
import './game_level.dart';
import './player_class.dart';
import './equipment.dart';
import './hit_location.dart';
import '../models/direction.dart';

/// Represents the entire state of the game at a single point in time.
class GameState {
  final List<List<GridCell>> grid;
  final List<GameCharacter> characters;
  final List<Projectile> projectiles;
  final int currentLevelIndex;
  final bool isDebugMenuOpen;

  // State for targeting and buffering
  final Ability? targetingAbility;
  final Point<int>? targetingPosition;
  final Ability? pendingAbility;
  final Point<int>? pendingTarget;

  // State for continuous movement
  final HashSet<Direction> activeMoveDirections;

  GameState({
    required this.grid,
    required this.characters,
    required this.currentLevelIndex,
    this.projectiles = const [],
    this.targetingAbility,
    this.targetingPosition,
    this.pendingAbility,
    this.pendingTarget,
    this.isDebugMenuOpen = false,
    HashSet<Direction>? activeMoveDirections,
  }) : activeMoveDirections = activeMoveDirections ?? HashSet<Direction>();

  factory GameState.initial({
    int currentLevelIndex = 0,
    PlayerClassType selectedClass = PlayerClassType.warrior,
  }) {
    final level = GameLevel.allLevels[currentLevelIndex];
    final playerClass = PlayerClass.classes[selectedClass]!;
    final random = Random();
    final List<List<GridCell>> initialGrid = List.generate(
      level.height,
      (_) => List.generate(level.width, (_) => GridCell(terrainType: TerrainType.grass)),
    );

    // --- Generate Water Rivers ---
    int numRivers = random.nextInt(3) + 1; // 1 to 3 rivers
    for (int r = 0; r < numRivers; r++) {
      int startX = random.nextInt(level.width);
      int startY = random.nextInt(level.height);
      bool horizontal = random.nextBool(); // Decide if river starts horizontally or vertically

      int currentX = startX;
      int currentY = startY;

      for (int i = 0; i < (horizontal ? level.width : level.height); i++) {
        if (currentX >= 0 && currentX < level.width && currentY >= 0 && currentY < level.height) {
          initialGrid[currentY][currentX] = GridCell(terrainType: TerrainType.water);
          // Add some width to the river
          if (currentX + 1 < level.width) initialGrid[currentY][currentX + 1] = GridCell(terrainType: TerrainType.water);
          if (currentY + 1 < level.height) initialGrid[currentY + 1][currentX] = GridCell(terrainType: TerrainType.water);
        }

        // Move generally straight, with a slight chance to drift
        if (horizontal) {
          currentX++;
          if (random.nextDouble() < 0.3) currentY += (random.nextBool() ? 1 : -1); // Drift up/down
        } else {
          currentY++;
          if (random.nextDouble() < 0.3) currentX += (random.nextBool() ? 1 : -1); // Drift left/right
        }
      }
    }

    // --- Generate Walls ---
    // Ensure walls don't block initial character positions
    final playerInitialPos = level.playerSpawn;

    for (int y = 0; y < level.height; y++) {
      for (int x = 0; x < level.width; x++) {
        // Avoid placing walls on initial character spawn points
        if ((x == playerInitialPos.x && y == playerInitialPos.y) ||
            level.enemySpawns.any((spawn) => spawn.x == x && spawn.y == y)) {
          continue;
        }
        // Avoid placing walls on water
        if (initialGrid[y][x].terrainType == TerrainType.water) {
          continue;
        }

        // Low probability for walls
        if (random.nextDouble() < 0.05) { // 5% chance for a wall
          initialGrid[y][x] = GridCell(terrainType: TerrainType.wall);
        }
      }
    }

    // Determine initial player equipment based on class
    final Map<EquipmentSlot, Equipment> playerEquipment = {};
    if (selectedClass == PlayerClassType.warrior) {
      playerEquipment[EquipmentSlot.mainHand] = Equipment.items['Iron Sword']!;
      playerEquipment[EquipmentSlot.offHand] = Equipment.items['Wooden Shield']!;
      playerEquipment[EquipmentSlot.chest] = Equipment.items['Leather Tunic']!;
      playerEquipment[EquipmentSlot.head] = Equipment.items['Leather Cap']!;
      playerEquipment[EquipmentSlot.arms] = Equipment.items['Leather Bracers']!;
      playerEquipment[EquipmentSlot.legs] = Equipment.items['Leather Pants']!;
    } else if (selectedClass == PlayerClassType.mage) {
      playerEquipment[EquipmentSlot.mainHand] = Equipment.items['Fire Staff']!;
      playerEquipment[EquipmentSlot.trinket1] = Equipment.items['Mana Amulet']!;
      playerEquipment[EquipmentSlot.trinket2] = Equipment.items['Summoning Stone']!;
      playerEquipment[EquipmentSlot.head] = Equipment.items['Cloth Hood']!;
      playerEquipment[EquipmentSlot.chest] = Equipment.items['Cloth Robe']!;
      playerEquipment[EquipmentSlot.arms] = Equipment.items['Cloth Wraps']!;
      playerEquipment[EquipmentSlot.legs] = Equipment.items['Cloth Pants']!;
    }

    // Calculate initial player health based on Constitution
    final int playerTotalMaxHealth = playerClass.baseConstitution * 10; // Example: 10 HP per Constitution
    final Map<HitLocation, int> playerMaxHealthByLocation = {
      HitLocation.head: playerTotalMaxHealth ~/ 4,
      HitLocation.torso: playerTotalMaxHealth ~/ 2,
      HitLocation.arms: playerTotalMaxHealth ~/ 8,
      HitLocation.legs: playerTotalMaxHealth ~/ 8,
    };
    final Map<HitLocation, int> playerHealthByLocation = Map<HitLocation, int>.from(playerMaxHealthByLocation);

    // Calculate initial player mana based on Intelligence
    final int playerMaxMana = playerClass.baseIntelligence * 5; // Example: 5 Mana per Intelligence

    return GameState(
      grid: initialGrid,
      characters: [
        // Player
        GameCharacter(
          logicalPosition: playerInitialPos,
          playerClass: playerClass,
          healthByLocation: playerHealthByLocation,
          maxHealthByLocation: playerMaxHealthByLocation,
          mana: playerMaxMana,
          maxMana: playerMaxMana,
          equipment: playerEquipment,
          strength: playerClass.baseStrength,
          dexterity: playerClass.baseDexterity,
          intelligence: playerClass.baseIntelligence,
          constitution: playerClass.baseConstitution,
          skills: playerClass.startingSkills, // Initialize skills
        ),
        // Enemies
        ...level.enemySpawns.asMap().entries.map((entry) {
          final index = entry.key;
          final spawn = entry.value;

          // Default enemy stats (can be customized per enemy type later)
          final enemyBaseHealth = 50;
          final Map<HitLocation, int> enemyMaxHealthByLocation = {
            HitLocation.head: enemyBaseHealth ~/ 4,
            HitLocation.torso: enemyBaseHealth ~/ 2,
            HitLocation.arms: enemyBaseHealth ~/ 8,
            HitLocation.legs: enemyBaseHealth ~/ 8,
          };
          final Map<HitLocation, int> enemyHealthByLocation = Map<HitLocation, int>.from(enemyMaxHealthByLocation);

          if (currentLevelIndex == 1 && index == 0) {
            return GameCharacter(
              logicalPosition: spawn,
              size: const Point(2, 2),
              healthByLocation: {
                HitLocation.head: 50,
                HitLocation.torso: 100,
                HitLocation.arms: 25,
                HitLocation.legs: 25,
              },
              maxHealthByLocation: {
                HitLocation.head: 50,
                HitLocation.torso: 100,
                HitLocation.arms: 25,
                HitLocation.legs: 25,
              },
              equipment: {
                EquipmentSlot.mainHand: Equipment(
                  name: 'Slam Attack',
                  slot: EquipmentSlot.mainHand,
                  type: EquipmentType.sword, // Placeholder type
                  abilities: [
                    Ability(
                      name: 'Slam',
                      range: 2.5,
                      aoeRadius: 1.5,
                      damage: 20,
                      targetLocations: [HitLocation.torso, HitLocation.arms, HitLocation.legs],
                      cooldownDuration: Duration(seconds: 2),
                      requiredSkillType: WeaponSkillType.unarmed,
                    ),
                  ],
                ),
              },
            );
          }
          // Alternate between melee, ranged and healer enemies
          if (index % 4 == 0) {
            return GameCharacter(
              logicalPosition: spawn,
              isRanged: true,
              healthByLocation: enemyHealthByLocation,
              maxHealthByLocation: enemyMaxHealthByLocation,
              equipment: {
                EquipmentSlot.mainHand: Equipment(
                  name: 'Spit Attack',
                  slot: EquipmentSlot.mainHand,
                  type: EquipmentType.staff, // Placeholder type
                  abilities: [
                    Ability(
                      name: 'Spit',
                      range: 6,
                      aoeRadius: 0.5,
                      damage: 8,
                      targetLocations: [HitLocation.head, HitLocation.torso, HitLocation.arms, HitLocation.legs],
                      cooldownDuration: Duration(seconds: 1),
                      requiredSkillType: WeaponSkillType.ranged,
                    ),
                  ],
                ),
              },
            );
          } else if (index % 4 == 1) {
            return GameCharacter(
              logicalPosition: spawn,
              healthByLocation: enemyHealthByLocation,
              maxHealthByLocation: enemyMaxHealthByLocation,
              equipment: {
                EquipmentSlot.mainHand: Equipment(
                  name: 'Claw Attack',
                  slot: EquipmentSlot.mainHand,
                  type: EquipmentType.sword, // Placeholder type
                  abilities: [
                    Ability(
                      name: 'Claw',
                      range: 1.5,
                      aoeRadius: 0.5,
                      damage: 10,
                      targetLocations: [HitLocation.torso, HitLocation.arms],
                      cooldownDuration: Duration(milliseconds: 800),
                      requiredSkillType: WeaponSkillType.unarmed,
                    ),
                  ],
                ),
              },
            );
          } else if (index % 4 == 2) {
            return GameCharacter(
              logicalPosition: spawn,
              healthByLocation: enemyHealthByLocation,
              maxHealthByLocation: enemyMaxHealthByLocation,
              equipment: {
                EquipmentSlot.mainHand: Equipment(
                  name: 'Heal Spell',
                  slot: EquipmentSlot.mainHand,
                  type: EquipmentType.staff, // Placeholder type
                  abilities: [
                    Ability(
                      name: 'Heal',
                      range: 5,
                      aoeRadius: 1.0,
                      damage: -15, // Negative damage to heal
                      isHeal: true,
                      targetLocations: [HitLocation.head, HitLocation.torso, HitLocation.arms, HitLocation.legs],
                      cooldownDuration: Duration(seconds: 3),
                      requiredSkillType: WeaponSkillType.magic,
                    ),
                  ],
                ),
              },
            );
          } else {
            return GameCharacter(
              logicalPosition: spawn,
              healthByLocation: enemyHealthByLocation,
              maxHealthByLocation: enemyMaxHealthByLocation,
              equipment: {
                EquipmentSlot.mainHand: Equipment(
                  name: 'Summoning Orb',
                  slot: EquipmentSlot.mainHand,
                  type: EquipmentType.staff, // Placeholder type
                  abilities: [
                    Ability(
                      name: 'Summon',
                      range: 4,
                      aoeRadius: 0.5,
                      damage: 0,
                      manaCost: 20,
                      targetLocations: [HitLocation.torso], // Summon doesn't target a body part
                      cooldownDuration: Duration(seconds: 10),
                      requiredSkillType: WeaponSkillType.magic,
                    ),
                  ],
                ),
              },
            );
          }
        }),
      ],
      currentLevelIndex: currentLevelIndex,
    );
  }

  GameState copyWith({
    List<List<GridCell>>? grid,
    List<GameCharacter>? characters,
    List<Projectile>? projectiles,
    int? currentLevelIndex,
    bool? isDebugMenuOpen,
    Ability? targetingAbility,
    Point<int>? targetingPosition,
    bool clearTargeting = false,
    Ability? pendingAbility,
    Point<int>? pendingTarget,
    bool clearPending = false,
    HashSet<Direction>? activeMoveDirections,
  }) {
    return GameState(
      grid: grid ?? this.grid,
      characters: characters ?? this.characters,
      projectiles: projectiles ?? this.projectiles,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      isDebugMenuOpen: isDebugMenuOpen ?? this.isDebugMenuOpen,
      targetingAbility:
          clearTargeting ? null : targetingAbility ?? this.targetingAbility,
      targetingPosition:
          clearTargeting ? null : targetingPosition ?? this.targetingPosition,
      pendingAbility: clearPending ? null : pendingAbility ?? this.pendingAbility,
      pendingTarget: clearPending ? null : pendingTarget ?? this.pendingTarget,
      activeMoveDirections: activeMoveDirections ?? this.activeMoveDirections,
    );
  }
}
