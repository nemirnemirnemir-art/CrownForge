extends Node

const LOG_PREFIX = "[MineCore]"

# Modules (Reduced)
const MineRegistry = preload("res://core/mine/MineRegistry.gd")

var registry: Node

# Public State
var miners_ids: Array[String] = []
var carriers_ids: Array[String] = []
var carts_ids: Array[String] = []

var miners_count: int:
    get: return miners_ids.size()
var carriers_count: int:
    get: return carriers_ids.size()
var carts_count: int:
    get: return carts_ids.size()

# Upgrades
var powerful_pickaxe_level: int = 0
var sturdy_cart_level: int = 0
var comfortable_boots_level: int = 0

const PICKAXE_UNLOCK_LEVELS = [20, 40, 60, 80, 100]
const CART_UNLOCK_LEVELS = [15, 30, 45, 60, 75, 90]
const BOOTS_UNLOCK_LEVELS = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]

# Ticker State
var _last_update_time: float = 0.0
var _accumulator: float = 0.0

signal workers_changed
signal upgrades_changed

func _ready() -> void:
    registry = MineRegistry.new()
    add_child(registry)
    
    _last_update_time = Time.get_unix_time_from_system()
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    if miners_count == 0 or carriers_count == 0 or carts_count == 0:
        return
        
    # Production rate: 1 hit every 2 seconds per miner
    # Base shards per second = miners * 0.5
    var base_rate = miners_count * 0.5
    var pickaxe_bonus = 1.0 + get_pickaxe_extra_shard_chance()
    var total_rate = base_rate * pickaxe_bonus
    
    _accumulator += total_rate * delta
    
    if _accumulator >= 1.0:
        var amount = int(_accumulator)
        _accumulator -= amount
        if EconomyCore:
            EconomyCore.add_forge_cores(amount)
    
    _last_update_time = Time.get_unix_time_from_system()

# --- Worker Management ---

func get_max_workers_for_level(mine_level: int) -> Dictionary:
    if mine_level < 1:
        return {"miners": 0, "carriers": 0, "carts": 0}
    
    var base = 1
    var total_adds = mine_level - 1
    var per_type = int(float(total_adds) / 3.0)
    var remainder = total_adds % 3
    
    var m = base + per_type
    var c = base + per_type
    var t = base + per_type
    
    if remainder >= 1:
        m += 1
    if remainder >= 2:
        c += 1
        
    return {"miners": m, "carriers": c, "carts": t}

func set_miners_count(target_count: int) -> bool:
    return _adjust_worker_count(miners_ids, target_count, "miners")

func set_carriers_count(target_count: int) -> bool:
    return _adjust_worker_count(carriers_ids, target_count, "carriers")

func set_carts_count(target_count: int) -> bool:
    return _adjust_worker_count(carts_ids, target_count, "carts")

func _adjust_worker_count(id_list: Array[String], target_count: int, type_name: String) -> bool:
    var current_count = id_list.size()
    if target_count == current_count: return true
    if target_count > current_count:
        var to_add = target_count - current_count
        for i in range(to_add):
            id_list.append("%s_%d" % [type_name, current_count + i])
    else:
        var to_remove = current_count - target_count
        for i in range(to_remove):
            if id_list.is_empty(): break
            id_list.pop_back()
    workers_changed.emit()
    return true

# --- Upgrades Management ---

func get_upgrade_levels() -> Dictionary:
    return {
        "powerful_pickaxe": powerful_pickaxe_level,
        "sturdy_cart": sturdy_cart_level,
        "comfortable_boots": comfortable_boots_level
    }

func upgrade_powerful_pickaxe() -> bool:
    if powerful_pickaxe_level >= PICKAXE_UNLOCK_LEVELS.size(): return false
    var req = PICKAXE_UNLOCK_LEVELS[powerful_pickaxe_level]
    if TownCore.get_building_level("mine") >= req:
        powerful_pickaxe_level += 1
        upgrades_changed.emit()
        return true
    return false

func upgrade_sturdy_cart() -> bool:
    if sturdy_cart_level >= CART_UNLOCK_LEVELS.size(): return false
    var req = CART_UNLOCK_LEVELS[sturdy_cart_level]
    if TownCore.get_building_level("mine") >= req:
        sturdy_cart_level += 1
        upgrades_changed.emit()
        return true
    return false

func upgrade_comfortable_boots() -> bool:
    if comfortable_boots_level >= BOOTS_UNLOCK_LEVELS.size(): return false
    var req = BOOTS_UNLOCK_LEVELS[comfortable_boots_level]
    if TownCore.get_building_level("mine") >= req:
        comfortable_boots_level += 1
        upgrades_changed.emit()
        return true
    return false

# Helper methods for effects
func get_pickaxe_extra_shard_chance() -> float:
    return 0.05 * powerful_pickaxe_level

func get_cart_capacity() -> int:
    return 6 + sturdy_cart_level

func get_boots_speed_multiplier() -> float:
    return 1.0 + (0.05 * comfortable_boots_level)

# --- Save/Load ---

func get_save_data() -> Dictionary:
    return {
        "miners_ids": miners_ids,
        "carriers_ids": carriers_ids,
        "carts_ids": carts_ids,
        "powerful_pickaxe_level": powerful_pickaxe_level,
        "sturdy_cart_level": sturdy_cart_level,
        "comfortable_boots_level": comfortable_boots_level,
        "last_update_time": _last_update_time
    }

func load_save_data(data: Dictionary) -> void:
    miners_ids = []
    var loaded_miners = data.get("miners_ids", [])
    for id in loaded_miners:
        miners_ids.append(str(id))
        
    carriers_ids = []
    var loaded_carriers = data.get("carriers_ids", [])
    for id in loaded_carriers:
        carriers_ids.append(str(id))
        
    carts_ids = []
    var loaded_carts = data.get("carts_ids", [])
    for id in loaded_carts:
        carts_ids.append(str(id))
        
    powerful_pickaxe_level = int(data.get("powerful_pickaxe_level", 0))
    sturdy_cart_level = int(data.get("sturdy_cart_level", 0))
    comfortable_boots_level = int(data.get("comfortable_boots_level", 0))
    
    _last_update_time = float(data.get("last_update_time", Time.get_unix_time_from_system()))
    _catch_up_offline()
    
    workers_changed.emit()
    upgrades_changed.emit()

func _catch_up_offline() -> void:
    var now = Time.get_unix_time_from_system()
    var dt = now - _last_update_time
    if dt <= 0: return
    
    if miners_count > 0 and carriers_count > 0 and carts_count > 0:
        var base_rate = miners_count * 0.5
        var pickaxe_bonus = 1.0 + get_pickaxe_extra_shard_chance()
        var total_rate = base_rate * pickaxe_bonus
        var amount = int(total_rate * dt)
        if amount > 0:
            if EconomyCore:
                EconomyCore.add_forge_cores(amount)
                print("[MineCore] Offline catch-up: %d cores over %.1f seconds" % [amount, dt])

func reset() -> void:
    miners_ids.clear()
    carriers_ids.clear()
    carts_ids.clear()
    powerful_pickaxe_level = 0
    sturdy_cart_level = 0
    comfortable_boots_level = 0
    _accumulator = 0.0
    _last_update_time = Time.get_unix_time_from_system()
    workers_changed.emit()
    upgrades_changed.emit()
