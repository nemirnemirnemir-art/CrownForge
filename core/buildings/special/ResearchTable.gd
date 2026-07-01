extends RefCounted

enum ResearchMode { NOTHING = 0, BASIC_PRODUCTION = 1, LEVY_BARRACKS = 2 }
const CYCLE_TIME_SEC: float = 100.0

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _mode: int = ResearchMode.NOTHING
var _is_producing: bool = false

const MODE_NAMES := {
    ResearchMode.NOTHING: "Nothing",
    ResearchMode.BASIC_PRODUCTION: "Basic Production",
    ResearchMode.LEVY_BARRACKS: "Levy Barracks",
}

const MODE_REWARD_TYPES := {
    ResearchMode.BASIC_PRODUCTION: int(ProphecyPatternScript.RewardType.BASIC_PRODUCTION),
    ResearchMode.LEVY_BARRACKS: int(ProphecyPatternScript.RewardType.LEVY_BARRACKS),
}

func initialize(slot: Node, config: BuildingConfig) -> void:
    _slot = slot
    _config = config
    _timer = 0.0
    _mode = ResearchMode.NOTHING
    _is_producing = false

func set_mode(mode: int) -> void:
    var next_mode := clampi(mode, 0, 2)
    if next_mode == _mode:
        return
    _mode = next_mode
    _timer = 0.0
    if _mode == ResearchMode.NOTHING:
        _is_producing = false
        return
    _is_producing = true

func get_mode() -> int:
    return _mode

func get_mode_name() -> String:
    return MODE_NAMES.get(_mode, "Unknown")

func get_current_reward_type() -> int:
    return int(MODE_REWARD_TYPES.get(_mode, -1))

func get_ui_options() -> Array:
    return [
        {"mode": ResearchMode.NOTHING, "label": MODE_NAMES[ResearchMode.NOTHING], "reward_type": -1},
        {"mode": ResearchMode.BASIC_PRODUCTION, "label": MODE_NAMES[ResearchMode.BASIC_PRODUCTION], "reward_type": MODE_REWARD_TYPES[ResearchMode.BASIC_PRODUCTION]},
        {"mode": ResearchMode.LEVY_BARRACKS, "label": MODE_NAMES[ResearchMode.LEVY_BARRACKS], "reward_type": MODE_REWARD_TYPES[ResearchMode.LEVY_BARRACKS]},
    ]

func get_progress_ratio() -> float:
    var cycle := _get_effective_cycle_time()
    if cycle <= 0.0 or _mode == ResearchMode.NOTHING:
        return 0.0
    return max(0.0, (cycle - _timer) / cycle)

func get_cycle_time() -> float:
    return _get_effective_cycle_time()

func get_runtime_state() -> Dictionary:
    return {
        "mode": _mode,
        "timer": _timer,
        "is_producing": _is_producing,
    }

func load_runtime_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    _mode = clampi(int(state.get("mode", ResearchMode.NOTHING)), 0, 2)
    _timer = maxf(0.0, float(state.get("timer", 0.0)))
    _is_producing = bool(state.get("is_producing", _mode != ResearchMode.NOTHING))
    if _mode == ResearchMode.NOTHING:
        _is_producing = false

func tick(delta: float) -> Dictionary:
    if _config == null:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
    
    if _mode == ResearchMode.NOTHING:
        return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
    
    var cycle: float = _get_effective_cycle_time()
    
    if not _is_producing:
        _is_producing = true
    
    _timer += delta
    var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
    var completed: bool = false
    
    if _timer >= cycle:
        _timer = 0.0
        completed = true
        _on_cycle_completed()
    
    return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _on_cycle_completed() -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null or tree.current_scene == null:
        return
    var game_scene = tree.current_scene
    
    match _mode:
        ResearchMode.BASIC_PRODUCTION:
            if game_scene.has_method("enqueue_base_production_reward"):
                game_scene.call("enqueue_base_production_reward")
        ResearchMode.LEVY_BARRACKS:
            if game_scene.has_method("enqueue_levy_barracks_reward"):
                game_scene.call("enqueue_levy_barracks_reward")

func _get_effective_cycle_time() -> float:
    var speed_mult := 1.0
    var tree := Engine.get_main_loop() as SceneTree
    if tree and tree.root:
        var artifact_core := tree.root.get_node_or_null("ArtifactCore")
        if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
            speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
    if tree and tree.root:
        var morale_system := tree.root.get_node_or_null("MoraleSystem")
        if morale_system:
            speed_mult *= (1.0 + float(morale_system.call("get_productivity_modifier")))
        var king_spell_state := tree.root.get_node_or_null("KingSpellState")
        if king_spell_state:
            speed_mult *= (1.0 + float(king_spell_state.call("get_productivity_bonus_multiplier")))
    if speed_mult <= 0.0:
        speed_mult = 0.0001
    return max(0.001, CYCLE_TIME_SEC / speed_mult)
