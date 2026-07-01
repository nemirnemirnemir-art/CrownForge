extends RefCounted

const BASE_MORALE_BONUS := 10
const PASSIVE_MORALE_BONUS := 5

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false
var _is_vzor_active: bool = false
var _last_reported_morale_bonus: int = 0

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_producing = false
	_is_vzor_active = false
	_last_reported_morale_bonus = 0

func set_vzor_active(active: bool) -> void:
	if _is_vzor_active == active:
		_refresh_morale_if_needed()
		return
	_is_vzor_active = active
	_refresh_morale_if_needed(true)

func tick(delta: float) -> Dictionary:
	_refresh_morale_if_needed()
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

func get_runtime_state() -> Dictionary:
	return {
		"timer": _timer,
		"is_producing": _is_producing,
		"is_vzor_active": _is_vzor_active,
		"last_reported_morale_bonus": _last_reported_morale_bonus,
	}

func load_runtime_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	_timer = maxf(0.0, float(state.get("timer", 0.0)))
	_is_producing = bool(state.get("is_producing", false))
	_is_vzor_active = bool(state.get("is_vzor_active", false))
	_last_reported_morale_bonus = int(state.get("last_reported_morale_bonus", 0))
	_refresh_morale_if_needed(true)

func get_morale_bonus() -> int:
	var total := 0
	
	# Active bonus (when under GAZE)
	if _is_vzor_active and _has_upgrade("concert:0"):
		total += BASE_MORALE_BONUS
	
	# Passive bonus (from passive upgrade)
	if _has_upgrade("concert:1"):
		total += PASSIVE_MORALE_BONUS
	
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
