extends Node
## MoraleSystem - Autoload
## Manages global morale mechanics affecting unit damage and building speed.

const MoraleCalculatorScript := preload("res://scripts/systems/morale/MoraleCalculator.gd")
const BuildingSlotQueryScript := preload("res://scripts/systems/morale/BuildingSlotQuery.gd")

signal morale_updated

var morale: int = 0
var debug_bonus_morale: int = 0

const WINE_CONSUME_PER_WARRIOR_PER_SEC: float = 0.1

var _is_battle_active: bool = false
var _wine_consume_accumulator: float = 0.0
var _morale_calculator = MoraleCalculatorScript.new()
var _building_slot_query = BuildingSlotQueryScript.new()

# Factors breakdown for UI
var last_breakdown: Dictionary = {}

func _ready() -> void:
    # Connect to signals that usually affect morale
    if ResourceCore:
        ResourceCore.resource_changed.connect(_on_resource_changed)
    if HeroCore:
        HeroCore.squad_changed.connect(calculate_morale)

    if EventBus:
        EventBus.wave_started.connect(_on_wave_started)
        EventBus.wave_completed.connect(_on_wave_completed)

    if BuildingUpgradeCore and BuildingUpgradeCore.has_signal("building_upgrades_changed"):
        BuildingUpgradeCore.building_upgrades_changed.connect(
            func(_bid: String, _lvl: int): calculate_morale())

    # Initial calculation
    call_deferred("calculate_morale")
    call_deferred("_connect_vzor_signals")

func _process(delta: float) -> void:
    if not _is_battle_active:
        return
    if not ResourceCore:
        return

    var scaled_delta := TickManager.get_scaled_delta(delta) if TickManager else delta
    var warriors := _get_warrior_count_on_field()
    if warriors <= 0:
        return

    var consume := float(warriors) * WINE_CONSUME_PER_WARRIOR_PER_SEC * scaled_delta
    consume *= _get_wine_consumption_multiplier()
    if consume <= 0.0:
        return

    _wine_consume_accumulator += consume

    var available := ResourceCore.get_resource(ResourceCore.RESOURCE_WINE)
    if available <= 0:
        _wine_consume_accumulator = 0.0
        return

    var to_consume: int = min(int(floor(_wine_consume_accumulator)), available)
    if to_consume <= 0:
        return

    ResourceCore.consume_resource(ResourceCore.RESOURCE_WINE, to_consume)
    _wine_consume_accumulator -= float(to_consume)
    if ArtifactCore and ArtifactCore.has_method("on_wine_spent"):
        ArtifactCore.on_wine_spent(to_consume)

func _on_wave_started(_wave_number: int) -> void:
    _is_battle_active = true
    calculate_morale()

func _on_wave_completed(_wave_number: int) -> void:
    _is_battle_active = false
    calculate_morale()

func _on_resource_changed(res_id: String, _amount: int) -> void:
    if res_id == ResourceCore.RESOURCE_WINE:
        calculate_morale()

func calculate_morale() -> void:
    var result: Dictionary = _morale_calculator.calculate_morale({
        "wine_stock_morale_bonus": _get_wine_morale_bonus(),
        "additional_wine_stock_morale_bonus": _get_additional_wine_stock_morale_bonus(),
        # TODO: unit diversity - another story for different kings
        # "unit_diversity_bonus": _get_unit_diversity_bonus(),
        "artifact_bonus": _get_artifact_bonus(),
        "building_sources": _get_building_bonus(),
        "arena_bonus": _get_active_arena_morale_bonus(),
        "debug_bonus": debug_bonus_morale,
    })
    var total := int(result.get("total", 0))
    last_breakdown = result.get("breakdown", {}) as Dictionary

    if morale != total:
        morale = total
        morale_updated.emit()
        # print("[MoraleSystem] Updated Morale: %d" % morale)

func get_total_morale() -> int:
    return morale

func get_damage_modifier() -> float:
    return _morale_calculator.get_damage_modifier(morale)

func get_productivity_modifier() -> float:
    return _morale_calculator.get_productivity_modifier(morale)

func add_debug_morale(amount: int) -> void:
    debug_bonus_morale += amount
    calculate_morale()

func reset_debug_morale() -> void:
    debug_bonus_morale = 0
    calculate_morale()

func _get_warrior_count_on_field() -> int:
    return _building_slot_query.get_warrior_count_on_field()

func _get_wine_morale_bonus() -> int:
    if not ResourceCore:
        return 0

    var wine := ResourceCore.get_resource(ResourceCore.RESOURCE_WINE)
    var warriors := _get_warrior_count_on_field()
    return _morale_calculator.get_wine_morale_bonus(wine, warriors)

func _get_wine_consumption_multiplier() -> float:
    return _morale_calculator.get_wine_consumption_multiplier(_has_active_tavern())

func _get_additional_wine_stock_morale_bonus() -> int:
    return _morale_calculator.get_additional_wine_stock_morale_bonus(_has_active_tavern())

func _has_active_tavern() -> bool:
    return _building_slot_query.has_active_tavern()

func _get_active_arena_morale_bonus() -> int:
    return _building_slot_query.get_active_arena_morale_bonus()


func _get_unit_diversity_bonus() -> int:
    if not HeroCore:
        return 0

    var active_heroes: Array = HeroCore.get_active_heroes()
    var unique_types: Array[String] = []
    for hero_data in active_heroes:
        var type_id := String(hero_data.get("icon_id", "unknown"))
        if unique_types.has(type_id):
            continue
        unique_types.append(type_id)
    return unique_types.size() * 3


func _get_artifact_bonus() -> int:
    if ArtifactCore and ArtifactCore.has_method("get_morale_flat_bonus"):
        return int(ArtifactCore.get_morale_flat_bonus())
    return 0


func _get_building_bonus() -> Dictionary:
    if not BuildingUpgradeCore:
        return {}
    var result: Dictionary = {}
    if BuildingUpgradeCore.has_method("get_active_concert_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_active_concert_morale_bonus())
        if bv > 0:
            result["Concert"] = bv
    if BuildingUpgradeCore.has_method("get_active_hospital_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_active_hospital_morale_bonus())
        if bv > 0:
            result["Hospital"] = bv
    if BuildingUpgradeCore.has_method("get_vineyard_passive_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_vineyard_passive_morale_bonus())
        if bv > 0:
            result["Vineyard"] = bv
    if BuildingUpgradeCore.has_method("get_market_active_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_market_active_morale_bonus())
        if bv > 0:
            result["Market (active)"] = bv
    if BuildingUpgradeCore.has_method("get_tavern_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_tavern_morale_bonus())
        if bv > 0:
            result["Tavern"] = bv
    if BuildingUpgradeCore.has_method("get_black_unicorn_morale_bonus"):
        var bv := int(BuildingUpgradeCore.get_black_unicorn_morale_bonus())
        if bv > 0:
            result["Black Unicorn"] = bv
    return result


func _connect_vzor_signals() -> void:
    if not get_tree():
        return
    var vzor_zones := get_tree().get_nodes_in_group("vzor_zone")
    for zone in vzor_zones:
        if zone.has_signal("gaze_slots_changed") and not zone.gaze_slots_changed.is_connected(calculate_morale):
            zone.gaze_slots_changed.connect(calculate_morale)
