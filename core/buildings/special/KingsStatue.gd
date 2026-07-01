extends "res://core/buildings/special/GenericSpecialBuilding.gd"

const CRYSTAL_COST_PER_TICK: int = 2
const COOLDOWN_REDUCTION_SEC: float = 1.0
const CRYSTAL_BONUS_UPGRADE_ID: String = "kings_statue:0"

var _is_vzor_active: bool = false

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_vzor_active = false

func set_vzor_active(active: bool) -> void:
	_is_vzor_active = active
	if not _is_vzor_active:
		_timer = 0.0

func tick(delta: float) -> Dictionary:
	if _config == null:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}
	var cycle_time: float = max(0.001, float(_config.cycle_time))
	if not _is_vzor_active:
		return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": cycle_time}
	if delta <= 0.0:
		return {"progress_ratio": max(0.0, (cycle_time - _timer) / cycle_time), "is_producing": true, "completed": false, "cycle_time": cycle_time}

	_timer += delta
	var completed: bool = false
	var tick_count: int = int(floor(_timer / cycle_time))
	if tick_count > 0:
		_timer = fmod(_timer, cycle_time)
		for _i in range(tick_count):
			if _perform_tick():
				completed = true
	var progress_ratio: float = max(0.0, (cycle_time - _timer) / cycle_time)
	return {"progress_ratio": progress_ratio, "is_producing": true, "completed": completed, "cycle_time": cycle_time}

func _perform_tick() -> bool:
	var resource_core := _get_autoload("ResourceCore")
	var king_spell_state := _get_autoload("KingSpellState")
	if resource_core == null or king_spell_state == null:
		return false
	if not bool(resource_core.call("consume_resource", "crystal", CRYSTAL_COST_PER_TICK)):
		return false
	if king_spell_state.has_method("reduce_all_active_cooldowns_flat"):
		king_spell_state.call("reduce_all_active_cooldowns_flat", COOLDOWN_REDUCTION_SEC)
	_try_bonus_crystal_production(resource_core)
	return true

func _try_bonus_crystal_production(resource_core: Node) -> void:
	var upgrade_core := _get_autoload("BuildingUpgradeCore")
	if upgrade_core == null:
		return
	var slot_index: int = _get_slot_index()
	if slot_index < 0:
		return
	if not bool(upgrade_core.call("has_upgrade", slot_index, CRYSTAL_BONUS_UPGRADE_ID)):
		return
	if randf() < 0.25:
		resource_core.call("add_resource", "crystal", 1)

func _get_slot_index() -> int:
	if _slot == null:
		return -1
	var raw_slot_index: Variant = _slot.get("slot_index")
	if raw_slot_index == null:
		return -1
	return int(raw_slot_index)

func _get_autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
