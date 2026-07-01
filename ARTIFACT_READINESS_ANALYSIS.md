# Artifact Implementation Readiness Analysis

## Summary
- **Total Artifacts:** 57 unimplemented (including 7 placeholders)
- **Existing Effect Kinds:** 36
- **Existing Unit Classes:** 8 (GRUNT, WARRIOR, RANGED, RIDER, CHAMPION, FLYING, ARCANE, UNDEAD)
- **Note:** No "Infernal" unit class exists (Infernals are summoned via spell temporarily)

---

## ANALYSIS BY ARTIFACT

### READY NOW (Systems 100% exist and integrated)

These can be implemented immediately with just an effect_kind and ArtifactEffectExecutor/QueryHandler additions:

#### Simple Unit Stat Bonuses (troop_all_hp_percent system exists)
- **22. iron_helmet** - "Increases max unit HP by 30."
  - System: Can use existing troop_all_hp_percent effect_kind
  - Needs: Add effect_kind="troop_all_hp_percent", effect_value=0.30
  - Status: ✓ READY

- **52. medal** - "Increases max unit HP by 75."
  - System: Same as iron_helmet, scales with value
  - Needs: effect_kind="troop_all_hp_percent", effect_value=0.75 (adjusted for balance)
  - Status: ✓ READY

#### Resource Production Speed (system exists)
- **45. iron_hoe** - "Increases production limits for starter buildings by 100%."
  - System: Production speed multiplier exists but NOT per-building-type
  - Current: all_production_speed_percent affects all buildings
  - Needs: New effect_kind for specific building category filtering
  - Status: ⚠ PARTIAL - needs filtering

#### Simple Triggers (wave_started system fully implemented)
- **26. family_crossbow** - "Receive temporary crossbowmen (2) at the start of every wave."
  - System: on_wave_started_add_resource exists
  - Needs: New effect_kind on_wave_started_add_units + unit spawning system
  - Status: ⚠ PARTIAL - needs unit spawning

- **34. rusty_bell** - "Receive temporary Goose Riders (2) at the start of every wave."
  - Status: ⚠ PARTIAL - same as family_crossbow

#### Resource Production Triggers (partially exist)
- **24. magic_acorn** - "Producing 1000 wood grants extra 500 wood."
  - System: Production tracking exists in buildings, but no "on_produced_X_amount" trigger
  - Needs: New effect_kind with production amount threshold detection
  - Status: ⚠ PARTIAL

- **29. royal_order** - "Producing 1000 crystals grants 3 Legendary Spells."
  - Status: ⚠ PARTIAL - same as magic_acorn
  - Extra need: Legendary spell reward system

- **4. clay_treasure** - "Producing 1000 clay grants a Legendary Artifact."
  - Status: ⚠ PARTIAL - needs legendary reward system

---

### PARTIAL (Some systems exist, need modifications)

#### Resource Tracking Systems
- **17. broken_penny** - "Gain 3 Gold for each point of damage dealt to your castle."
  - Castle damage tracking: ✓ exists in castle_core.take_damage()
  - System: No artifact hook for damage tracking
  - Needs: New event hook on_castle_damaged(amount) → add_resource
  - Status: ⚠ NEEDS EVENT HOOK

#### Unit-Per-Class Systems (class bonus system exists but limited)
- **63. poor_mans_relic** - "Every Grunt unit on battlefield +2% HP, +3% damage to other Grunts."
  - System: troop_class_hp_percent and troop_class_damage_percent effects exist
  - Limitation: Effects are static multipliers, not "per unit on field"
  - Needs: Dynamic multiplier recalculation based on active unit count
  - Status: ⚠ PARTIAL - architecture mismatch

- **2. mages_robe** already implements this: "Every Arcane unit +3% spell damage"
  - effect_kind: spell_damage_percent_per_class_unit_on_field
  - Status: ✓ This pattern works for spells, needs unit damage version

#### Flying Unit Bonuses
- **36. golden_wings** - "Flying troops gain 30% boost to attack speed and move speed."
  - System: Unit class bonus system exists for HP/damage/attack_speed
  - Unit classes: FLYING class exists
  - Attack speed bonus: ✓ supported (samurai_helm uses it)
  - Movement speed bonus: ✗ NOT in TroopBonusCore
  - Needs: Add movement_speed stat to ArtifactClassBonuses
  - Status: ⚠ PARTIAL

