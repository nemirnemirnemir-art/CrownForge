# Quickstart: Mine Field Scene - Living Location with Workers

**Phase**: 1 - Design  
**Date**: 2025-12-04  
**Status**: ✅ Complete

## Getting Started

Это руководство поможет быстро понять и начать реализацию сцены шахты.

## Project Structure

### 1. Core Infrastructure

Создайте структуру модулей MineCore:

```
res://
├── core/
│   └── mine/
│       ├── MineCore.gd              # Main autoload singleton
│       ├── MineRegistry.gd          # Ore and worker registration
│       ├── MineShardDelivery.gd     # Shard delivery tracking
│       ├── MineOfflineProgress.gd   # Offline simulation
│       ├── MineSceneSnapshot.gd     # Scene snapshot for save
│       ├── MineSceneState.gd        # Scene state management
│       ├── MineScenePersistence.gd  # Snapshot save/restore
│       └── MineSaveLoad.gd          # Save/Load integration
```

### 2. Scene Structure

Создайте сцены для шахты:

```
res://
├── scenes/
│   └── mine/
│       ├── MineField.tscn           # Main mine scene
│       ├── Ore.tscn                 # Ore deposit (4 instances)
│       ├── Miner.tscn               # Miner worker
│       ├── Carrier.tscn             # Carrier worker
│       ├── Cart.tscn                # Cart worker
│       └── Shard.tscn               # Shard on ground
```

### 3. Scripts

Создайте скрипты для рабочих:

```
res://
├── scripts/
│   └── mine/
│       ├── Ore.gd                   # Ore logic
│       ├── Miner.gd                 # Miner state machine
│       ├── Carrier.gd               # Carrier state machine
│       ├── Cart.gd                  # Cart state machine
│       └── Shard.gd                 # Shard pickup logic
```

---

## Implementation Order

### Step 1: MineCore Autoload (Foundation)

1. Create `core/mine/MineCore.gd`
2. Add as autoload in Project Settings → Autoload
   - Name: `MineCore`
   - Path: `res://core/mine/MineCore.gd`
   - Enable "Singleton"
3. Implement basic structure:
   ```gdscript
   extends Node
   
   # Workers
   var miners_count: int = 0
   var carriers_count: int = 0
   var carts_count: int = 0
   
   # Upgrades
   var powerful_pickaxe_level: int = 0  # 0-5
   var sturdy_cart_level: int = 0       # 0-6
   var comfortable_boots_level: int = 0 # 0-10
   
   # Scene state
   var is_on_mine_scene: bool = false
   ```
4. Create module classes (MineRegistry, MineShardDelivery, etc.)
5. Initialize modules in `_ready()`

**Test**: Verify MineCore is accessible from any script via `MineCore.miners_count`

---

### Step 2: Workers Management

1. Implement `get_max_workers_for_level(mine_level: int) -> Dictionary`
   - Formula: каждый уровень добавляет +1 в один из типов по кругу
   - lvl 1: {miners: 1, carriers: 1, carts: 1}
   - lvl 2: {miners: 2, carriers: 1, carts: 1}
   - lvl 3: {miners: 2, carriers: 2, carts: 1}
2. Implement `set_miners_count(count: int) -> bool` with TownCore population check
3. Implement `set_carriers_count(count: int) -> bool` with TownCore population check
4. Implement `set_carts_count(count: int) -> bool` with TownCore population check
5. Add UI to Mine building in town (3 counter rows with [+ / −] buttons)

**Test**: Can set worker counts through UI, TownCore population is checked

---

### Step 3: Upgrades System

1. Implement upgrade unlock checks based on mine level:
   - Powerful Pickaxe: levels 20, 40, 60, 80, 100
   - Sturdy Cart: levels 15, 30, 45, 60, 75, 90
   - Comfortable Boots: levels 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
2. Implement upgrade methods:
   - `upgrade_powerful_pickaxe() -> bool`
   - `upgrade_sturdy_cart() -> bool`
   - `upgrade_comfortable_boots() -> bool`
3. Implement upgrade effects:
   - Powerful Pickaxe: chance for second shard = `0.05 * level`
   - Sturdy Cart: capacity = `6 + level`
   - Comfortable Boots: speed multiplier = `1 + (0.05 * level)`

**Test**: Upgrades unlock at correct mine levels, effects apply correctly

---

### Step 4: Scene Structure & Ores

