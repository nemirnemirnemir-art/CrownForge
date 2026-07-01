extends Node

## ResourceCore - Autoload singleton
## Manages the in-run resource inventory (13 resource IDs)
## Coordinates resource changes and signals

# ===========================================
# SIGNALS
# ===========================================
signal resource_changed(resource_id: String, amount: int)

# ===========================================
# CONSTANTS
# ===========================================

const RESOURCE_WATER = "water"
const RESOURCE_GOLD = "gold"
const RESOURCE_WOOD = "wood"
const RESOURCE_CLAY = "clay"
const RESOURCE_IRON_ORE = "iron_ore"
const RESOURCE_STEEL = "steel"
const RESOURCE_WHEAT = "wheat"
const RESOURCE_FLOUR = "flour"
const RESOURCE_MEAT = "meat"
const RESOURCE_GRAPES = "grapes"
const RESOURCE_WINE = "wine"
const RESOURCE_OIL = "oil"
const RESOURCE_CRYSTAL = "crystal"

const RESOURCE_IDS: Array[String] = [
    RESOURCE_WATER,
    RESOURCE_GOLD,
    RESOURCE_WOOD,
    RESOURCE_CLAY,
    RESOURCE_IRON_ORE,
    RESOURCE_STEEL,
    RESOURCE_WHEAT,
    RESOURCE_FLOUR,
    RESOURCE_MEAT,
    RESOURCE_GRAPES,
    RESOURCE_WINE,
	RESOURCE_OIL,
	RESOURCE_CRYSTAL,
]

func _normalize_resource_id(resource_id: String) -> String:
    match resource_id:
        "ore":
            return RESOURCE_IRON_ORE
        "metal":
            return RESOURCE_STEEL
        "fuel":
            return RESOURCE_OIL
        _:
            return resource_id

# ===========================================
# STATE
# ===========================================
var _resources: Dictionary = {}

# ===========================================
# INITIALIZATION
# ===========================================
func _ready() -> void:
    _initialize_resources()

func _initialize_resources() -> void:
    _resources.clear()
    for resource_id in RESOURCE_IDS:
        _resources[resource_id] = 0

# ===========================================
# PUBLIC API
# ===========================================
func add_resource(resource_id: String, amount: int) -> void:
    resource_id = _normalize_resource_id(resource_id)
    if amount <= 0:
        return
    
    if not _resources.has(resource_id):
        push_warning("[ResourceCore] Unknown resource id: %s" % resource_id)
        return
    
    _resources[resource_id] += amount
    resource_changed.emit(resource_id, _resources[resource_id])

func get_resource(resource_id: String) -> int:
    resource_id = _normalize_resource_id(resource_id)
    return _resources.get(resource_id, 0)

func has_resource(resource_id: String, amount: int = 1) -> bool:
    resource_id = _normalize_resource_id(resource_id)
    if amount <= 0:
        return true
    if not _resources.has(resource_id):
        return false
    return int(_resources.get(resource_id, 0)) >= amount

func consume_resource(resource_id: String, amount: int) -> bool:
    resource_id = _normalize_resource_id(resource_id)
    if not _resources.has(resource_id):
        return false
    
    if _resources[resource_id] >= amount:
        _resources[resource_id] -= amount
        resource_changed.emit(resource_id, _resources[resource_id])
        return true
    
    return false

func get_all_resources() -> Dictionary:
    return _resources.duplicate()

# ===========================================
# SAVE/LOAD
# ===========================================
func get_save_data() -> Dictionary:
    return {
        "resources": _resources.duplicate()
    }

func load_save_data(data: Dictionary) -> void:
    if data.has("resources"):
        _initialize_resources()
        var saved: Dictionary = data["resources"].duplicate()
        for k in saved.keys():
            var raw_id := String(k)
            var resource_id := _normalize_resource_id(raw_id)
            if not _resources.has(resource_id):
                continue
            _resources[resource_id] = int(saved.get(k, 0))
        # Emit signals for all resources to update UI
        for resource_id in _resources:
            resource_changed.emit(resource_id, _resources[resource_id])

func reset() -> void:
    for resource_id in _resources:
        _resources[resource_id] = 0
        resource_changed.emit(resource_id, 0)