#### Building Mechanics
- **6. comfy_bed** - "Increases all troop buildings' unit capacity by 1."
  - Building capacity system: ✓ exists (max_units per building)
  - Artifact hook: ✗ No way to modify building max_units dynamically
  - Needs: ArtifactCore method to query/modify building capacity
  - Status: ⚠ BLOCKED - no building modification hook

- **10. cupbearers_vessel** - "Receive 1 Wine for each Well or Big Well every 10 seconds."
  - Building detection: Possible via BuildingRegistry
  - Wine production: Resource exists
  - Needs: New effect_kind for periodic_per_building_type_resource
  - Status: ⚠ PARTIAL

#### Seal System
- **22. enchanted_totem** - "Places a seal on 2 tiles."
  - Seal resources exist: seal_normal.tres, seal_legendary.tres in /resources/seals/
  - SealConfig class exists
  - Needs: Seal placement UI/logic system integration
  - Status: ⚠ BLOCKED - seal placement not hooked to artifacts

- **44. trusty_compass** - "Places a Legendary Seal on 3 tiles."
  - Status: ⚠ BLOCKED - same as enchanted_totem

#### Spell System Integration
- **19. chi_fan** - "Increases units' bonus HP by 5 each time you use a spell."
  - Spell cast tracking: on_spell_cast hook exists in ArtifactEffectExecutor
  - HP bonus: troop_all_hp_percent exists but static
  - Needs: Stackable/accumulating HP bonus on each spell cast
  - Status: ⚠ PARTIAL - needs accumulator

#### King Ability Cooldown
- **30. royal_rune** - "Reduces ALL King's Abilities cooldown by 25%."
  - King/Hero system: ✓ exists (hero_core.gd)
  - Ability cooldowns: ✓ exist in skill_core.gd
  - Needs: Effect_kind for skill_cooldown_reduction + hero integration
  - Status: ⚠ PARTIAL

- **31-33. rune_shard_red/blue/green** - Individual ability cooldowns
  - Status: ⚠ PARTIAL - same system needed

#### Morale System
- **49. wine_cup** - "Every 30 wine spent permanently grants 1 morale."
  - Morale system: ✓ exists (MoraleSystem.gd)
  - Wine resource: ✓ exists
  - Resource spending tracking: ✗ NOT implemented
  - Needs: Hook on resource consumption with threshold
  - Status: ⚠ PARTIAL

#### Gaze System Integration
- **26. moon_talisman** - "Healer Mages (3) join each time you upgrade gaze."
  - Gaze system: ✓ exists (gaze_core.gd with gaze_level_changed signal)
  - Unit summoning: ✗ Limited (only at wave start currently)
  - Needs: on_gaze_upgraded event + unit summon capability
  - Status: ⚠ PARTIAL

---

### BLOCKED (Multiple new systems needed)

#### Legendary Reward System (doesn't exist at all)
- **4. clay_treasure**, **29. royal_order** - Need legendary artifact/spell distribution
- Status: ❌ REQUIRES NEW SYSTEM

#### Damage/Enemy Mechanics
- **15. golden_arrow** - "Enemies damaged for 10% their max HP after introduction."
  - Enemy HP tracking: ✓ exists
  - Enemy intro event: ✗ NOT hooked
  - Needs: on_enemy_spawned trigger + damage calculation system
  - Status: ⚠ BLOCKED

- **16. golden_ball** - "Heal castle 10 HP when production building depleted. 5 uses."
  - Building depletion event: ✗ NOT exposed
  - Needs: on_building_depleted trigger + use counter
  - Status: ⚠ BLOCKED

- **39. sweeping_blade** - "Sawmills and trees damage enemies when working."
  - Building attack system: ✓ Cannon building exists with damage
  - Needs: Apply to specific building types, not custom logic
  - Status: ⚠ BLOCKED - architecture doesn't support per-building-type behaviors in artifacts

#### Unit Summoning on Events
- **35. scarecrow_hat** - "Explosive scarecrow on troop death. 40s cooldown."
- **20. indescribable_figurine** - "Dreadful creature on troop death. 140s cooldown."
  - Unit spawning: ✗ Only works at wave start or via spell
  - Building depletion event: ✗ NOT exposed
  - Excavation system: ✗ NOT hooked to artifacts
  - Status: ❌ REQUIRES EVENT HOOKS + UNIT SPAWNING SYSTEM

#### Unit Damage/Ability Systems
- **38. stunning_mace** - "Champion units stun enemy once every 20 attacks."
  - Unit abilities: ✗ NOT exposed to artifacts
  - Stun mechanic: ✓ exists in spells
  - Needs: Per-unit-class ability trigger system
  - Status: 
