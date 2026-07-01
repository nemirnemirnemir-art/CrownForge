# Building Upgrade Campaign — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make 100% of building upgrades functional at runtime. Currently ~15/61 buildings have working upgrade code; the remaining ~46 are pure UI text with zero gameplay effect.

**Architecture:** New upgrade logic goes into narrow helper files adjacent to `core/building_upgrade/`, NOT into `building_upgrade_core.gd` (monolith watchlist). Per-building effect handlers go into `core/buildings/special/*.gd`. Production/morale/troop-stat hooks go into the appropriate consuming system files. Follow extract-first-extend-second rule from `docs/AGENTS.md`.

**Tech Stack:** Godot 4.3, GDScript, headless test runner (`Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/<test>.gd`)

---

## Ownership Rules

1. Controller (orchestrator) is the only writer for this plan and the execution log.
2. Worker A owns economy/morale/production buildings.
3. Worker B owns levy/veteran barracks buildings.
4. Worker C owns elite/offensive/unit-synergy buildings.
5. Worker D owns kingdom infrastructure + systemic bug fixes + MagicSchool.
6. Controller owns final doc updates, shared verification, and cross-worker integration fixes.

## Mandatory Pre-Edit Checklist

Before ANY code change, every worker MUST:
1. Read `docs/policies/GDSCRIPT_WARNING_PREVENTION.md` and follow its rules.
2. Use static typing for all variables, parameters, and return values.
3. Prefix unused parameters with `_`.
4. Never shadow global `class_name` identifiers or base-class properties like `owner`.
5. Use `float()` or float literals for division where float results are intended.
6. New logic goes into focused helper files, NOT monolith watchlist files.

## Confirmed Design Decisions

| Decision | Resolution |
|----------|-----------|
| Sawmill / Friendly Lumberjacks neighbours | 4 orthogonal sides only (no diagonals) |
| Fuel Pump / Gifts of the Earth resource pool | All 13 runtime resources, equal chance |
| Militia Camp / Mega dude counter | GLOBAL counter across all militia_camp buildings |
| Capacity upgrades scope | Global unlock — ALL buildings of that type get the bonus |
| Troop Inspiration stacking | Flat 10% when at least 1 building has the upgrade (does NOT stack per building count) |

## Canonical Upgrade Matrix

### Key: Status column
- **DONE** = runtime code exists and works
- **MISMATCH** = runtime code exists but text/behavior don't match
- **MISSING** = no runtime code at all
- **BUG** = runtime code has a defect

---

### Already Implemented (DONE / MISMATCH — verify only, fix mismatches)

| building_id | upgrade_id | Name | Expected Behavior | Status |
|---|---|---|---|---|
| archmages_university | :0 | Illusion of Choice | Choice instead of random legendary spell | DONE |
| archmages_university | :1 | Archmage's Tempo | +20% legendary spell gen speed | DONE |
| arena | :0 | Fight Betting | Earn 1 gold / 3s while working | DONE |
| arena | :1 | Higher Morale | +15 morale | DONE |
| brick_factory | :0 | Repair speed | +100% production speed | DONE |
| brick_factory | :1 | Fortifications | 5 charges -> +1 max HP (max 100) | MISMATCH (runtime uses 20 charges) |
| buddhist_temple | :0 | Production Speed Buff | +5% all production per temple | DONE |
| buddhist_temple | :1 | Troop Damage Buff | +10% all troop damage per temple | DONE |
| buddhist_temple | :2 | Spell Damage Buff | +10% spell damage per temple | DONE |
| concert | :0 | Music for Your Soul | +10 morale while active under gaze | DONE |
| concert | :1 | Music for Your Body | +5 passive morale | DONE |
| execution_ground | :0 | High Bounties | +2 extra Denarii per execution | DONE |
| execution_ground | :1 | Troop Inspiration | +10% dmg/HP for Grunt troops | BUG (synthetic ID pollution) |
| fairy_fountain | :0 | Production Speed | +25% production speed | DONE |
| fairy_fountain | :1 | Anti-Goblin Dust | 15 dmg per production cycle | MISMATCH (runtime is continuous DPS) |
| hero_statue | :0 | Hero Statue Speed | +25% troop bonus reward gen speed | DONE |
| hospital | :0 | Masters of healing | +50% healing | MISMATCH (runtime is *1.25) |
| hospital | :1 | Masters of morale | +5 morale per active hospital | MISMATCH (runtime gives +4) |
| kings_statue | :0 | Crystal Clarity | 25% chance extra Crystal 1 per cycle | MISMATCH (runtime is cost refund) |
| kings_statue | :1 | Troop Inspiration | +10% dmg/HP Champion troops | DONE |
| magic_ball | :0 | More spell damage | +30% spell damage | DONE |
| magic_ball | :1 | Witchcraft | +15% Arcane troop damage | DONE |
| magic_college | :0 | Illusion of Choice | Choice instead of random spell | DONE |
| magic_college | :1 | Magic College Speed | +20% spell gen speed | DONE |
| stables | :2 | Survivor | When horse dies rider continues | DONE |
| tesla_tower | :0 | Attack Speed | +40% attack speed | DONE |
| tesla_tower | :1 | Additional Chain | +1 lightning chain | DONE |
| tesla_tower | :2 | Damage | +40% damage | DONE |
| wheel_of_fortune | :0 | Production Speed | +25% production speed | DONE |

