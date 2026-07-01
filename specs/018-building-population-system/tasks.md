# Tasks: Building System Expansion

**Feature**: 018-building-population-system  
**Date**: 2025-11-28  
**Based on**: spec.md, plan.md, data-model.md, contracts/

---

## Overview

This feature expands the building system with:
- **Barracks**: Flat defense bonus + defensive perk unlocks
- **Training Grounds**: Global damage bonus + offensive perk unlocks  
- **Academy**: Global XP bonus + progression perk unlocks
- **Worker System**: Assign population to economic buildings
- **Expanded Perk Pool**: Buildings unlock new perks into global pool
- **Population Integration**: Hero creation/death affects population

---

## Implementation Strategy

**MVP Scope**: All user stories (US1-US6) are core functionality and should be implemented together.

**Approach**: Incremental delivery by user story, each independently testable.

**Dependencies**:
- Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3+ (User Stories)
- US1, US2, US3 can be parallelized after Phase 2
- US4 depends on US1-US3 (needs buildings to exist)
- US5 depends on US4 (needs population system)
- US6 depends on US1-US3 (needs perk unlocks)

---

## Phase 1: Setup

**Goal**: Prepare data structures and extend existing resources.

### Data Model Extensions

- [ ] T001 Extend BuildingData Resource with new fields in `core/building_data.gd`
- [ ] T002 [P] Create barracks.tres building data in `data/buildings/barracks.tres`
- [ ] T003 [P] Create training_grounds.tres building data in `data/buildings/training_grounds.tres`
- [ ] T004 [P] Create academy.tres building data in `data/buildings/academy.tres`
- [ ] T005 [P] Create mine.tres building data in `data/buildings/mine.tres`
- [ ] T006 [P] Create shield_wall.tres perk data in `data/perks/shield_wall.tres`
- [ ] T007 [P] Create vanguard.tres perk data in `data/perks/vanguard.tres`
- [ ] T008 [P] Create dragonslayer.tres perk data in `data/perks/dragonslayer.tres`
- [ ] T009 [P] Create steel_grip.tres perk data in `data/perks/steel_grip.tres`
- [ ] T010 [P] Create powerful_thrust.tres perk data in `data/perks/powerful_thrust.tres`
- [ ] T011 [P] Create duelist.tres perk data in `data/perks/duelist.tres`
- [ ] T012 [P] Create fast_learner.tres perk data in `data/perks/fast_learner.tres`
- [ ] T013 [P] Create mentor.tres perk data in `data/perks/mentor.tres`

---

## Phase 2: Foundational

**Goal**: Extend TownCore with core infrastructure for new systems.

### TownCore Infrastructure

- [ ] T014 Add private variables for unlocked perks, population status, worker assignments in `core/town_core.gd`
- [ ] T015 Add caching variables for global bonuses in `core/town_core.gd`
- [ ] T016 Implement `_recalculate_global_bonuses()` method in `core/town_core.gd`
- [ ] T017 Implement `get_global_defense_bonus()` method in `core/town_core.gd`
- [ ] T018 Implement `get_global_damage_bonus()` method in `core/town_core.gd`
- [ ] T019 Implement `get_global_xp_bonus()` method in `core/town_core.gd`
- [ ] T020 Implement `_check_unlocked_perks()` method in `core/town_core.gd`
- [ ] T021 Implement `get_unlocked_perks()` method in `core/town_core.gd`
- [ ] T022 Implement `is_perk_unlocked()` method in `core/town_core.gd`
- [ ] T023 Modify `try_upgrade_building()` to check perk unlocks in `core/town_core.gd`
- [ ] T024 Add new signals to EventBus in `core/event_bus.gd`: `perk_unlocked`, `building_worker_assigned`, `building_worker_removed`

### Building State Extensions

- [ ] T025 Extend `_buildings` structure to include `workers` field in `core/town_core.gd`
- [ ] T026 Update `_init_default_buildings()` to initialize `workers` field in `core/town_core.gd`

---

## Phase 3: User Story 1 - Barracks (Defense + Perks)

**Goal**: Implement Barracks building with flat defense bonus and defensive perk unlocks.

**Independent Test Criteria**: 
- Barracks level 1 gives +1 defense to all heroes
- Barracks level 5 unlocks Shield Wall perk
- Barracks level 10 unlocks Vanguard perk
- Barracks level 15 unlocks Dragonslayer perk
- Defense applies in battle: `final_damage = max(1, raw_damage - effective_defense)`

### HeroCore Integration

- [ ] T027 [US1] Implement `get_hero_defense()` method in `core/hero_core.gd`
- [ ] T028 [US1] Implement `get_defense_bonus_from_perks()` helper method in `core/hero_core.gd`
- [ ] T029 [US1] Modify `get_available_perks_for_hero()` to include unlocked perks in `core/hero_core.gd`

### BattleCore Integration

- [ ] T030 [US1] Find damage calculation location (likely `core/hero_core.gd` `take_damage()` method)
- [ ] T031 [US1] Modify damage formula to use flat defense: `max(1, raw_damage - effective_defense)` in `core/hero_core.gd`

### Testing

- [ ] T032 [US1] Test Barracks level 1 gives +1 defense to all heroes
- [ ] T033 [US1] Test Barracks level 5 unlocks Shield Wall perk
- [ ] T034 [US1] Test defense formula: damage reduced by defense, minimum 1 damage

---

## Phase 4: User Story 2 - Training Grounds (Damage + Perks)

**Goal**: Implement Training Grounds building with global damage bonus and offensive perk unlocks.

**Independent Test Criteria**:
- Training Grounds level 1 gives +5% damage to all heroes
- Training Grounds level 5 unlocks Steel Grip perk
- Training Grounds level 10 unlocks Powerful Thrust perk
- Training Grounds level 15 unlocks Duelist perk
- Damage formula: `base * (1 + training_bonus + perks + items)`

### HeroCore Integration

- [ ] T035 [US2] Modify `get_hero_damage()` to include global damage bonus from TownCore in `core/hero_core.gd`
- [ ] T036 [US2] Implement `get_damage_bonus_from_perks()` helper method in `core/hero_core.gd`
- [ ] T037 [US2] Ensure damage formula is additive: `base * (1 + sum_of_all_bonuses)` in `core/hero_core.gd`

### Testing

- [ ] T038 [US2] Test Training Grounds level 1 gives +5% damage to all heroes
- [ ] T039 [US2] Test Training Grounds level 5 unlocks Steel Grip perk
- [ ] T040 [US2] Test additive damage formula with multiple bonuses

---

## Phase 5: User Story 3 - Academy (XP + Perks)

**Goal**: Implement Academy building with global XP bonus and progression perk unlocks.

**Independent Test Criteria**:
- Academy level 1 gives +10% XP gain to all heroes
- Academy level 5 unlocks Fast Learner perk
- Academy level 10 unlocks Mentor perk
- XP formula: `base_xp * (1 + academy_bonus + hero_xp_perks)`

### HeroCore Integration

- [ ] T041 [US3] Implement `get_hero_xp_gain_multiplier()` method in `core/hero_core.gd`
- [ ] T042 [US3] Implement `get_xp_bonus_from_perks()` helper method in `core/hero_core.gd`
- [ ] T043 [US3] Find XP gain location and apply multiplier (likely in `core/hero_core.gd` or `core/battle_core.gd`)

### Testing

- [ ] T044 [US3] Test Academy level 1 gives +10% XP gain to all heroes
- [ ] T045 [US3] Test Academy level 5 unlocks Fast Learner perk
- [ ] T046 [US3] Test XP formula with Academy bonus

---

## Phase 6: User Story 4 - Worker System

**Goal**: Implement worker assignment system for economic buildings.

**Independent Test Criteria**:
- Can assign FREE people as workers to Farm/Mine/Tavern
- Can remove workers from buildings
- Workers increase production: `base * (1 + 0.5 * workers)`
- Worker count limited by building level
- Production recalculates when workers change

### TownCore Worker Management

