# Data Model: Mine Field Scene - Living Location with Workers

**Phase**: 1 - Design  
**Date**: 2025-12-04  
**Status**: ✅ Complete

## Core Entities

### MineCore State

Central mine state managed by MineCore singleton.

**Properties**:
- `miners_count: int` - Number of assigned miners (minimum 0, maximum based on mine level)
- `carriers_count: int` - Number of assigned carriers (minimum 0, maximum based on mine level)
- `carts_count: int` - Number of assigned carts (minimum 0, maximum based on mine level)
- `powerful_pickaxe_level: int` - Powerful Pickaxe upgrade level (0-5, minimum 0, maximum 5)
- `sturdy_cart_level: int` - Sturdy Cart upgrade level (0-6, minimum 0, maximum 6)
- `comfortable_boots_level: int` - Comfortable Boots upgrade level (0-10, minimum 0, maximum 10)
- `is_on_mine_scene: bool` - Whether player is currently on mine scene (for online/offline logic)

**Relationships**:
- Owned by MineCore (singleton)
- Referenced by MineField scene for worker spawning
- Referenced by UI for display
- Saved to SaveData for persistence

**Validation**:
- `miners_count >= 0 && miners_count <= max_miners_for_level`
- `carriers_count >= 0 && carriers_count <= max_carriers_for_level`
- `carts_count >= 0 && carts_count <= max_carts_for_level`
- `powerful_pickaxe_level >= 0 && powerful_pickaxe_level <= 5`
- `sturdy_cart_level >= 0 && sturdy_cart_level <= 6`
- `comfortable_boots_level >= 0 && comfortable_boots_level <= 10`
- Total workers (miners + carriers + carts) must not exceed available population from TownCore

**Lifecycle**:
1. Initialized with default values (all 0) on game start
2. Updated when player assigns workers through UI
3. Updated when player upgrades mine
4. Saved to SaveData on state changes
5. Loaded from SaveData on game load

---

### Ore Data

Ore deposit state attached to Ore scene instance.

**Properties**:
- `ore_id: String` - Unique identifier for ore (e.g., "ore_1", "ore_2", "ore_3", "ore_4")
- `position: Vector2` - World position of ore (set in editor, fixed)
- `work_radius: float` - Work radius from center (default: 32.0 px)
- `slots: Array[Dictionary]` - Array of 4 slot dictionaries, each containing:
  - `position: Vector2` - Slot position (circle around ore, ~32px from center)
  - `occupied_by: String` - Worker ID occupying slot (null if free)

**Relationships**:
- Instance created in MineField scene editor (4 fixed instances)
- Referenced by MineRegistry for ore management
- Referenced by Miner for slot selection
- Slots occupied by Miner instances

**Validation**:
- `ore_id` must be unique ("ore_1" through "ore_4")
- `work_radius > 0`
- `slots.size() == 4`
- Each slot position must be ~32px from ore center
- `occupied_by` is either null (free) or valid worker ID

**Lifecycle**:
1. Created in scene editor at fixed positions
2. Registered in MineRegistry on scene load
3. Slots managed dynamically as miners work
4. Never destroyed (permanent ore deposits)

**Slot Management Methods**:
- `get_free_slot() -> int` - Returns slot index (0-3) or -1 if all occupied
- `occupy_slot(slot_index: int, worker_id: String) -> void` - Marks slot as occupied
- `free_slot(slot_index: int) -> void` - Marks slot as free

---

### Miner Data

Miner worker state attached to Miner scene instance.

**Properties**:
- `miner_id: String` - Unique identifier for miner (e.g., "miner_1", "miner_2")
- `current_state: int` - Current state enum (REST_AFTER_WORK, SCAN_FOR_ORE, MOVE_TO_ORE_SLOT, MINE_HITS)
- `position: Vector2` - Current world position
- `target_ore_id: String` - Currently targeted ore (null if none)
- `target_slot_index: int` - Currently targeted slot (0-3, -1 if none)
- `hits_count: int` - Number of hits in current mining session (3-12, randomized)
- `current_hit: int` - Current hit number in session (0 to hits_count)
- `hit_timer: float` - Time remaining until next hit (2 seconds between hits)
- `rest_timer: float` - Time remaining in rest state