### Worker A — Economy / Morale / Production (MISSING)

| building_id | upgrade_id | Name | Expected Behavior | Implementation Approach |
|---|---|---|---|---|
| vineyard | :0 | Grape Varieties | +5 morale per vineyard (passive) | Add to MoraleSystem aggregation |
| vineyard | :1 | Vineyard Production | +30% production | Add to MapSlotProduction multiplier |
| market | :0 | Charismatic Traders | +5 morale per active market | Add to MoraleSystem aggregation |
| market | :1 | Faster Trading | +25% production | Add to MapSlotProduction multiplier |
| tavern | :0 | Higher Morale | +5 additional morale | Add to MoraleSystem aggregation |
| sawmill | :0 | Sawmill Production | +25% production | Add to MapSlotProduction multiplier |
| sawmill | :1 | Friendly Lumberjacks | +20% production to 4 orthogonal neighbours | New helper: `BuildingUpgradeNeighbourBoost.gd` |
| clay_mine | :0 | Zero Waste | 10% chance repair castle 1 HP per cycle | Hook into production tick |
| clay_mine | :1 | Clay Mine Production | +35% production | Add to MapSlotProduction multiplier |
| crystal_mine | :0 | Magic Aura | +10% spell damage (passive) | Add to spell damage aggregation |
| crystal_mine | :1 | Crystal Mine Production | +30% production | Add to MapSlotProduction multiplier |
| gold_mine | :0 | Rich Veins | 50% chance extra Gold 2 per cycle | Hook into production tick |
| gold_mine | :1 | Gold Mine Production | +25% production | Add to MapSlotProduction multiplier |
| iron_mine | :0 | Troop Inspiration | +10% dmg/HP Warrior troops (flat, no stack) | Add to troop stat aggregation |
| iron_mine | :1 | Iron Mine Production | +30% production | Add to MapSlotProduction multiplier |
| wheat_field | :0 | Farm Production | +30% production | Add to MapSlotProduction multiplier |
| wheat_field | :1 | Gold Diggers | 25% chance extra Gold 1 per cycle | Hook into production tick |
| animal_farm | :0 | Production Speed | +30% production | Add to MapSlotProduction multiplier |
| animal_farm | :1 | Troop Inspiration | +10% dmg/HP Rider troops (flat, no stack) | Add to troop stat aggregation |
| fishermans_hut | :0 | Production Speed | +30% production | Add to MapSlotProduction multiplier |
| fishermans_hut | :1 | Quality Lure | 50% chance extra Meat 2 per cycle | Hook into production tick |
| forge | :0 | Efficient Processing | Consume Ore 2 -> produce Steel 2 | Modify production recipe |
| forge | :1 | Troop Inspiration | +10% dmg/HP Ranged troops (flat, no stack) | Add to troop stat aggregation |
| fuel_pump | :0 | Production Speed | +30% production | Add to MapSlotProduction multiplier |
| fuel_pump | :1 | Gifts of the Earth | 20% chance random extra resource (13 pool) | Hook into production tick |
| mill | :0 | Efficient Processing | Consume Wheat 2 -> produce Flour 2 | Modify production recipe |
| mill | :1 | Troop Inspiration | +10% dmg/HP Flying troops (flat, no stack) | Add to troop stat aggregation |
| winery | :0 | Production Speed | +30% production | Add to MapSlotProduction multiplier |
| winery | :1 | Wine for All | 50% chance extra Wine 1 per cycle | Hook into production tick |

**Worker A Files to Create/Modify:**
- Create: `core/building_upgrade/BuildingUpgradeProductionBoost.gd` — production multiplier lookup by building_id + upgrade status
- Create: `core/building_upgrade/BuildingUpgradeNeighbourBoost.gd` — sawmill neighbour 20% boost (4 orthogonal)
- Create: `core/building_upgrade/BuildingUpgradeProductionBonus.gd` — bonus resource/repair hooks for production tick
- Create: `core/building_upgrade/BuildingUpgradeTroopInspiration.gd` — flat 10% troop class buffs from mines/forge/mill
- Modify: `scripts/map_slot/MapSlotProduction.gd` — hook production multiplier + bonus resource
- Modify: `scripts/systems/MoraleSystem.gd` — add vineyard/market/tavern morale hooks
- Modify: `core/building_upgrade/BuildingUpgradeEffectFlow.gd` — add passive spell damage from crystal_mine
- Modify: `core/building_upgrade_core.gd` — add thin wrapper methods for new queries (wiring only)
- Test: `scripts/dev/tests/test_building_upgrade_production_boost.gd`
- Test: `scripts/dev/tests/test_building_upgrade_neighbour_boost.gd`
- Test: `scripts/dev/tests/test_building_upgrade_production_bonus.gd`
- Test: `scripts/dev/tests/test_building_upgrade_troop_inspiration.gd`

### Worker B — Levy / Veteran Barracks (MISSING)

| building_id | upgrade_id | Name | Expected Behavior | Implementation Approach |
|---|---|---|---|---|
| peasants_hut | :0 | Capacity | +2 capacity (global) | Capacity query in slot production |
| peasants_hut | :1 | Insurance | Gold 2 on Peasant death | Death callback hook |
| peasants_hut | :2 | Peasants' power | +30% HP and damage for Peasants | Troop stat modifier |
| archery | :0 | Precise shots | 2x damage every 5th attack | Combat attack hook |
| archery | :1 | Archers' capacity | +2 capacity (global) | Capacity query |
| archery | :2 | Stunning arrows | 2s stun on full HP enemy | Combat attack hook |
| gnome_dome | :0 | Refund | 5 gold on Gnome death | Death callback hook |
| gnome_dome | :1 | Damage | +100% Gnome damage | Troop stat modifier |
| gnome_dome | :2 | Capacity | +5 capacity (global) | Capacity query |
| hunters | :0 | Stinky nets | 10 bonus DoT poison | Combat attack hook |
| hunters | :1 | Hunters' capacity | +2 capacity (global) | Capacity query |
| madhouse | :0 | Madman Evasion | 35% evasion chance | Troop stat modifier |
| madhouse | :1 | Madman Capacity | +2 capacity (global) | Capacity query |
| madhouse | :2 | Alcohol Needles | Drunk debuff on enemies | Combat attack hook |
| militia_camp | :0 | Militia HP | +50% HP | Troop stat modifier |
| militia_camp | :1 | Militia capacity | +2 capacity (global) | Capacity query |
| militia_camp | :2 | Mega dude | Mega militia after 4 base troops (GLOBAL counter) | New special building handler |
| slingers_tree | :0 | Slingers' capacity | +3 capacity (global) | Capacity query |
| slingers_tree | :1 | Heavy stones | 3% chance 1s stun | Combat attack hook |
| slingers_tree | :2 | Slingers' HP | +200% HP | Troop stat modifier |
| swordsmen_barracks | :0 | Damage dealt by Swordsmen | +100% damage | Troop stat modifier |
| swordsmen_barracks | :1 | Swordsmen's Capacity | +2 capacity (global) | Capacity query |
| whipmens_house | :0 | Whipmen's capacity | +2 capacity (global) | Capacity query |
| whipmens_house | :1 | Whipmen's HP | +400% HP | Troop stat modifier |
| academy_of_fire | :0 | Combustion | 6 DoT fire on hit | Combat attack hook |
| academy_of_fire | :1 | Damage dealt by Mages | +50% Fire Mage damage | Troop stat modifier |
| academy_of_fire | :2 | Fire Mages' Capacity | +2 capacity (global) | Capacity query |
| academy_of_nature | :0 | Healer Mages' capacity | +1 capacity (global) | Capacity query |
| academy_of_nature | :1 | Healer Mage damage | +25% Healer Mage damage | Troop stat modifier |
| barbarian_tent | :0 | Weapon melting | 8 metal on Barbarian death | Death callback hook |
| barbarian_tent | :1 | Cheaper production | 50% cheaper troops | Production cost modifier |
| barbarian_tent | :2 | Barbarians' damage | +100% damage | Troop stat modifier |
| falcons_camp | :0 | Mentoring | +100% HP to all Grunt troops if >=1 Black Swordsman on field | Conditional global buff |
| falcons_camp | :1 | Black Swordsmen's attack range | Increased attack range | Troop stat modifier |
| falcons_camp | :2 | Black Swordsmen's HP | +200% HP | Troop stat modifier |
| firing_range | :0 | Critical shots | 10% chance 500% damage | Combat attack hook |
| firing_range | :1 | Musketeers' capacity | +2 capacity (global) | Capacity query |
| firing_range | :2 | Cheaper production | 40% cheaper troops | Production cost modifier |
| geese_training_field | :0 | Capacity | +1 capacity (global) | Capacity query |
| geese_training_field | :1 | Damage | +60% Goose Rider damage | Troop stat modifier |
| geese_training_field | :2 | Cheaper production | 50% cheaper troops | Production cost modifier |
| hive | :0 | Bumblebees' capacity | +2 capacity (global) | Capacity query |
| hive | :1 | Sting attack | 30 DoT poison on hit | Combat attack hook |
| longbowmens_camp | :0 | Damage dealt by Longbowmen | +100% damage | Troop stat modifier |
| longbowmens_camp | :1 | Burning arrows | 20 DoT fire on hit | Combat attack hook |
| longbowmens_camp | :2 | Longbowmen's capacity | +2 capacity (global) | Capacity query |
| minotaur_camp | :0 | Vampirism | 50% lifesteal | Combat attack hook |
| minotaur_camp | :1 | Trait Upgrade | +3% dmg to Flying troops per Minotaur (cap 30%) | Global conditional buff |
| minotaur_camp | :2 | Stunning Blow | 1s stun on special attack | Combat attack hook |
| paladins_campus | :0 | Paladins' capacity | +2 capacity (global) | Capacity query |
| paladins_campus | :1 | Spell damage buff | +10% spell damage (passive) | Add to spell damage aggregation |
| paladins_campus | :2 | Paladins' HP | +100% HP | Troop stat modifier |
| pumpkin_field | :0 | Pumpkin Warriors' capacity | +3 capacity (global) | Capacity query |
| pumpkin_field | :1 | HP and Damage | +30% HP and damage | Troop stat modifier |

