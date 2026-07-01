# Artifact Implementation Readiness Analysis

## Executive Summary

**Analyzed:** 54 unimplemented artifacts (+ 7 placeholders)
**Ready Now:** 2 artifacts (3% - can implement today)
**Partial (Event hooks):** 7 artifacts (13% - 1-2 weeks)
**Partial (System extensions):** 12 artifacts (22% - 2-4 weeks)
**Blocked (Major systems):** 33 artifacts (61% - 4-8 weeks each)

---

## READY NOW (2 artifacts - Implement Today)

### 1. iron_helmet
- **Requirement:** Increases max unit HP by 30
- **System Status:** ✓ FULLY IMPLEMENTED
  - `troop_all_hp_percent` effect_kind exists
  - ArtifactClassBonuses handles HP scaling
  - Unit classes (8 total) all affected
- **Implementation:** Add to catalog with effect_kind="troop_all_hp_percent", value=0.30
- **Effort:** 2 minutes

### 2. medal  
- **Requirement:** Increases max unit HP by 75
- **System Status:** ✓ FULLY IMPLEMENTED (same as iron_helmet)
- **Implementation:** effect_kind="troop_all_hp_percent", value=0.75
- **Effort:** 2 minutes

---

## TIER 1: Simple Event Hooks (7 artifacts - 1-2 weeks total)

These artifacts need ONE new event hook each in existing systems:

### 3. broken_penny
- **Requirement:** Gain 3 Gold per damage to castle
- **Systems:**
  - ✓ castle_core.take_damage() exists
  - ✓ ResourceCore.add_resource() works
  - ✗ Missing: on_castle_damaged event hook
- **Implementation:** Emit signal in castle_core.take_damage(), create effect_kind "on_castle_damage_add_resource"
- **Effort:** 4 hours

### 4. wine_cup
- **Requirement:** Every 30 wine spent = +1 morale permanently
- **Systems:**
  - ✓ ResourceCore tracks consumption
  - ✓ MoraleSystem exists and calculates morale
  - ✗ Missing: on_resource_consumed threshold hook
- **Implementation:** Add threshold tracking in artifact state, new effect_kind "on_resource_consumed_amount_threshold"
- **Effort:** 4 hours

### 5. golden_arrow
- **Requirement:** Enemies take 10% max HP damage when spawning
- **Systems:**
  - ✓ Damage system exists
  - ✓ Enemy data tracked
  - ✗ Missing: on_enemy_spawned event
- **Implementation:** Emit signal when BattleCore spawns enemies, new effect_kind "on_enemy_spawned_damage_percent_max_hp"
- **Effort:** 4 hours

### 6. golden_ball
- **Requirement:** Heal castle 10 HP when production building depleted (5 uses max)
- **Systems:**
  - ✓ Castle healing exists
  - ✓ Building depletion tracked in MapSlotProduction
  - ✗ Missing: on_building_depleted event hook
  - ✗ Missing: Use counter in artifact state
- **Implementation:** Emit from building depletion logic, new effect_kind "on_building_depleted_heal_castle_limited"
- **Effort:** 6 hours (includes use counter)

### 7. moon_talisman
- **Requirement:** 3 Healer Mages on gaze upgrade
- **Systems:**
  - ✓ gaze_core.gaze_level_changed signal exists
  - ✗ Missing: Unit summoning outside of spells/waves
  - ✗ Missing: Healer Mage unit type (need to define)
- **Implementation:** Add on_gaze_upgraded_summon_units effect, new unit spawn system
- **Effort:** 6 hours (includes basic unit spawn)

### 8. hand_of_the_avenged
- **Requirement:** Random unit enraged on friendly death
- **Systems:**
  - ✓ on_troop_died event exists
  - ✓ Enrage mechanic (from Wrath spell) exists
  - ✗ Missing: Probabilistic artifact effect triggers
- **Implementation:** New effect_kind "on_troop_died_random_apply_enrage", probability execution system
- **Effort:** 6 hours

### 9. healing_banner
- **Requirement:** 25% chance unit dies → healing pool spawns
- **Systems:**
  - ✓ on_troop_died event exists
  - ✓ Healing pool spell effect exists
  - ✗ Missing: Probability-based effect system
- **Implementation:** Add probability to effect execution, new effect_kind "on_troop_died_chance_spawn_healing_pool"
- **Effort:** 6 hours

**Tier 1 Total Effort:** ~40 hours (1-2 weeks for experienced developer)

---

## TIER 2: System Extensions (12 artifacts - 2-4 weeks)

These need modifications to existing core systems:

### 10. golden_wings
- **Requirement:** Flying troops +30% attack/move speed
- **Current State:**
  - ✓ FLYING unit class exists
  - ✓ Attack speed bonus works (see samurai_helm)
  - ✗ Movement speed not in ArtifactClassBonuses
- **Fix:** Add TROOP_STAT_MOVE_SPEED constant to ArtifactClassBonuses, apply via unit bonus system
- **Effort:** 4 hours

### 11. poor_mans_relic
- **Requirement:** Each Grunt on battlefield: +2% HP, +3% damage to Grunts
- **Current Issue:**
  - Class bonuses are static multipliers
  - Requirement is dynamic per active unit count
  - mages_robe pattern uses count but for spell damage only
- **Solution:** Create dynamic bonus recalc based on active unit count in TroopBonusCore
- **Effort:** 8 hours

### 12. chi_fan
- **Requirement:** +5 HP per spell cast (accumulating)
- **Current Issue:**
  - on_spell_cast hook exists ✓
  - troop_all_hp_percent is static ✗
  - Need stackable/accumulating bonus
- **Solution:** Create HP accumulator in artifact state, apply on each spell cast
- **Effort:** 6 hours

### 13-14. royal_rune / rune_shards
- **Requirement:** -25% cooldown on King abilities (all or individual)
- **Current State:**
  - ✓ skill_core manages cooldowns
  - ✓ Hero system integrated
  - ✗ No cooldown reduction effect_kind
- **Solution:** Add skill_cooldown_reduction_percent effect_kind, integrate with skill_core
- **Effort:** 8 hours (covers all 3 variants)

### 15. cupbearers_vessel
- **Requirement:** 1 Wine per well every 10s
- **Current State:**
  - ✓ BuildingRegistry tracks buildings
  - ✓ Well buildings exist
  - ✗ No per-building-type periodic effect
- **Solution:** New effect_kind "periodic_per_building_type_add_resource"
- **Effort:** 6 hours

### 16. iron_hoe
- **Requirement:** +100% production limits for starter buildings
- **Current Issue:**
  - Production speed multiplier affects ALL buildings
  - Need building category filtering
- **Solution:** Filter all_production_speed_percent by building category (basic_production)
- **Effort:** 4 hours

### 17-18. family_crossbow / rusty_bell
- **Requirement:** 2 Crossbowmen/Goose Riders at wave start
- **Current State:**
  - ✓ on_wave_started hook exists
  - ✗ No generic unit spawning system for artifacts
- **Solution:** Create unit spawn system, new effect_kind "on_wave_started_add_units"
- **Effort:** 10 hours (includes generic spawn system)

### 19-20. magic_acorn / royal_order  
- **Requirement:** 1000 resource produced → bonus
- **Current Issue:**
  - Production tracked but not totals
  - No threshold trigger system
  - royal_order needs legendary reward system
- **Solution:** Add production total tracking, threshold trigger, legendary system (simple version)
- **Effort:** 12 hours

### 21. twin_projectiles
- **Requirement:** +4% projectile per Warrior ally
- **Current Issue:**
  - Projectile system exists ✓
  - Need dynamic per-ally-count calculation ✗
- **Solution:** Create ally-count → projectile multiplier calculation
- **Effort:** 6 hours

**Tier 2 Total Effort:** ~80 hours (2-4 weeks for experienced developer)

---

## TIER 3: Major New Systems (20+ artifacts - 4-8 weeks each)

### Unit Summoning on Events (5-6 artifacts)
- **Artifacts:** scarecrow_hat, indescribable_figurine, moon_talisman (partial)
- **Missing:**
  - Generic unit spawn outside spell/wave context
  - on_building_depleted trigger
  - on_excavation_completed trigger
  - Unit lifetime/cooldown management
- **Effort:** 20-30 hours

### Unit Lifecycle Management (3 artifacts)
- **Artifacts:** second_chance, sturdy_candle
- **Missing:**
  - Temporary unit lifecycle hooks
  - Unit resurrection system
  - Unit extension system
- **Effort:** 20-30 hours

### Ability Systems (3 artifacts)
- **Artifacts:** stunning_mace, chi_fan (partial), golden_wings (partial)
- **Missing:**
  - Per-unit-class ability triggers
  - Champion stun every N attacks system
- **Effort:** 15-25 hours

### Production Ratio Tracking (3 artifacts)
- **Artifacts:** filtered_fuel, flour_deity, super_metal
- **Missing:**
  - Per-resource-type production hooks
  - Dynamic stat scaling on production
  - Complex scaling calculations
- **Effort:
