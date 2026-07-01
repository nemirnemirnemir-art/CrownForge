# Implementation Tasks: Mine Field Scene - Living Location with Workers

**Feature**: 022-mine-field  
**Branch**: `022-mine-field`  
**Created**: 2025-12-04  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

Создать сцену шахты как отдельную «живую» локацию с тремя типами рабочих (шахтёры, носильщики, тележечники), системой добычи осколков, апгрейдами шахты, онлайн/оффлайн симуляцией и интеграцией с существующими системами.

**Total Tasks**: ~80+  
**MVP Scope**: All tasks (complete implementation)

---

## Dependencies

### Implementation Order

1. **Core Infrastructure** (MineCore + Modules) → **No dependencies** (foundation)
2. **Workers Management** → **Depends on**: Core Infrastructure, TownCore
3. **Upgrades System** → **Depends on**: Core Infrastructure
4. **Scene Structure & Ores** → **Depends on**: Core Infrastructure
5. **Miner Implementation** → **Depends on**: Scene Structure, Upgrades
6. **Shard System** → **Depends on**: Miner Implementation
7. **Carrier Implementation** → **Depends on**: Shard System, Upgrades
8. **Cart Implementation** → **Depends on**: Carrier Implementation, Upgrades
9. **Online/Offline System** → **Depends on**: Core Infrastructure, Workers, Upgrades
10. **Save/Load System** → **Depends on**: Online/Offline System, SaveCore
11. **UI Integration** → **Depends on**: Shard System, Online/Offline System
12. **Scene Integration** → **Depends on**: Online/Offline System, Navigation

### Parallel Execution Opportunities

- **Module creation** can be done in parallel (MineRegistry, MineShardDelivery, etc.)
- **Scene creation** can be done in parallel with module implementation
- **UI elements** can be created in parallel with gameplay logic

---

## Phase 2.1: Core Infrastructure (MineCore + Modules)

**Goal**: Создать MineCore автолоад и базовые модули

**Independent Test**: MineCore доступен как автолоад синглтон, модули инициализируются корректно

- [ ] T001 Create `core/mine/` directory structure
- [ ] T002 Create `core/mine/MineCore.gd` file with basic class structure (extends Node)
- [ ] T003 Add MineCore as autoload singleton in Project Settings → Autoload (name: "MineCore", path: "res://core/mine/MineCore.gd")
- [ ] T004 Create `core/mine/MineRegistry.gd` module class
- [ ] T005 Create `core/mine/MineShardDelivery.gd` module class
- [ ] T006 Create `core/mine/MineOfflineProgress.gd` module class
- [ ] T007 Create `core/mine/MineSceneSnapshot.gd` module class
- [ ] T008 Create `core/mine/MineSceneState.gd` module class
- [ ] T009 Create `core/mine/MineScenePersistence.gd` module class
- [ ] T010 Create `core/mine/MineSaveLoad.gd` module class
- [ ] T011 Implement module preloads in MineCore (const MineRegistry = preload(...))
- [ ] T012 Implement module instances in MineCore (var _registry: Node, etc.)
- [ ] T013 Implement `_initialize_modules()` in MineCore to create all module instances
- [ ] T014 Implement basic `_ready()` in MineCore with module initialization
- [ ] T015 Add debug logging to MineCore initialization (`[MineCore] Initializing modules...`)

---

## Phase 2.2: Workers Management & UI Integration

**Goal**: Реализовать управление рабочими и UI в городе

**Independent Test**: Можно установить количество рабочих через MineCore, UI отображает корректные значения

- [ ] T016 Implement `miners_count: int`, `carriers_count: int`, `carts_count: int` in MineCore
- [ ] T017 Implement `get_max_workers_for_level(mine_level: int) -> Dictionary` in MineCore (FR-055, FR-056)
  - Formula: каждый уровень добавляет +1 в один из трёх типов по кругу
  - lvl 1: {miners: 1, carriers: 1, carts: 1}
  - lvl 2: {miners: 2, carriers: 1, carts: 1}
  - lvl 3: {miners: 2, carriers: 2, carts: 1}
  - и т.д.
- [ ] T018 Implement `set_miners_count(count: int) -> bool` in MineCore with TownCore population check
- [ ] T019 Implement `set_carriers_count(count: int) -> bool` in MineCore with TownCore population check
- [ ] T020 Implement `set_carts_count(count: int) -> bool` in MineCore with TownCore population check
- [ ] T021 Integrate with TownCore to check available population before assigning workers
- [ ] T022 Integrate with TownCore to return workers to population pool when decreasing count
- [ ] T023 Find building UI for "Mine" in town menu
- [ ] T024 Add three counter rows to Mine building UI: "Шахтёры", "Носильщики", "Тележки" with [+ / −] buttons
- [ ] T025 Connect UI buttons to MineCore methods (set_miners_count, set_carriers_count, set_carts_count)
- [ ] T026 Update UI to display current worker counts from MineCore
- [ ] T027 Update UI to display max worker counts based on mine level (get_max_workers_for_level)
- [ ] T028 Add validation: prevent setting workers above max for current mine level
- [ ] T029 Add validation: prevent setting workers if not enough population available

---

## Phase 2.3: Upgrades System

**Goal**: Реализовать систему апгрейдов шахты

**Independent Test**: Можно повысить уровень апгрейда, эффекты применяются корректно

- [ ] T030 Implement `powerful_pickaxe_level: int` in MineCore (0-5)
- [ ] T031 Implement `sturdy_cart_level: int` in MineCore (0-6)
- [ ] T032 Implement `comfortable_boots_level: int` in MineCore (0-10)
- [ ] T033 Implement `get_upgrade_levels() -> Dictionary` in MineCore returning all upgrade levels
- [ ] T034 Implement `upgrade_powerful_pickaxe() -> bool` in MineCore with mine level check (FR-067)
  - Unlock at mine levels: 20, 40, 60, 80, 100
- [ ] T035 Implement `upgrade_sturdy_cart() -> bool` in MineCore with mine level check (FR-074)
  - Unlock at mine levels: 15, 30, 45, 60, 75, 90
- [ ] T036 Implement `upgrade_comfortable_boots() -> bool` in MineCore with mine level check (FR-079)
  - Unlock at mine levels: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
- [ ] T037 Implement powerful pickaxe chance calculation: `0.05 * powerful_pickaxe_level` (FR-066)
- [ ] T038 Implement sturdy cart capacity calculation: `6 + sturdy_cart_level` (FR-072)
- [ ] T039 Implement comfortable boots speed multiplier: `1 + (0.05 * comfortable_boots_level)` (FR-078)
- [ ] T040 Add validation: prevent upgrading beyond max level for each upgrade type
- [ ] T041 Add validation: prevent upgrading if mine level not high enough

---

## Phase 2.4: Scene Structure & Ores

**Goal**: Создать базовую структуру сцены и породы

**Independent Test**: Сцена загружается, 4 породы отображаются корректно, слоты работают

- [ ] T042 Create `scenes/mine/` directory structure
- [ ] T043 Create `scenes/mine/MineField.tscn` scene with Node2D root
- [ ] T044 Add Background layer to MineField scene
- [ ] T045 Add WorldYSort node to MineField scene for proper rendering
- [ ] T046 Add OreContainer (Node2D) to MineField scene for ore placement
- [ ] T047 Add WorkersContainer (Node2D) to MineField scene for workers
- [ ] T048 Add ShardsContainer (Node2D) to MineField scene for shards on ground
- [ ] T049 Add UI layer to MineField scene (Control node)
- [ ] T050 Create `scenes/mine/Ore.tscn` scene with StaticBody2D or Area2D root
- [ ] T051 Add Sprite2D to Ore scene (PNG 128×128 placeholder)
- [ ] T052 Add 4 Marker2D nodes to Ore scene for slots (around ore, ~32px from center)
  - Slot positions: top, right, bottom, left (circle around ore)
- [ ] T053 Add script `scripts/mine/Ore.gd` to Ore scene
- [ ] T054 Implement `ore_id: String` property in Ore script
- [ ] T055 Implement `work_radius: float = 32.0` property in Ore script
- [ ] T056 Implement `slots: Array[Dictionary]` in Ore script with slot positions and occupied_by tracking
- [ ] T057 Implement `get_free_slot() -> int` method in Ore script (returns slot index or -1)
- [ ] T058 Implement `occupy_slot(slot_index: int, worker_id: String) -> void` in Ore script
- [ ] T059 Implement `free_slot(slot_index: int) -> void` in Ore script
- [ ] T060 Place 4 Ore instances in MineField scene editor at fixed positions
- [ ] T061 Register 4 ores in MineRegistry with IDs: "ore_1", "ore_2", "ore_3", "ore_4"
- [ ] T062 Implement `register_ore(data: OreData)` in MineRegistry
- [ ] T063 Implement `get_ore_data(ore_id: String) -> OreData` in MineRegistry
- [ ] T064 Implement `get_all_ores() -> Array[OreData]` in MineRegistry

---

## Phase 2.5: Miner Implementation

**Goal**: Реализовать логику шахтёра

**Independent Test**: Шахтёр выбирает породу, идёт к слоту, бьёт руду, спавнит осколки

- [ ] T065 Create `scenes/mine/Miner.tscn` scene with CharacterBody2D or Area2D root
- [ ] T066 Add Sprite2D to Miner scene (placeholder sprite)
- [ ] T067 Add script `scripts/mine/Miner.gd` to Miner scene
- [ ] T068 Implement state enum: `REST_AFTER_WORK`, `SCAN_FOR_ORE`, `MOVE_TO_ORE_SLOT`, `MINE_HITS`
- [ ] T069 Implement `current_state` variable in Miner script
- [ ] T070 Implement `target_ore_id: String` variable in Miner script
- [ ] T071 Implement `target_slot_index: int` variable in Miner script
- [ ] T072 Implement `hits_count: int` variable in Miner script (random 3-12)
- [ ] T073 Implement `current_hit: int` variable in Miner script
- [ ] T074 Implement `hit_timer: float` variable in Miner script (2 sec delay between hits)
- [ ] T075 Implement `scan_for_ore()` method: choose random ore from 4 available (FR-022)
- [ ] T076 Implement slot checking logic: find free slot for chosen ore (FR-023)
- [ ] T077 Implement `move_to_ore_slot()` method: move to target slot position
- [ ] T078 Implement `start_mining()` method: randomize hits_count (3-12), reset current_hit (FR-024)
- [ ] T079 Implement `mine_hit()` method: check shard limit, spawn shard if limit not reached (FR-027)
- [ ] T080 Implement powerful pickaxe logic: chance for second shard based on upgrade level (FR-068)
- [ ] T081 Implement hit timer logic: wait 2 seconds between hits (FR-026)
- [ ] T082 Implement state transitions: REST → SCAN → MOVE → MINE → REST (FR-021)
- [ ] T083 Implement `_process(delta)` in Miner script to handle state machine
- [ ] T084 Spawn miners on MineField scene based on `MineCore.miners_count`

---

## Phase 2.6: Shard System

**Goal**: Реализовать систему осколков

**Independent Test**: Осколки спавнятся при ударе шахтёра, подбираются носильщиками, лимит работает

- [ ] T085 Create `scenes/mine/Shard.tscn` scene with Area2D root
- [ ] T086 Add Sprite2D to Shard scene (black brick PNG placeholder)
- [ ] T087 Add CollisionShape2D to Shard scene for pickup detection
- [ ] T088 Add script `scripts/mine/Shard.gd` to Shard scene
- [ ] T089 Implement `shard_id: String` property in Shard script
- [ ] T090 Implement `is_reserved: bool` property in Shard script (for carrier reservation)
- [ ] T091 Implement `reserve_for_carrier(carrier_id: String) -> void` in Shard script
- [ ] T092 Implement shard spawn logic: reuse meat drop mechanics from hunting (FR-017)
  - Shards fly out in random direction (12 directions)
- [ ] T093 Implement global shard counter in MineField scene (track total shards on scene)
- [ ] T094 Implement shard limit check: max 200 shards on scene (FR-018)
- [ ] T095 Implement shard limit message: show "Too many stones on the ground! Collect them first." when limit reached (FR-019, FR-088)
- [ ] T096 Implement shard reservation system: first carrier to pick reserves shard (FR-032)
- [ ] T097 Implement shard pickup logic: carrier can pick reserved shard
- [ ] T098 Implement shard removal: remove shard from scene when picked up
- [ ] T099 Update shard counter when shard is spawned or removed

---

## Phase 2.7: Carrier Implementation

**Goal**: Реализовать логику носильщика

**Independent Test**: Носильщик находит осколок, подбирает, несёт к тележке или складу

- [ ] T100 Create `scenes/mine/Carrier.tscn` scene with CharacterBody2D or Area2D root
- [ ] T101 Add Sprite2D to Carrier scene (placeholder sprite)
- [ ] T102 Add script `scripts/mine/Carrier.gd` to Carrier scene
- [ ] T103 Implement state enum: `REST_AFTER_WORK`, `SCAN_FOR_STONES`, `MOVE_TO_STONE`, `CARRY_TO_CART_OR_WAREHOUSE`
- [ ] T104 Implement `current_state` variable in Carrier script
- [ ] T105 Implement `target_shard_id: String` variable in Carrier script
- [ ] T106 Implement `target_cart_id: String` variable in Carrier script (optional)
- [ ] T107 Implement `is_carrying: bool` variable in Carrier script
- [ ] T108 Implement `scan_timer: float` variable in Carrier script (5 sec scan period)
- [ ] T109 Implement `base_speed: float` variable in Carrier script (same as farm workers)
- [ ] T110 Implement `speed_while_carrying: float` variable in Carrier script (modified by comfortable boots)
- [ ] T111 Implement `scan_for_stones()` method: find free unreserved shard (FR-031, FR-032)
- [ ] T112 Implement `move_to_stone()` method: move to reserved shard position
- [ ] T113 Implement `pickup_shard()` method: pick up shard, set is_carrying = true (FR-036)
- [ ] T114 Implement `find_nearest_cart()` method: find cart that is not at warehouse and not full (FR-040)
- [ ] T115 Implement `deliver_to_cart()` method: add shard to cart load, set is_carrying = false (FR-041)
- [ ] T116 Implement `deliver_to_warehouse()` method: directly add forge_cores via EconomyCore (FR-042)
- [ ] T117 Implement comfortable boots speed calculation: `base_speed * (1 + 0.05 * comfortable_boots_level)` (FR-078)
- [ ] T118 Implement state transitions: REST → SCAN → MOVE → CARRY → REST (FR-029)
- [ ] T119 Implement `_process(delta)` in Carrier script to handle state machine
- [ ] T120 Implement movement logic: use same system as farm/hunting (FR-089)
- [ ] T121 Spawn carriers on MineField scene based on `MineCore.carriers_count`

---

## Phase 2.8: Cart Implementation

**Goal**: Реализовать логику тележечника

**Independent Test**: Тележка накапливает осколки, едет на склад, выгружает в forge_cores