**Worker B Files to Create/Modify:**
- Create: `core/building_upgrade/BuildingUpgradeCapacityBonus.gd` — capacity bonus lookup by building_id
- Create: `core/building_upgrade/BuildingUpgradeTroopStatModifier.gd` — HP/damage/evasion/range modifiers by unit type
- Create: `core/building_upgrade/BuildingUpgradeCombatHook.gd` — on-hit effects (DoT, stun, crit, lifesteal)
- Create: `core/building_upgrade/BuildingUpgradeDeathReward.gd` — on-death resource grants
- Create: `core/building_upgrade/BuildingUpgradeCostModifier.gd` — production cost reduction
- Create: `core/building_upgrade/BuildingUpgradeMegaMilitia.gd` — mega dude global counter logic
- Modify: `core/building_upgrade_core.gd` — thin wrappers for capacity/stat/combat queries
- Modify: `core/hero/HeroStats.gd` or troop stat consumer — integrate stat modifiers
- Test: `scripts/dev/tests/test_building_upgrade_capacity_bonus.gd`
- Test: `scripts/dev/tests/test_building_upgrade_troop_stat_modifier.gd`
- Test: `scripts/dev/tests/test_building_upgrade_combat_hook.gd`
- Test: `scripts/dev/tests/test_building_upgrade_death_reward.gd`
- Test: `scripts/dev/tests/test_building_upgrade_cost_modifier.gd`
- Test: `scripts/dev/tests/test_building_upgrade_mega_militia.gd`

### Worker C — Elite / Offensive / Unit-Synergy (MISSING)

