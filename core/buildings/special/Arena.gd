extends RefCounted

const BASE_MORALE_BONUS := 25
const HIGHER_MORALE_BONUS := 15
const FIGHT_BETTING_CYCLE_SEC := 3.0

var _slot: Node = null
var _config: BuildingConfig = null
var _is_vzor_active: bool = false
var _betting_timer: float = 0.0
var _last_reported_morale_bonus: int = 0

func initialize(slot: Node, config: BuildingConfig) -> void:
    _slot = slot
    _config = config
    _betting_timer = 0.0
    _is_vzor_active = false
    _last_reported_morale_bonus = 0

func set_vzor_active(active: bool) -> void:
    if _is_vzor_active == active:
        _refresh_morale_if_needed()
        return
    _is_vzor_active = active
    if not _is_vzor_active:
        _betting_timer = 0.0
    _refresh_morale_if_needed(true)

func tick(delta: float) -> Dictionary:
    _refresh_morale_if_needed()
    if _config == null:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
    if not _is_vzor_active:
        _betting_timer = 0.0
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": FIGHT_BETTING_CYCLE_SEC}
    if not _has_upgrade("arena:0"):
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": FIGHT_BETTING_CYCLE_SEC}

    var cycle: float = _get_effective_cycle_time(FIGHT_BETTING_CYCLE_SEC)
    _betting_timer += delta
    var progress_ratio: float = maxf(0.0, (cycle - _betting_timer) / cycle)
    if _betting_timer < cycle:
        return {"progress_ratio": progress_ratio, "is_producing": true, "completed": false, "cycle_time": cycle}

    _betting_timer = 0.0
    if EconomyCore and EconomyCore.has_method("add_gold"):
        EconomyCore.add_gold(1.0)
    return {"progress_ratio": 0.0, "is_producing": true, "completed": true, "cycle_time": cycle}

func get_runtime_state() -> Dictionary:
    return {
        "betting_timer": _betting_timer,
        "is_vzor_active": _is_vzor_active,
        "last_reported_morale_bonus": _last_reported_morale_bonus,
    }

func load_runtime_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    _betting_timer = maxf(0.0, float(state.get("betting_timer", 0.0)))
    _is_vzor_active = bool(state.get("is_vzor_active", false))
    _last_reported_morale_bonus = int(state.get("last_reported_morale_bonus", 0))
    _refresh_morale_if_needed(true)

func get_morale_bonus() -> int:
    if not _is_vzor_active:
        return 0
    var total := BASE_MORALE_BONUS
    if _has_upgrade("arena:1"):
        total += HIGHER_MORALE_BONUS
    return total

func _refresh_morale_if_needed(force: bool = false) -> void:
    var current_bonus := get_morale_bonus()
    if not force and current_bonus == _last_reported_morale_bonus:
        return
    _last_reported_morale_bonus = current_bonus
    if MoraleSystem and MoraleSystem.has_method("calculate_morale"):
        MoraleSystem.calculate_morale()

func _has_upgrade(upgrade_id: String) -> bool:
    if BuildingUpgradeCore == null or not BuildingUpgradeCore.has_method("has_upgrade"):
        return false
    var slot_index := _get_slot_index()
    if slot_index < 0:
        return false
    return bool(BuildingUpgradeCore.has_upgrade(slot_index, upgrade_id))

func _get_slot_index() -> int:
    if _slot == null or not is_instance_valid(_slot):
        return -1
    return int(_slot.get("slot_index"))

func _get_effective_cycle_time(base_cycle: float) -> float:
    var speed_mult := 1.0
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var artifact_core := tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
            speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
    if MoraleSystem:
        speed_mult *= (1.0 + MoraleSystem.get_productivity_modifier())
    if KingSpellState:
        speed_mult *= (1.0 + KingSpellState.get_productivity_bonus_multiplier())
    if speed_mult <= 0.0:
        speed_mult = 0.0001
    return maxf(0.001, base_cycle / speed_mult)
