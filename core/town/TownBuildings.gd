extends RefCounted
class_name TownBuildings

## Управление зданиями
## Загрузка данных, уровни, апгрейд, стоимость

var _buildings: Dictionary = {}
var _building_registry: Dictionary = {}

const MAGE_TOWER_ID: String = "mage_tower"
const MAGE_TOWER_MAX_LEVEL: int = 50
const MAGE_TOWER_UPGRADE_BASE_PRICE: float = 500.0
const MAGE_TOWER_UPGRADE_GROWTH: float = 1.12

func initialize() -> void:
    _load_building_data()
    if _buildings.is_empty():
        _init_default_buildings()

func _load_building_data() -> void:
    var dir_path = "res://data/buildings/"
    var dir = DirAccess.open(dir_path)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres") or file_name.ends_with(".remap"):
                var clean_name = file_name.replace(".remap", "")
                var res = load(dir_path + clean_name) as BuildingData
                if res:
                    _building_registry[res.id] = res
            file_name = dir.get_next()
    else:
        # print("[TownBuildings] Failed to open buildings directory!")
        pass

func _init_default_buildings() -> void:
    if _building_registry.is_empty():
        _load_building_data()
    
    for id in _building_registry:
        var init_level = 0
        _buildings[id] = { "level": init_level, "slots": {}, "workers": [], "built_count": 0 }

func get_all_building_ids() -> Array:
    return _building_registry.keys()

func get_building_config(building_id: String) -> BuildingData:
    return _building_registry.get(building_id)

func get_building_level(building_id: String) -> int:
    if _buildings.has(building_id):
        return _buildings[building_id]["level"]
    return 0

func get_building_upgrade_cost(building_id: String) -> int:
    var level = get_building_level(building_id)
    var data = _building_registry.get(building_id)
    if not data:
        return 999999

    if building_id == MAGE_TOWER_ID:
        if level >= MAGE_TOWER_MAX_LEVEL:
            return 0
        # Price(L)=ceil(500*1.12^(L-1)), where L is the target level.
        var target_level: int = level + 1
        return int(ceil(MAGE_TOWER_UPGRADE_BASE_PRICE * pow(MAGE_TOWER_UPGRADE_GROWTH, target_level - 1)))
    
    var base = data.base_upgrade_cost_gold
    var multiplier = data.upgrade_cost_multiplier
    
    if level <= 0:
        return int(base)
    
    # Cost = Base * (Multiplier ^ (Level - 1))
    return int(base * pow(multiplier, level - 1))

func try_upgrade_building(building_id: String) -> bool:
    if not _buildings.has(building_id):
        return false

    if building_id == MAGE_TOWER_ID and get_building_level(building_id) >= MAGE_TOWER_MAX_LEVEL:
        return false
    
    var cost = get_building_upgrade_cost(building_id)
    if cost <= 0:
        return false
    if EconomyCore.can_afford(cost):
        EconomyCore.spend_gold(cost)
        _buildings[building_id]["level"] += 1
        
        if SaveCore:
            SaveCore.request_save()
        return true
    return false

func get_buildings() -> Dictionary:
    return _buildings

func set_buildings(buildings: Dictionary) -> void:
    _buildings = buildings
    # Validate buildings (in case of new ones added in updates)
    for id in _building_registry:
        if not _buildings.has(id):
            var init_level = 0
            _buildings[id] = { "level": init_level, "slots": {}, "workers": [], "built_count": 0 }
        else:
            # Ensure 'workers' field exists for old saves
            if not _buildings[id].has("workers"):
                _buildings[id]["workers"] = []
            if not _buildings[id].has("slots"):
                _buildings[id]["slots"] = {}
            if not _buildings[id].has("built_count"):
                _buildings[id]["built_count"] = 0

func get_slot_state(building_id: String, slot_index: int) -> Dictionary:
    if not _buildings.has(building_id):
        return {}
    var slots: Variant = _buildings[building_id].get("slots", {})
    if not (slots is Dictionary):
        return {}
    var raw: Variant = slots.get(str(slot_index), {})
    return raw.duplicate(true) if raw is Dictionary else {}

func set_slot_state(building_id: String, slot_index: int, state: Dictionary) -> void:
    if not _buildings.has(building_id):
        return
    if not _buildings[building_id].has("slots") or not (_buildings[building_id]["slots"] is Dictionary):
        _buildings[building_id]["slots"] = {}
    _buildings[building_id]["slots"][str(slot_index)] = state.duplicate(true)

func clear_slot_state(building_id: String, slot_index: int) -> void:
    if not _buildings.has(building_id):
        return
    if not _buildings[building_id].has("slots") or not (_buildings[building_id]["slots"] is Dictionary):
        return
    _buildings[building_id]["slots"].erase(str(slot_index))

func get_building_built_count(building_id: String) -> int:
    if not _buildings.has(building_id):
        return 0
    return int(_buildings[building_id].get("built_count", 0))

func increment_building_built_count(building_id: String) -> void:
    if not _buildings.has(building_id):
        return
    if not _buildings[building_id].has("built_count"):
        _buildings[building_id]["built_count"] = 0
    _buildings[building_id]["built_count"] += 1
    if SaveCore:
        SaveCore.request_save()

func get_building_registry() -> Dictionary:
    return _building_registry