- [ ] T047 [US4] Implement `assign_worker()` method in `core/town_core.gd`
- [ ] T048 [US4] Implement `remove_worker()` method in `core/town_core.gd`
- [ ] T049 [US4] Implement `get_building_workers()` method in `core/town_core.gd`
- [ ] T050 [US4] Implement `get_available_workers()` method in `core/town_core.gd`
- [ ] T051 [US4] Implement `get_building_food_production()` with worker multiplier in `core/town_core.gd`
- [ ] T052 [US4] Implement `get_building_gold_production()` with worker multiplier in `core/town_core.gd`
- [ ] T053 [US4] Modify `get_food_production()` to use `get_building_food_production()` in `core/town_core.gd`
- [ ] T054 [US4] Modify `get_passive_gold_production()` to use `get_building_gold_production()` in `core/town_core.gd`

### Population Initialization

- [ ] T055 [US4] Implement `_initialize_population()` method in `core/town_core.gd`
- [ ] T056 [US4] Call `_initialize_population()` in `_ready()` or `_init_default_buildings()` in `core/town_core.gd`

### Testing

- [ ] T057 [US4] Test assigning worker to Farm increases food production by 50%
- [ ] T058 [US4] Test worker limit equals building level
- [ ] T059 [US4] Test removing worker decreases production

---

## Phase 7: User Story 5 - Population Integration

**Goal**: Integrate hero creation and death with population system.

**Independent Test Criteria**:
- Creating hero decreases `current_population` by 1
- Permanent hero death decreases `current_population` by 1
- Cannot create hero if `current_population >= max_population`
- Population status tracks FREE/WORKER/HERO

### HeroCore Integration

- [ ] T060 [US5] Modify `try_recruit_hero()` to check population limit in `core/hero_core.gd`
- [ ] T061 [US5] Modify `try_recruit_hero()` to decrease population when creating hero in `core/hero_core.gd`
- [ ] T062 [US5] Find permanent death location and add population decrease in `core/hero_core.gd`

### TownCore Population Management

- [ ] T063 [US5] Implement `set_person_status()` or similar method to change population status in `core/town_core.gd`
- [ ] T064 [US5] Implement `decrease_population()` or similar method in `core/town_core.gd`
- [ ] T065 [US5] Update `get_population_used()` to count HERO status people in `core/town_core.gd`

### Testing

- [ ] T066 [US5] Test creating hero decreases population
- [ ] T067 [US5] Test cannot create hero when population full
- [ ] T068 [US5] Test permanent death decreases population

---

## Phase 8: User Story 6 - Expanded Perk Pool

**Goal**: Ensure unlocked perks are available to all heroes during level-up.

**Independent Test Criteria**:
- Unlocked perks appear in perk selection pool for all heroes
- Base perks + unlocked perks = available pool
- Perks already owned by hero are excluded from selection

### HeroCore Perk Pool

- [ ] T069 [US6] Modify `get_available_perks_for_hero()` to merge base + unlocked perks in `core/hero_core.gd`
- [ ] T070 [US6] Implement `_get_base_perk_pool()` helper method in `core/hero_core.gd`
- [ ] T071 [US6] Ensure unlocked perks are excluded if hero already has them in `core/hero_core.gd`

### EventBus Integration

- [ ] T072 [US6] Subscribe HeroCore to `EventBus.perk_unlocked` signal in `core/hero_core.gd`
- [ ] T073 [US6] Handle perk unlock event (refresh perk pool cache if needed) in `core/hero_core.gd`

### Testing

- [ ] T074 [US6] Test unlocked perk appears in hero level-up selection
- [ ] T075 [US6] Test base perks + unlocked perks = available pool
- [ ] T076 [US6] Test hero cannot select perk they already own

---

## Phase 9: Save/Load

**Goal**: Persist worker assignments, unlocked perks, and population status.

### TownCore Save/Load

- [ ] T077 Extend `get_save_data()` to include unlocked_perks, population_status, worker_assignments in `core/town_core.gd`
- [ ] T078 Extend `apply_save_data()` to restore unlocked_perks, population_status, worker_assignments in `core/town_core.gd`
- [ ] T079 Add validation for loaded worker assignments (workers <= level) in `core/town_core.gd`
- [ ] T080 Add validation for loaded population status (current <= max) in `core/town_core.gd`

### Testing