1. Create `scenes/mine/MineField.tscn` (Node2D root)
2. Add structure:
   - Background layer
   - WorldYSort node
   - OreContainer (Node2D)
   - WorkersContainer (Node2D)
   - ShardsContainer (Node2D)
   - UI layer (Control)
3. Create `scenes/mine/Ore.tscn`:
   - StaticBody2D or Area2D root
   - Sprite2D (PNG 128×128)
   - 4 Marker2D nodes for slots (circle around ore, ~32px)
4. Create `scripts/mine/Ore.gd`:
   - Implement slot management (get_free_slot, occupy_slot, free_slot)
5. Place 4 Ore instances in MineField scene editor
6. Register ores in MineRegistry

**Test**: Scene loads, 4 ores visible, slots work correctly

---

### Step 5: Miner Implementation

1. Create `scenes/mine/Miner.tscn` (CharacterBody2D or Area2D)
2. Create `scripts/mine/Miner.gd` with state machine:
   - States: REST_AFTER_WORK → SCAN_FOR_ORE → MOVE_TO_ORE_SLOT → MINE_HITS
3. Implement `scan_for_ore()`: choose random ore from 4 available
4. Implement slot selection: find free slot for chosen ore
5. Implement `start_mining()`: randomize hits_count (3-12)
6. Implement `mine_hit()`: spawn shard (check limit 200), apply powerful pickaxe chance
7. Implement hit timer: 2 seconds between hits
8. Spawn miners based on `MineCore.miners_count`

**Test**: Miner chooses ore, goes to slot, mines, spawns shards

---

### Step 6: Shard System

1. Create `scenes/mine/Shard.tscn` (Area2D)
   - Sprite2D (black brick PNG placeholder)
   - CollisionShape2D for pickup
2. Reuse meat drop mechanics from hunting:
   - Shards fly out in random direction (12 directions)
3. Implement shard limit: max 200 shards on scene
4. Implement shard reservation: first carrier to pick reserves shard
5. Implement limit message: "Too many stones on the ground! Collect them first."
6. Track shard count globally in MineField scene

**Test**: Shards spawn when miner hits, limit works, reservation works

---

### Step 7: Carrier Implementation

1. Create `scenes/mine/Carrier.tscn` (CharacterBody2D or Area2D)
2. Create `scripts/mine/Carrier.gd` with state machine:
   - States: REST_AFTER_WORK → SCAN_FOR_STONES → MOVE_TO_STONE → CARRY_TO_CART_OR_WAREHOUSE
3. Implement `scan_for_stones()`: find free unreserved shard (every 5 seconds)
4. Implement `pickup_shard()`: reserve and pick up shard
5. Implement `find_nearest_cart()`: find cart that is not full and not at warehouse
6. Implement delivery logic:
   - If cart found: deliver to cart (increase cart load)
   - If no cart: deliver directly to warehouse (EconomyCore.add_forge_cores(1))
7. Apply comfortable boots speed multiplier when carrying
8. Spawn carriers based on `MineCore.carriers_count`

**Test**: Carrier finds shard, picks up, delivers to cart or warehouse

---

### Step 8: Cart Implementation

1. Create `scenes/mine/Cart.tscn` (CharacterBody2D or Area2D)
2. Create `scripts/mine/Cart.gd` with state machine:
   - States: MOVE_TO_ORE → IDLE_NEAR_ORE → MOVE_TO_WAREHOUSE → UNLOAD
3. Implement `choose_random_ore()`: select random ore (not nearest)
4. Implement `move_to_ore()`: move to ore at ~200px distance
5. Implement `idle_near_ore()`: wait for carriers to deliver shards
6. Implement `accept_shard()`: increase load by 1
7. Implement capacity: `6 + sturdy_cart_level`
8. When load >= capacity: move to warehouse
9. Implement `unload()`: call `EconomyCore.add_forge_cores(load)`, reset load to 0
10. Spawn carts based on `MineCore.carts_count`

**Test**: Cart accumulates shards, moves to warehouse when full, unloads to forge_cores

---

### Step 9: Online/Offline System

1. Implement `start_tracking()` in MineCore:
   - Set `is_on_mine_scene = true`
   - Calculate offline progress if dt > 0
   - Start online simulation
2. Implement `stop_tracking()` in MineCore:
   - Set `is_on_mine_scene = false`
   - Save timestamp
   - Save state for offline calculation
