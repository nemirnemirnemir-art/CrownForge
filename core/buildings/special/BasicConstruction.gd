extends RefCounted

const READY_TARGETS: Array[String] = [
    "clay_mine",
    "crystal_mine",
    "gold_mine",
    "iron_mine",
    "vineyard",
    "wheat_field",
]
const MODE_NAME_NOTHING := "Nothing"

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_ready: bool = false

func initialize(slot: Node, config: BuildingConfig) -> void:
    _slot = slot
    _config = config
    _timer = 0.0
    _is_ready = false

func tick(delta: float) -> Dictionary:
    if _config == null:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0, "is_ready": false}

    var cycle: float = _get_effective_cycle_time()
    if _is_ready:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle, "is_ready": true}

    _timer += delta
    var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
    if _timer >= cycle:
        _timer = cycle
        _is_ready = true
        return {"progress_ratio": 0.0, "is_producing": false, "completed": true, "cycle_time": cycle, "is_ready": true}

    return {"progress_ratio": progress_ratio, "is_producing": true, "completed": false, "cycle_time": cycle, "is_ready": false}

func is_ready() -> bool:
    return _is_ready

func get_mode_name() -> String:
    if _is_ready:
        return "Ready"
    return MODE_NAME_NOTHING

func get_target_buildings() -> Array[String]:
    return READY_TARGETS.duplicate()

func convert_to(building_id: String) -> bool:
    if not _is_ready:
        return false
    if not READY_TARGETS.has(building_id):
        return false
    if _slot == null or not is_instance_valid(_slot):
        return false
    if not _slot.has_method("replace_current_building"):
        return false
    _slot.call("replace_current_building", building_id)
    return true

func get_runtime_state() -> Dictionary:
    return {
        "timer": _timer,
        "is_ready": _is_ready,
    }

func load_runtime_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    _timer = maxf(0.0, float(state.get("timer", 0.0)))
    _is_ready = bool(state.get("is_ready", false))
    if _config != null:
        _timer = minf(_timer, _get_effective_cycle_time())

func _get_effective_cycle_time() -> float:
    var cycle := float(_config.cycle_time) if _config != null else 0.0
    if cycle <= 0.0:
        return 0.001
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
    return max(0.001, cycle / speed_mult)