- [ ] T122 Create `scenes/mine/Cart.tscn` scene with CharacterBody2D or Area2D root
- [ ] T123 Add Sprite2D to Cart scene (placeholder sprite)
- [ ] T124 Add script `scripts/mine/Cart.gd` to Cart scene
- [ ] T125 Implement state enum: `MOVE_TO_ORE`, `IDLE_NEAR_ORE`, `MOVE_TO_WAREHOUSE`, `UNLOAD`
- [ ] T126 Implement `current_state` variable in Cart script
- [ ] T127 Implement `target_ore_id: String` variable in Cart script
- [ ] T128 Implement `load: int` variable in Cart script (current shards in cart)
- [ ] T129 Implement `capacity: int` variable in Cart script (6 + sturdy_cart_level)
- [ ] T130 Implement `warehouse_position: Vector2` variable in Cart script
- [ ] T131 Implement `choose_random_ore()` method: select random ore (not nearest) (FR-045)
- [ ] T132 Implement `move_to_ore()` method: move to ore at ~200px distance (FR-046, FR-047)
- [ ] T133 Implement `idle_near_ore()` method: wait for carriers to deliver shards (FR-048)
- [ ] T134 Implement `accept_shard()` method: increase load by 1 when carrier delivers (FR-050)
- [ ] T135 Implement `check_if_full()` method: check if load >= capacity (FR-051)
- [ ] T136 Implement `move_to_warehouse()` method: move to warehouse position (FR-052)
- [ ] T137 Implement `unload()` method: call `EconomyCore.add_forge_cores(load)`, reset load to 0 (FR-053)
- [ ] T138 Implement sturdy cart capacity calculation: `6 + sturdy_cart_level` (FR-072)
- [ ] T139 Implement state transitions: MOVE_TO_ORE → IDLE → MOVE_TO_WAREHOUSE → UNLOAD → MOVE_TO_ORE (FR-044)
- [ ] T140 Implement `_process(delta)` in Cart script to handle state machine
- [ ] T141 Implement movement logic: use same system as farm/hunting
- [ ] T142 Spawn carts on MineField scene based on `MineCore.carts_count`

---

## Phase 2.9: Online/Offline System

**Goal**: Реализовать онлайн/оффлайн симуляцию

**Independent Test**: Оффлайн прогресс работает когда сцена закрыта, онлайн симуляция работает когда открыта

- [ ] T143 Implement `is_on_mine_scene: bool` variable in MineSceneState
- [ ] T144 Implement `last_seen_timestamp: float` variable in MineSceneState
- [ ] T145 Implement `start_tracking()` method in MineCore (FR-082)
  - Set is_on_mine_scene = true
  - Calculate offline progress if dt > 0
  - Start online simulation
- [ ] T146 Implement `stop_tracking()` method in MineCore (FR-085)
  - Set is_on_mine_scene = false
  - Save timestamp
  - Save state for offline calculation
- [ ] T147 Implement offline progress calculation in MineOfflineProgress (FR-083)
  - Formula based on: workers count, upgrade levels, time passed
  - Calculate forge_cores earned offline
  - Call EconomyCore.add_forge_cores() with calculated amount
- [ ] T148 Implement `save_state()` method in MineOfflineProgress to save current state
- [ ] T149 Implement `calculate_offline_earnings(dt: float)` method in MineOfflineProgress
- [ ] T150 Add call to `MineCore.start_tracking()` in MineField scene `_ready()` (FR-082)
- [ ] T151 Add call to `MineCore.stop_tracking()` in MineField scene `_exit_tree()` (FR-085)
- [ ] T152 Implement check: disable offline calculation when is_on_mine_scene == true (FR-083)
- [ ] T153 Implement check: disable online simulation when is_on_mine_scene == false

---

## Phase 2.10: Save/Load System

**Goal**: Реализовать сохранение/загрузку состояния шахты

**Independent Test**: Состояние шахты сохраняется и загружается корректно, снапшот восстанавливается

- [ ] T154 Implement `get_save_data() -> Dictionary` in MineSaveLoad
  - Save: workers counts, upgrade levels, is_on_mine_scene, timestamp
- [ ] T155 Implement `load_save_data(data: Dictionary) -> void` in MineSaveLoad
  - Load: workers counts, upgrade levels, is_on_mine_scene, timestamp
- [ ] T156 Integrate with SaveCore: add "mine_state" block to save data
- [ ] T157 Implement scene snapshot saving in MineSceneSnapshot
  - Save: worker positions, states, ore assignments, cart loads
