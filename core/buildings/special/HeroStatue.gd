extends RefCounted

const SPEED_UPGRADE_ID: String = "hero_statue:0"

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_producing = false

func tick(delta: float) -> Dictionary:
	if _config == null:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
	var cycle: float = _get_effective_cycle_time()
	if not _is_producing:
		if _config.consumes.size() > 0:
			if not _config.can_produce():
				return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle}
			_config.consume_inputs()
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
	if scene.has_method("enqueue_troop_bonus_reward"):
		scene.call("enqueue_troop_bonus_reward")

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
	if _has_upgrade(SPEED_UPGRADE_ID):
		speed_mult *= 1.25
	if speed_mult <= 0.0:
		speed_mult = 0.0001
	return max(0.001, float(_config.cycle_time) / speed_mult)

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
	var raw_slot_index: Variant = _slot.get("slot_index")
	if raw_slot_index == null:
		return -1
	return int(raw_slot_index)
