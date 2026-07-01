extends Node

## PopulationCore - Autoload singleton
## Manages hero population limits and upgrades

signal population_limit_changed(current_limit: int)

const INITIAL_POPULATION_LIMIT: int = 5
const UPGRADE_BONUS: int = 3
const INITIAL_UPGRADE_COST: int = 150
const RESOURCE_WOOD = "wood"

var _max_population: int = INITIAL_POPULATION_LIMIT
var _upgrade_level: int = 0

func _ready() -> void:
    pass

func get_max_population() -> int:
    var bonus := 0
    var artifact_core := get_node_or_null("/root/ArtifactCore")
    if artifact_core != null and artifact_core.has_method("get_unit_limit_bonus"):
        bonus = int(artifact_core.call("get_unit_limit_bonus"))
    return _max_population + bonus

func get_current_population() -> int:
    if not HeroCore:
        return 0
    var count = 0
    for hero in HeroCore.heroes.values():
        # Count only active battlefield heroes that are not dead
        if hero.get("is_hired", false) and not hero.get("isDead", false) and hero.get("isActive", false):
            count += 1
    return count

func get_upgrade_level() -> int:
    return _upgrade_level

func get_next_upgrade_cost() -> int:
    return int(float(INITIAL_UPGRADE_COST) * pow(2.0, float(_upgrade_level)))

func can_upgrade() -> bool:
    var cost = get_next_upgrade_cost()
    if ResourceCore:
        return ResourceCore.get_resource(RESOURCE_WOOD) >= cost
    return false

func try_upgrade() -> bool:
    var cost = get_next_upgrade_cost()
    if can_upgrade():
        if ResourceCore.consume_resource(RESOURCE_WOOD, cost):
            _upgrade_level += 1
            _max_population += UPGRADE_BONUS
            population_limit_changed.emit(_max_population)
            if SaveCore:
                SaveCore.request_save()
            return true
    return false

# === SAVE/LOAD ===
func get_save_data() -> Dictionary:
    return {
        "max_population": _max_population,
        "upgrade_level": _upgrade_level
    }

func load_save_data(data: Dictionary) -> void:
    if data.has("max_population"):
        _max_population = data["max_population"]
    if data.has("upgrade_level"):
        _upgrade_level = data["upgrade_level"]
    population_limit_changed.emit(_max_population)

func reset() -> void:
    _max_population = INITIAL_POPULATION_LIMIT
    _upgrade_level = 0
    population_limit_changed.emit(_max_population)