- [ ] T158 Implement `save_scene_snapshot(data: Dictionary)` method in MineSceneSnapshot
- [ ] T159 Implement `get_scene_snapshot() -> Dictionary` method in MineSceneSnapshot
- [ ] T160 Implement scene snapshot restoration in MineScenePersistence
  - Restore: worker positions, states, ore assignments, cart loads
  - Apply time delta (dt) for offline progress simulation
- [ ] T161 Implement `restore_scene_snapshot(dt_seconds: float)` method in MineScenePersistence
- [ ] T162 Implement snapshot saving on scene exit in MineField scene
- [ ] T163 Implement snapshot restoration on scene enter in MineField scene (if dt > 0)
- [ ] T164 Test save/load when player is on mine scene
- [ ] T165 Test save/load when player is not on mine scene

---

## Phase 2.11: UI Integration

**Goal**: Реализовать UI сцены шахты

**Independent Test**: UI отображает forge_cores, статистику, сообщение при лимите

- [ ] T166 Add forge_cores display to MineField UI (read from EconomyCore.get_forge_cores()) (FR-087)
- [ ] T167 Implement shard delivery tracking in MineShardDelivery
  - Track: total delivered, session time, shards per minute
- [ ] T168 Add "за сессию" statistics display to MineField UI (FR-087)
- [ ] T169 Add "за минуту" statistics display to MineField UI (FR-087)
- [ ] T170 Implement `get_shards_per_minute() -> float` in MineShardDelivery
- [ ] T171 Implement `get_total_shards_delivered() -> int` in MineShardDelivery
- [ ] T172 Implement `get_session_time_seconds() -> float` in MineShardDelivery
- [ ] T173 Add optional display: number of shards on ground (FR-087)
- [ ] T174 Add optional display: number of shards in carts (FR-087)
- [ ] T175 Implement shard limit message UI: show "Too many stones on the ground! Collect them first." at center of screen (FR-088)
- [ ] T176 Update UI elements every frame or on events (forge_cores changed, shard delivered, etc.)

---

## Phase 2.12: Scene Integration & Navigation

**Goal**: Интегрировать сцену шахты в систему навигации

**Independent Test**: Можно войти на сцену шахты из города и меню, выход работает корректно

- [ ] T177 Find town menu building UI for "Mine" building
- [ ] T178 Add click handler to Mine building: open MineField scene (FR-001)
- [ ] T179 Find main menu navigation system
- [ ] T180 Add MineField scene to main menu navigation (FR-002)
- [ ] T181 Implement return logic: remember where player came from (town or menu) (FR-003)
- [ ] T182 Implement return to previous location on scene exit
- [ ] T183 Test navigation: enter from town, exit returns to town
- [ ] T184 Test navigation: enter from menu, exit returns to menu
- [ ] T185 Verify MineCore.start_tracking() is called in MineField._ready()
- [ ] T186 Verify MineCore.stop_tracking() is called in MineField._exit_tree()

---

## Testing Checklist

- [ ] All workers spawn correctly based on counts
- [ ] Miners mine ores and spawn shards
- [ ] Carriers pick up shards and deliver to carts or warehouse
- [ ] Carts accumulate shards and unload to forge_cores
- [ ] Shard limit (200) works correctly
- [ ] Upgrades apply correctly (powerful pickaxe, sturdy cart, comfortable boots)
- [ ] Offline progress calculates correctly
- [ ] Online simulation works when scene is open
- [ ] Save/load works correctly
- [ ] Scene snapshot saves and restores correctly
- [ ] UI displays correct information
- [ ] Navigation works from town and menu
- [ ] Performance is acceptable with 200 shards and 10+ workers

---

## Notes

- All movement should use existing farm/hunting movement system (no NavMesh)
- Shard spawning should reuse meat drop mechanics from hunting
- All forge_cores operations go through EconomyCore
- All population checks go through TownCore
- All save/load operations go through SaveCore

