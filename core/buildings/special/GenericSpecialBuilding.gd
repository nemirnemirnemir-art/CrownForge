extends RefCounted

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

	if float(_config.cycle_time) <= 0.0:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}

	var cycle := _get_effective_cycle_time()
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
		if _config.produces.size() > 0:
			_config.produce_outputs()

	return {"progress_ratio": progress_ratio, "is_producing": _is_producing, "completed": completed, "cycle_time": cycle}

func _get_effective_cycle_time() -> float:
	var speed_mult := 1.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var artifact_core := tree.root.get_node_or_null("ArtifactCore")
		if artifact_core != null and artifact_core.has_method("get_resource_production_speed_multiplier"):
			speed_mult *= float(artifact_core.call("get_resource_production_speed_multiplier"))
	var morale_system := _get_autoload("MoraleSystem")
	if morale_system != null:
		speed_mult *= (1.0 + float(morale_system.call("get_productivity_modifier")))
	var king_spell_state := _get_autoload("KingSpellState")
	if king_spell_state != null:
		speed_mult *= (1.0 + float(king_spell_state.call("get_productivity_bonus_multiplier")))
	var building_upgrade_core := _get_autoload("BuildingUpgradeCore")
	if building_upgrade_core != null and _slot != null:
		var raw_slot_index: Variant = _slot.get("slot_index")
		var slot_index := -1 if raw_slot_index == null else int(raw_slot_index)
		if slot_index >= 0 and building_upgrade_core.has_method("get_concert_slot_production_speed_multiplier"):
			speed_mult *= float(building_upgrade_core.call("get_concert_slot_production_speed_multiplier", slot_index))
	if speed_mult <= 0.0:
		speed_mult = 0.0001
	return max(0.001, float(_config.cycle_time) / speed_mult)

func _get_autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