**Relationships**:
- Instance created by MineField scene based on `MineCore.miners_count`
- References Ore for mining target
- Spawns Shard instances when mining

**Validation**:
- `miner_id` must be unique
- `current_state` must be valid state enum value
- `hits_count >= 3 && hits_count <= 12`
- `current_hit >= 0 && current_hit <= hits_count`
- `hit_timer >= 0.0`
- `target_ore_id` must be valid ore ID or null
- `target_slot_index` must be 0-3 or -1

**Lifecycle**:
1. Created when `MineCore.miners_count` increases
2. Spawned at spawn point in MineField scene
3. Cycles through states: REST → SCAN → MOVE → MINE → REST
4. Spawns shards during MINE state
5. Destroyed when `MineCore.miners_count` decreases

**State Transitions**:
- REST_AFTER_WORK → SCAN_FOR_ORE (after rest timer expires)
- SCAN_FOR_ORE → MOVE_TO_ORE_SLOT (when ore and slot selected)
- MOVE_TO_ORE_SLOT → MINE_HITS (when reached slot)
- MINE_HITS → REST_AFTER_WORK (when all hits completed)

---

### Carrier Data

Carrier worker state attached to Carrier scene instance.

**Properties**:
- `carrier_id: String` - Unique identifier for carrier (e.g., "carrier_1", "carrier_2")
- `current_state: int` - Current state enum (REST_AFTER_WORK, SCAN_FOR_STONES, MOVE_TO_STONE, CARRY_TO_CART_OR_WAREHOUSE)
- `position: Vector2` - Current world position
- `target_shard_id: String` - Currently targeted shard (null if none)
- `target_cart_id: String` - Currently targeted cart (null if delivering to warehouse)
- `is_carrying: bool` - Whether carrier is currently carrying a shard
- `scan_timer: float` - Time remaining until next scan (5 seconds)
- `base_speed: float` - Base movement speed (same as farm workers)
- `speed_while_carrying: float` - Movement speed when carrying (modified by comfortable boots upgrade)

**Relationships**:
- Instance created by MineField scene based on `MineCore.carriers_count`
- References Shard for pickup target
- References Cart for delivery target (optional)
- Delivers to EconomyCore when no cart available

**Validation**:
- `carrier_id` must be unique
- `current_state` must be valid state enum value
- `scan_timer >= 0.0`
- `base_speed > 0`
- `speed_while_carrying >= base_speed` (upgrade can only increase)
- `target_shard_id` must be valid shard ID or null
- `target_cart_id` must be valid cart ID or null
- `is_carrying == true` only when in CARRY state

**Lifecycle**:
1. Created when `MineCore.carriers_count` increases
2. Spawned at spawn point in MineField scene
3. Cycles through states: REST → SCAN → MOVE → CARRY → REST
4. Picks up shards and delivers to carts or warehouse
5. Destroyed when `MineCore.carriers_count` decreases

**State Transitions**:
- REST_AFTER_WORK → SCAN_FOR_STONES (after scan timer expires)
- SCAN_FOR_STONES → MOVE_TO_STONE (when shard found and reserved)
- MOVE_TO_STONE → CARRY_TO_CART_OR_WAREHOUSE (when shard picked up)
- CARRY_TO_CART_OR_WAREHOUSE → REST_AFTER_WORK (after delivery)

**Speed Calculation**:
- `speed_while_carrying = base_speed * (1 + 0.05 * comfortable_boots_level)`

---

### Cart Data

Cart worker state attached to Cart scene instance.

**Properties**:
- `cart_id: String` - Unique identifier for cart (e.g., "cart_1", "cart_2")
- `current_state: int` - Current state enum (MOVE_TO_ORE, IDLE_NEAR_ORE, MOVE_TO_WAREHOUSE, UNLOAD)
- `position: Vector2` - Current world position
- `target_ore_id: String` - Currently targeted ore (null if at warehouse)
- `load: int` - Current number of shards in cart (0 to capacity)
- `capacity: int` - Maximum shards cart can hold (6 + sturdy_cart_level)
- `warehouse_position: Vector2` - Position of warehouse for unloading

**Relationships**:
- Instance created by MineField scene based on `MineCore.carts_count`
- References Ore for positioning target
- Receives shards from Carrier instances
- Delivers to EconomyCore when unloading