- [ ] T081 Test saving and loading worker assignments
- [ ] T082 Test saving and loading unlocked perks
- [ ] T083 Test saving and loading population status
- [ ] T084 Test backward compatibility with old save files

---

## Phase 10: Polish & Cross-Cutting

**Goal**: Final integration, edge cases, and documentation.

### Edge Cases & Validation

- [ ] T085 Add null checks for TownCore in HeroCore methods (graceful degradation) in `core/hero_core.gd`
- [ ] T086 Add validation for worker assignments (max_workers check) in `core/town_core.gd`
- [ ] T087 Add validation for population status transitions in `core/town_core.gd`
- [ ] T088 Handle case when building data missing unlocked_perks field (backward compatibility) in `core/town_core.gd`

### Documentation

- [ ] T089 Update `docs/perks_list.md` with new 8 perks (shield_wall, vanguard, dragonslayer, steel_grip, powerful_thrust, duelist, fast_learner, mentor)
- [ ] T090 Document new TownCore API methods in code comments
- [ ] T091 Document new HeroCore API methods in code comments

### Performance

- [ ] T092 Ensure global bonuses cache is invalidated only when needed in `core/town_core.gd`
- [ ] T093 Optimize `get_available_perks_for_hero()` to avoid repeated TownCore calls in `core/hero_core.gd`

---

## Dependencies

### Story Completion Order

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
Phase 3 (US1: Barracks) ──┐
Phase 4 (US2: Training) ───┼──→ Phase 6 (US4: Workers)
Phase 5 (US3: Academy) ───┘         ↓
                              Phase 7 (US5: Population)
Phase 8 (US6: Perk Pool) ←──────────┘
    ↓
Phase 9 (Save/Load)
    ↓
Phase 10 (Polish)
```

### Parallel Execution Opportunities

**After Phase 2**:
- US1, US2, US3 can be implemented in parallel (different buildings, no dependencies)
- Tasks T027-T046 can be parallelized by user story

**Within each User Story**:
- Data creation tasks (T002-T013) can be parallelized
- Helper methods can be implemented in parallel (T028, T036, T042)

---

## Task Summary

**Total Tasks**: 93

**Tasks by Phase**:
- Phase 1 (Setup): 13 tasks
- Phase 2 (Foundational): 13 tasks
- Phase 3 (US1): 8 tasks
- Phase 4 (US2): 6 tasks
- Phase 5 (US3): 6 tasks
- Phase 6 (US4): 13 tasks
- Phase 7 (US5): 9 tasks
- Phase 8 (US6): 8 tasks
- Phase 9 (Save/Load): 8 tasks
- Phase 10 (Polish): 9 tasks

**Parallelizable Tasks**: 25+ (marked with [P])

**MVP Scope**: All phases (US1-US6 are core functionality)

---

## Independent Test Criteria Summary

### US1: Barracks
- ✅ Barracks gives +1 defense per level to all heroes
- ✅ Perks unlock at levels 5/10/15
- ✅ Flat defense formula works: `max(1, raw_damage - defense)`

### US2: Training Grounds
- ✅ Training Grounds gives +5% damage per level to all heroes
- ✅ Perks unlock at levels 5/10/15
- ✅ Additive damage formula: `base * (1 + sum_of_bonuses)`

### US3: Academy
- ✅ Academy gives +10% XP per level to all heroes
- ✅ Perks unlock at levels 5/10
- ✅ XP formula: `base_xp * (1 + academy_bonus + perks)`

### US4: Workers
- ✅ Can assign/remove workers to economic buildings
- ✅ Workers increase production by 50% each
- ✅ Worker limit = building level

### US5: Population
- ✅ Hero creation decreases population
- ✅ Permanent death decreases population
- ✅ Cannot create hero when population full

### US6: Perk Pool
- ✅ Unlocked perks appear in hero level-up selection
- ✅ Base + unlocked = available pool
- ✅ Owned perks excluded from selection

---

## Notes

- All tasks include exact file paths for implementation
- Tasks follow strict checklist format: `- [ ] T### [P?] [US?] Description with file path`
- Each user story is independently testable
- MVP includes all user stories (core functionality)
- Backward compatibility maintained throughout

