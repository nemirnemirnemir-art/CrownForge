extends RefCounted

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")

enum ResearchMode {
	NOTHING = 0,
	BASIC_PRODUCTION = 1,
	ESTABLISHED_PRODUCTION = 2,
	ADVANCED_PRODUCTION = 3,
	LEVY_BARRACKS = 4,
	VETERAN_BARRACKS = 5,
	ELITE_BARRACKS = 6,
	KINGDOM_INFRASTRUCTURE = 7,
}

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _mode: int = ResearchMode.NOTHING
var _is_producing: bool = false

const MODE_NAMES := {
	ResearchMode.NOTHING: "Nothing",
	ResearchMode.BASIC_PRODUCTION: "Basic Production",
	ResearchMode.ESTABLISHED_PRODUCTION: "Established Production",
	ResearchMode.ADVANCED_PRODUCTION: "Advanced Production",
	ResearchMode.LEVY_BARRACKS: "Levy Barracks",
	ResearchMode.VETERAN_BARRACKS: "Veteran Barracks",
	ResearchMode.ELITE_BARRACKS: "Elite Barracks",
	ResearchMode.KINGDOM_INFRASTRUCTURE: "Kingdom Infrastructure",
}

const MODE_REWARD_TYPES := {
	ResearchMode.BASIC_PRODUCTION: int(ProphecyPatternScript.RewardType.BASIC_PRODUCTION),
	ResearchMode.ESTABLISHED_PRODUCTION: int(ProphecyPatternScript.RewardType.ESTABLISHED_PRODUCTION),
	ResearchMode.ADVANCED_PRODUCTION: int(ProphecyPatternScript.RewardType.ADVANCED_PRODUCTION),
	ResearchMode.LEVY_BARRACKS: int(ProphecyPatternScript.RewardType.LEVY_BARRACKS),
	ResearchMode.VETERAN_BARRACKS: int(ProphecyPatternScript.RewardType.VETERAN_BARRACKS),
	ResearchMode.ELITE_BARRACKS: int(ProphecyPatternScript.RewardType.ELITE_BARRACKS),
	ResearchMode.KINGDOM_INFRASTRUCTURE: int(ProphecyPatternScript.RewardType.KINGDOM_INFRASTRUCTURE),
}

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_mode = ResearchMode.NOTHING
	_is_producing = false

func set_mode(mode: int) -> void:
	var next_mode := clampi(mode, int(ResearchMode.NOTHING), int(ResearchMode.KINGDOM_INFRASTRUCTURE))
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

func get_current_reward_type() -> int:
	return int(MODE_REWARD_TYPES.get(_mode, -1))

func get_ui_options() -> Array:
	var options: Array = []
	for mode in MODE_NAMES.keys():
		options.append({
			"mode": int(mode),
			"label": String(MODE_NAMES[mode]),
			"reward_type": int(MODE_REWARD_TYPES.get(mode, -1)),
		})
	options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("mode", 0)) < int(b.get("mode", 0)))
	return options

func get_runtime_state() -> Dictionary:
	return {
		"mode": _mode,
		"timer": _timer,
		"is_producing": _is_producing,
	}

func load_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	_mode = clampi(int(state.get("mode", ResearchMode.NOTHING)), int(ResearchMode.NOTHING), int(ResearchMode.KINGDOM_INFRASTRUCTURE))
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
		_timer = 0.0
	_timer += delta
	var progress_ratio: float = max(0.0, (cycle - _timer) / cycle)
	var completed: bool = false
	if _timer >= cycle:
		_timer = 0.0
		_is_producing = false
		completed = true
		_on_cycle_completed()
	return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _on_cycle_completed() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var scene := tree.current_scene
	match _mode:
		ResearchMode.BASIC_PRODUCTION:
			if scene.has_method("enqueue_base_production_reward"):
				scene.call("enqueue_base_production_reward")
		ResearchMode.ESTABLISHED_PRODUCTION:
			if scene.has_method("enqueue_established_production_reward"):
				scene.call("enqueue_established_production_reward")
		ResearchMode.ADVANCED_PRODUCTION:
			if scene.has_method("enqueue_advanced_production_reward"):
				scene.call("enqueue_advanced_production_reward")
		ResearchMode.LEVY_BARRACKS:
			if scene.has_method("enqueue_levy_barracks_reward"):
				scene.call("enqueue_levy_barracks_reward")
		ResearchMode.VETERAN_BARRACKS:
			if scene.has_method("enqueue_veteran_barracks_reward"):
				scene.call("enqueue_veteran_barracks_reward")
		ResearchMode.ELITE_BARRACKS:
			if scene.has_method("enqueue_elite_barracks_reward"):
				scene.call("enqueue_elite_barracks_reward")
		ResearchMode.KINGDOM_INFRASTRUCTURE:
			if scene.has_method("enqueue_kingdom_infrastructure_reward"):
				scene.call("enqueue_kingdom_infrastructure_reward")

func _get_effective_cycle_time() -> float:
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
	return max(0.001, float(_config.cycle_time) / speed_mult)