3. Implement offline progress calculation:
   - Formula based on: workers count, upgrade levels, time passed
   - Calculate forge_cores earned offline
   - Call `EconomyCore.add_forge_cores()` with calculated amount
4. Add `MineCore.start_tracking()` call in MineField `_ready()`
5. Add `MineCore.stop_tracking()` call in MineField `_exit_tree()`
6. Disable offline calculation when `is_on_mine_scene == true`

**Test**: Offline progress works when scene closed, online simulation works when open

---

### Step 10: Save/Load System

1. Implement `get_save_data() -> Dictionary` in MineSaveLoad:
   - Save: workers counts, upgrade levels, is_on_mine_scene, timestamp
2. Implement `load_save_data(data: Dictionary) -> void` in MineSaveLoad:
   - Load: workers counts, upgrade levels, is_on_mine_scene, timestamp
3. Integrate with SaveCore: add "mine_state" block to save data
4. Implement scene snapshot saving:
   - Save: worker positions, states, ore assignments, cart loads
5. Implement scene snapshot restoration:
   - Restore: worker positions, states, ore assignments, cart loads
   - Apply time delta (dt) for offline progress simulation

**Test**: Save/load works correctly, snapshot restores correctly

---

### Step 11: UI Integration

1. Add forge_cores display to MineField UI:
   - Read from `EconomyCore.get_forge_cores()`
2. Implement shard delivery tracking:
   - Track: total delivered, session time, shards per minute
3. Add statistics display:
   - "За сессию" (total delivered this session)
   - "За минуту" (shards per minute)
4. Add optional displays:
   - Number of shards on ground
   - Number of shards in carts
5. Implement shard limit message:
   - Show "Too many stones on the ground! Collect them first." at center when limit reached

**Test**: UI displays correct information, updates correctly

---

### Step 12: Scene Integration & Navigation

1. Add click handler to Mine building in town menu:
   - Open MineField scene
2. Add MineField scene to main menu navigation
3. Implement return logic:
   - Remember where player came from (town or menu)
   - Return to previous location on scene exit
4. Verify `MineCore.start_tracking()` called in `_ready()`
5. Verify `MineCore.stop_tracking()` called in `_exit_tree()`

**Test**: Can enter from town and menu, exit returns correctly

---

## Key Integration Points

### EconomyCore
- Use `EconomyCore.get_forge_cores()` to read current forge_cores
- Use `EconomyCore.add_forge_cores(amount)` to add shards (when cart unloads or carrier delivers directly)

### TownCore
- Use `TownCore` to check available population before assigning workers
- Use `TownCore` to return workers to population pool when decreasing count
- Get mine building level from TownCore for upgrade unlocks and worker limits

### SaveCore
- Add "mine_state" block to save data
- Save/load workers counts, upgrade levels, scene state

### Movement System
- Reuse existing farm/hunting movement system (no NavMesh)
- Use same movement logic for all workers

### Shard Spawning
- Reuse meat drop mechanics from hunting
- Replace sprite/resource, keep same physics

---

## Testing Checklist

- [ ] All workers spawn correctly based on counts
- [ ] Miners mine ores and spawn shards
- [ ] Carriers pick up shards and deliver to carts or warehouse
- [ ] Carts accumulate shards and unload to forge_cores
- [ ] Shard limit (200) works correctly
- [ ] Upgrades apply correctly
- [ ] Offline progress calculates correctly
- [ ] Online simulation works when scene is open
- [ ] Save/load works correctly
- [ ] Scene snapshot saves and restores correctly
- [ ] UI displays correct information
- [ ] Navigation works from town and menu
- [ ] Performance is acceptable with 200 shards and 10+ workers

---

## Common Pitfalls

1. **Shard Limit**: Don't forget to check limit before spawning shards
2. **Reservation System**: Make sure shards are properly reserved for carriers
3. **Offline Calculation**: Disable offline when scene is open, enable when closed
4. **Population Check**: Always check TownCore before assigning workers
5. **Upgrade Unlocks**: Check mine level before allowing upgrades
6. **State Machines**: Make sure all state transitions are handled correctly
7. **Save/Load**: Don't forget to save/load scene snapshot for restoration

---

## Next Steps

After completing all steps:
1. Test all functionality thoroughly
2. Optimize performance if needed (especially with 200 shards)
3. Add polish (animations, visual effects)
4. Update documentation if needed