| building_id | upgrade_id | Name | Expected Behavior | Implementation Approach |
|---|---|---|---|---|
| stables | :0 | Squires' HP | +40% HP | Troop stat modifier |
| stables | :1 | Squires' capacity | +1 capacity (global) | Capacity query |
| academy_of_lightning | :0 | Lightning Mages' capacity | +2 capacity (global) | Capacity query |
| academy_of_lightning | :1 | HP and Damage | +50% HP and damage for Lightning Mages | Troop stat modifier |
| academy_of_lightning | :2 | Jumping Lightning | +2 extra lightning jumps | Combat mechanic modifier |
| ballista_factory | :0 | Damage and slowness | +25% damage + slow on hit | Combat attack hook |
| ballista_factory | :1 | Ballistae capacity | +1 capacity (global) | Capacity query |
| ballista_factory | :2 | Long shot | Distance-based damage scaling | Combat mechanic modifier (NEEDS CLARIFICATION) |
| black_unicorn_field | :0 | Damage dealt by Black Unicorns | +100% damage | Troop stat modifier |
| black_unicorn_field | :1 | Boosters of Morale | +5 morale per Black Unicorn | Morale aggregation |
| catapult_factory | :0 | Catapult capacity | +1 capacity (global) | Capacity query |
| catapult_factory | :1 | Stun chance | 20% chance stun | Combat attack hook |
| catapult_factory | :2 | Long shot | Distance-based damage scaling | Combat mechanic modifier (NEEDS CLARIFICATION) |
| giants_bedding | :0 | Sawdust | +100 Wood on Giant wake | Production event hook |
| giants_bedding | :1 | Wheat Straws | +100 Wheat on Giant wake | Production event hook |
| hydra_pond | :0 | Hydras' HP | +100% HP | Troop stat modifier |
| hydra_pond | :1 | Capacity | +1 capacity (global) | Capacity query |
| hydra_pond | :2 | Trait Upgrade | +10% damage to all units on battlefield | Global combat buff (NEEDS CLARIFICATION) |
| lion_circus | :0 | Versatility | Griffins count as all-class, +100% cost | Troop class + cost modifier (NEEDS CLARIFICATION) |
| pangolin_stump | :0 | Pangolins' HP | +50% HP | Troop stat modifier |
| pangolin_stump | :1 | War of attrition | Rolling weakens enemies (slow + dmg reduction) | Combat mechanic (NEEDS CLARIFICATION) |
| pangolin_stump | :2 | Pangolins' evasion | 25% evasion | Troop stat modifier |
| ram_pasture | :0 | Rams' HP | +50% HP | Troop stat modifier |
| ram_pasture | :1 | Spell damage | +20% spell damage per Ram | Spell damage aggregation (NEEDS CLARIFICATION per-Ram or flat) |
| ram_pasture | :2 | Twins | 10% chance extra Ram on produce | Production event hook |
| white_unicorn_field | :0 | Unicorns' HP | +100% HP | Troop stat modifier |
| white_unicorn_field | :1 | Spell Damage | +10% spell damage per Unicorn | Spell damage aggregation |

**Worker C Files to Create/Modify:**
- Reuse Worker B's `BuildingUpgradeCapacityBonus.gd` and `BuildingUpgradeTroopStatModifier.gd` (Worker B creates first, Worker C adds entries)
- Create: `core/building_upgrade/BuildingUpgradeSpellDamageBoost.gd` — spell damage from ram/unicorn/crystal_mine/paladins
- Create: `core/buildings/special/GiantsBedding.gd` — resource grant on Giant wake
- Modify: `core/building_upgrade/BuildingUpgradeCombatHook.gd` — add ballista/catapult/lightning entries
- Modify: `core/building_upgrade_core.gd` — thin wrappers for spell damage, morale from unicorns
- Modify: `scripts/systems/MoraleSystem.gd` — black unicorn morale hook
- Test: `scripts/dev/tests/test_building_upgrade_spell_damage_boost.gd`
- Test: `scripts/dev/tests/test_giants_bedding_upgrade.gd`

### Worker D — Kingdom Infrastructure + Systemic Bug Fixes (BUG / MISSING)

| building_id | upgrade_id | Name | Expected Behavior | Status | Implementation Approach |
|---|---|---|---|---|---|
| execution_ground | :1 | Troop Inspiration | +10% Grunt dmg/HP | BUG | Fix synthetic ID `execution_ground:1:applied` pollution |
| magic_school | :0 | Illusion of Choice | Choice instead of random spell | MISSING | Wire into MagicSchool special handler |
| magic_school | :1 | Magic School Speed | +25% spell gen speed | MISSING | Wire into MagicSchool special handler |
| hospital | :0 | Masters of healing | +50% healing | MISMATCH | Fix multiplier from 1.25 to 1.5 |
| hospital | :1 | Masters of morale | +5 morale per active hospital | MISMATCH | Fix value from 4 to 5 |
| brick_factory | :1 | Fortifications | 5 charges -> +1 max HP | MISMATCH | Fix threshold from 20 to 5 |
| fairy_fountain | :1 | Anti-Goblin Dust | 15 dmg per production cycle | MISMATCH | Change from continuous DPS to per-cycle |
| kings_statue | :0 | Crystal Clarity | 25% chance extra Crystal 1 per cycle | MISMATCH | Change from cost refund to bonus production |
| TraderOfferGenerator | — | Duplicate offers | Iterates per-slot generating duplicates for global upgrades | BUG | Fix iteration to deduplicate by building_id |