**Validation**:
- `cart_id` must be unique
- `current_state` must be valid state enum value
- `load >= 0 && load <= capacity`
- `capacity >= 6 && capacity <= 12` (6 base + 6 max upgrade)
- `target_ore_id` must be valid ore ID or null
- `warehouse_position` must be valid Vector2

**Lifecycle**:
1. Created when `MineCore.carts_count` increases
2. Spawned at spawn point in MineField scene
3. Cycles through states: MOVE_TO_ORE → IDLE → MOVE_TO_WAREHOUSE → UNLOAD → MOVE_TO_ORE
4. Accumulates shards from carriers
5. Unloads to forge_cores when full
6. Destroyed when `MineCore.carts_count` decreases

**State Transitions**:
- MOVE_TO_ORE → IDLE_NEAR_ORE (when reached ore at ~200px distance)
- IDLE_NEAR_ORE → MOVE_TO_WAREHOUSE (when load >= capacity)
- MOVE_TO_WAREHOUSE → UNLOAD (when reached warehouse)
- UNLOAD → MOVE_TO_ORE (after unloading, choose new random ore)

**Capacity Calculation**:
- `capacity = 6 + sturdy_cart_level`

---

### Shard Data

Shard state attached to Shard scene instance.

**Properties**:
- `shard_id: String` - Unique identifier for shard (e.g., "shard_1", "shard_2")
- `position: Vector2` - Current world position
- `is_reserved: bool` - Whether shard is reserved by a carrier
- `reserved_by: String` - Carrier ID that reserved this shard (null if not reserved)
- `spawn_direction: Vector2` - Direction shard flew when spawned (for physics)

**Relationships**:
- Instance created by Miner when mining (if shard limit not reached)
- Referenced by Carrier for pickup target
- Removed from scene when picked up by carrier

**Validation**:
- `shard_id` must be unique
- `is_reserved == true` only when `reserved_by != null`
- `respawn_direction` must be normalized Vector2
- Total shards on scene must be <= 200

**Lifecycle**:
1. Created when miner hits ore (if limit not reached)
2. Spawned with physics (flies out in random direction)
3. Reserved by first carrier that targets it
4. Picked up by reserving carrier
5. Removed from scene when picked up

**Global Shard Limit**:
- Maximum 200 shards on scene simultaneously
- New shards not spawned if limit reached
- Message displayed: "Too many stones on the ground! Collect them first."

---

### MineSceneState

Scene state managed by MineSceneState module.

**Properties**:
- `is_on_mine_scene: bool` - Whether player is currently on mine scene
- `last_seen_timestamp: float` - Timestamp of last scene exit (Unix timestamp)
- `snapshot_units: Array[Dictionary]` - Snapshot of scene units for restoration

**Relationships**:
- Owned by MineSceneState module
- Referenced by MineOfflineProgress for offline calculation
- Referenced by MineScenePersistence for snapshot management
- Saved to SaveData for persistence

**Validation**:
- `last_seen_timestamp >= 0` (0 if never visited)
- `snapshot_units` is array of unit dictionaries (empty if no snapshot)

**Lifecycle**:
1. Initialized with `is_on_mine_scene = false`, `last_seen_timestamp = 0`
2. Updated when player enters scene (`is_on_mine_scene = true`)
3. Updated when player exits scene (`is_on_mine_scene = false`, `last_seen_timestamp = current_time`)
4. Snapshot saved on scene exit
5. Snapshot restored on scene enter (if dt > 0)

---

### MineSceneSnapshot

Scene snapshot structure for save/restore.

**Structure**:
```gdscript
Array[Dictionary] = [
    {
        "id": "miner_1",
        "type": "miner",
        "pos": Vector2(100, 200),
        "state": "mine_hits",
        "ore_id": "ore_1",
        "slot_index": 0,
        "hits_count": 7,
        "current_hit": 3
    },
    {
        "id": "carrier_1",
        "type": "carrier",
        "pos": Vector2(150, 250),
        "state": "carry_to_cart",
        "target_shard_id": "shard_5",
        "target_cart_id": "cart_1",
        "is_carrying": true
    },
    {
        "id": "cart_1",
        "type": "cart",
        "pos": Vector2(200, 300),
        "state": "idle_near_ore",
        "load": 3,
        "capacity": 6,
        "ore_id": "ore_2"
    }
]
```

