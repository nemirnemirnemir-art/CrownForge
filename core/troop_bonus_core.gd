extends Node

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

signal bonuses_changed

enum BonusStat {
    HP,
    DAMAGE,
    ATTACK_SPEED
}

const _STAT_LIST: Array[int] = [BonusStat.HP, BonusStat.DAMAGE, BonusStat.ATTACK_SPEED]
const UNIT_CLASS_COUNT: int = int(UnitConfig.UnitClass.UNDEAD) + 1

var _bonuses: Dictionary = {}
var _unit_classes_cache: Dictionary = {}

func _ready() -> void:
    reset()

func reset() -> void:
    _bonuses.clear()
    _unit_classes_cache.clear()
    for stat in _STAT_LIST:
        var arr: Array[float] = []
        arr.resize(UNIT_CLASS_COUNT)
        for i in range(arr.size()):
            arr[i] = 0.0
        _bonuses[stat] = arr
    bonuses_changed.emit()

func add_bonus_percent(unit_class: int, stat: int, amount: float) -> void:
    if not _bonuses.has(stat):
        return
    var arr: Array = _bonuses[stat]
    if unit_class < 0 or unit_class >= arr.size():
        return
    arr[unit_class] = float(arr[unit_class]) + amount
    bonuses_changed.emit()

func get_bonus_percent(unit_class: int, stat: int) -> float:
    if not _bonuses.has(stat):
        return 0.0
    var arr: Array = _bonuses[stat]
    if unit_class < 0 or unit_class >= arr.size():
        return 0.0
    return float(arr[unit_class])

func get_total_bonus_percent_for_classes(unit_classes: Array, stat: int) -> float:
    var total := 0.0
    for uc in unit_classes:
        total += get_bonus_percent(int(uc), stat)
    return total

func get_multiplier_for_classes(unit_classes: Array, stat: int) -> float:
    return 1.0 + get_total_bonus_percent_for_classes(unit_classes, stat)

func get_unit_classes(unit_id: String) -> Array:
    var key := unit_id.to_lower()
    if _unit_classes_cache.has(key):
        return _unit_classes_cache[key]
    var cfg := PathRegistryScript.load_unit_config(key) as UnitConfig
    if cfg == null:
        _unit_classes_cache[key] = []
        return []
    _unit_classes_cache[key] = cfg.unit_classes.duplicate()
    return _unit_classes_cache[key]

func get_unit_bonus_percent(unit_id: String, stat: int) -> float:
    var classes: Array = get_unit_classes(unit_id)
    return get_total_bonus_percent_for_classes(classes, stat)

func get_unit_multiplier(unit_id: String, stat: int) -> float:
    var classes: Array = get_unit_classes(unit_id)
    return get_multiplier_for_classes(classes, stat)