**Worker D Files to Modify:**
- Modify: `core/buildings/special/ExecutionGround.gd` — remove synthetic ID write
- Modify: `core/buildings/special/MagicSchool.gd` — implement both upgrade effects
- Modify: `core/buildings/special/Hospital.gd` — fix healing multiplier + morale value
- Modify: `core/buildings/special/BrickFactory.gd` — fix charge threshold
- Modify: `core/buildings/special/FairyFountain.gd` — fix damage timing
- Modify: `core/buildings/special/KingsStatue.gd` — change from refund to bonus production
- Modify: `scripts/ui/rewards/modules/TraderOfferGenerator.gd` — deduplicate global upgrade offers
- Test: `scripts/dev/tests/test_execution_ground_upgrade_fix.gd`
- Test: `scripts/dev/tests/test_magic_school_upgrades.gd`
- Test: `scripts/dev/tests/test_hospital_upgrade_values.gd`
- Test: `scripts/dev/tests/test_trader_offer_deduplication.gd`

## Ambiguous Upgrades (Defer or Ask User)

These upgrades have vague descriptions that need user clarification before implementation:

1. **lion_circus:0 / Versatility** — "counted as all-class" — what does this mean for troop type bonuses? Does the Griffin get Warrior+Ranged+Rider+Flying+Grunt+Champion+Arcane buffs simultaneously?
2. **ballista_factory:2 / catapult_factory:2 / Long shot** — no distance-damage formula. Linear? Quadratic? What multiplier at max range?
3. **pangolin_stump:1 / War of attrition** — no parameters for the debuff. What % slow? What % attack speed reduction? Duration?
4. **hydra_pond:2 / Trait Upgrade** — is the +10% damage a global aura from each Hydra on field, or a flat buff when upgrade is owned?
5. **ram_pasture:1 / Spell damage** — "+20% per Ram" — does this mean per Ram unit on the field, or per ram_pasture building?
6. **minotaur_camp:1 / Trait Upgrade** — "+3% extra damage to Flying troops, up to 30%" — 3% per what? Per Minotaur on field? Per minotaur_camp built?

**Recommendation:** Implement the simple/obvious ones first (Workers A, B capacity/stats/production), then come back for these ambiguous ones after user clarification.

## Phase 1: Systemic Bug Fixes (Worker D, do FIRST)

Worker D must fix these before any other worker touches related systems:

1. **ExecutionGround synthetic ID** — remove the `execution_ground:1:applied` write that pollutes upgrade count
2. **TraderOfferGenerator deduplication** — fix per-slot iteration for global upgrades
3. **MagicSchool no-op** — wire both upgrade effects into the existing handler

## Phase 2: Parallel Implementation (Workers A-D simultaneous)

After Phase 1 bugs are fixed, all 4 workers proceed in parallel on their assigned buildings.

**Shared contracts between workers:**
- Worker A creates `BuildingUpgradeProductionBoost.gd` — other workers may read but not write
- Worker B creates `BuildingUpgradeCapacityBonus.gd` and `BuildingUpgradeTroopStatModifier.gd` — Worker C adds entries after Worker B commits
- All workers add thin wrapper methods to `building_upgrade_core.gd` but ONLY for their own building scopes (no cross-contamination)

## Phase 3: Integration Verification (Controller)

After all workers complete:
1. Run full test suite headless
2. Verify save/load round-trip for all new upgrade state
3. Verify UI stripes/icons reflect correct upgrade levels
4. Verify reward menu offers correct upgrades
5. Verify trader does not generate duplicate offers
6. Verify morale/resource/troop bridges produce correct aggregated values
7. Update `docs/PROJECT_NAVIGATOR.md`, `docs/ARCHITECTURE.md`, and relevant `docs/wiki_buildings/*.md`

## Execution Log

- 2026-03-29 Controller: Completed full read-only audit of all 61 buildings and their upgrade status.
- 2026-03-29 Controller: Identified 15 working, 5 mismatched, 3 bugged, 46+ missing upgrade implementations.
- 2026-03-29 Controller: Got user confirmation on 5 critical design decisions.
- 2026-03-29 Controller: Created this master plan and assigned 4 worker scopes.