**Properties**:
- Each dictionary represents one unit (miner, carrier, or cart)
- `id: String` - Unique unit identifier
- `type: String` - Unit type ("miner", "carrier", "cart")
- `pos: Vector2` - Unit position
- `state: String` - Current state name
- Type-specific properties (ore_id, slot_index, load, etc.)

**Relationships**:
- Created by MineSceneSnapshot module on scene exit
- Restored by MineScenePersistence module on scene enter
- Used for offline progress simulation

**Validation**:
- All required fields must be present
- `type` must be "miner", "carrier", or "cart"
- `pos` must be valid Vector2
- Type-specific properties must match unit type

---

### MineOfflineProgress State

Offline progress calculation state.

**Properties**:
- `last_calculation_timestamp: float` - Timestamp of last offline calculation
- `saved_workers: Dictionary` - Snapshot of workers at last save:
  - `miners: int`
  - `carriers: int`
  - `carts: int`
- `saved_upgrades: Dictionary` - Snapshot of upgrades at last save:
  - `powerful_pickaxe: int`
  - `sturdy_cart: int`
  - `comfortable_boots: int`

**Relationships**:
- Owned by MineOfflineProgress module
- Used for calculating offline forge_cores earnings
- Saved on scene exit, loaded on scene enter

**Validation**:
- `last_calculation_timestamp >= 0`
- `saved_workers` contains valid worker counts
- `saved_upgrades` contains valid upgrade levels

**Offline Calculation Formula**:
- Base production per minute per worker type (to be determined during implementation)
- Modified by upgrade levels
- Calculated based on time passed since last exit

---

## Data Flow

### Worker Assignment Flow

1. Player clicks [+ / −] in Mine building UI
2. UI calls `MineCore.set_miners_count(count)` (or carriers/carts)
3. MineCore checks `TownCore` for available population
4. If available: update count, update TownCore population
5. If not available: return false, show error
6. MineField scene spawns/removes workers based on new counts

### Shard Delivery Flow

1. Miner hits ore → spawns shard (if limit not reached)
2. Carrier scans for shards → finds and reserves shard
3. Carrier picks up shard → `is_carrying = true`
4. Carrier finds cart (if available) → delivers to cart → cart `load += 1`
5. If no cart: Carrier delivers directly → `EconomyCore.add_forge_cores(1)`
6. Cart accumulates shards → when `load >= capacity`: move to warehouse
7. Cart unloads → `EconomyCore.add_forge_cores(load)`, `load = 0`

### Save/Load Flow

1. On save: `MineSaveLoad.get_save_data()` called by SaveCore
2. Save: workers counts, upgrade levels, scene state, timestamp
3. Save: scene snapshot if player was on scene
4. On load: `MineSaveLoad.load_save_data(data)` called by SaveCore
5. Load: workers counts, upgrade levels, scene state, timestamp
6. If `is_on_mine_scene == true`: restore snapshot with time delta
7. Calculate offline progress if dt > 0

---

## Validation Rules Summary

### MineCore
- Worker counts must be within limits for mine level
- Total workers must not exceed available population
- Upgrade levels must be within valid ranges (0-5, 0-6, 0-10)

### Ore
- Exactly 4 ores on scene
- Each ore has exactly 4 slots
- Slots must be ~32px from ore center

### Workers
- All workers must have unique IDs
- State transitions must be valid
- Position must be within scene bounds

### Shards
- Maximum 200 shards on scene
- Shards must be reserved before pickup
- Shards removed when picked up

### Scene State
- `is_on_mine_scene` must be consistent with actual scene state
- Timestamp must be valid Unix timestamp
- Snapshot must match current scene state

---

## Integration Points

### EconomyCore
- Read: `EconomyCore.get_forge_cores()` for UI display
- Write: `EconomyCore.add_forge_cores(amount)` when shards delivered

### TownCore
- Read: Available population for worker assignment
- Write: Update population when workers assigned/removed
- Read: Mine building level for upgrade unlocks and worker limits

### SaveCore
- Write: "mine_state" block in save data
- Read: "mine_state" block from save data

### MineField Scene
- Spawn workers based on `MineCore` counts
- Call `MineCore.start_tracking()` on `_ready()`
- Call `MineCore.stop_tracking()` on `_exit_tree()`
- Save/restore scene snapshot

