extends "res://core/buildings/special/GenericSpecialBuilding.gd"

const BASE_HEAL_PER_TICK: int = 15
const HEALING_UPGRADE_ID: String = "hospital:0"
const MORALE_UPGRADE_ID: String = "hospital:1"

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
	var heal_ticks: int = int(floor(_timer / cycle_time))
	if heal_ticks > 0:
		completed = true
		_timer = fmod(_timer, cycle_time)
		for _i in range(heal_ticks):
			_heal_one_injured_hero()
	var progress_ratio: float = max(0.0, (cycle_time - _timer) / cycle_time)
	return {"progress_ratio": progress_ratio, "is_producing": true, "completed": completed, "cycle_time": cycle_time}

func get_morale_bonus() -> int:
	var upgrade_core := _get_autoload("BuildingUpgradeCore")
	if not _is_vzor_active:
		return 0
	if upgrade_core == null:
		return 0
	var slot_index: int = _get_slot_index()
	if slot_index < 0:
		return 0
	if not bool(upgrade_core.call("has_upgrade", slot_index, MORALE_UPGRADE_ID)):
		return 0
	return 5

func _heal_one_injured_hero() -> void:
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return
	var hero_query: Variant = hero_core.get("query")
	if hero_query == null:
		return
	var hero_id: String = _find_injured_hero_id()
	if hero_id == "":
		return
	var before_hp: float = float(hero_query.call("get_hero_hp", hero_id))
	hero_core.call("heal_hero", hero_id, _get_heal_amount())
	var after_hp: float = float(hero_query.call("get_hero_hp", hero_id))
	var healed_amount: int = int(round(after_hp - before_hp))
	if healed_amount <= 0:
		return
	var event_bus := _get_autoload("EventBus")
	if event_bus != null:
		event_bus.get("hero_healed_by_hospital").emit(hero_id, healed_amount)

func _find_injured_hero_id() -> String:
	var hero_core := _get_autoload("HeroCore")
	if hero_core == null:
		return ""
	var hero_query: Variant = hero_core.get("query")
	if hero_query == null:
		return ""
	var candidate_ids: Array[String] = []
	for raw_hero_id in hero_query.call("get_all_hero_ids"):
		var hero_id: String = String(raw_hero_id)
		if hero_id == "":
			continue
		if bool(hero_query.call("is_hero_dead", hero_id)):
			continue
		if not bool(hero_query.call("is_hero_hired", hero_id)):
			continue
		if not bool(hero_query.call("is_hero_in_squad", hero_id)):
			continue
		var current_hp: float = float(hero_query.call("get_hero_hp", hero_id))
		var max_hp: float = float(hero_query.call("get_hero_max_hp", hero_id))
		if max_hp <= 0.0:
			continue
		if current_hp >= max_hp:
			continue
		candidate_ids.append(hero_id)
	candidate_ids.sort()
	if candidate_ids.is_empty():
		return ""
	return candidate_ids[0]

func _get_heal_amount() -> int:
	var heal_amount: float = float(BASE_HEAL_PER_TICK)
	var upgrade_core := _get_autoload("BuildingUpgradeCore")
	if upgrade_core != null:
		var slot_index: int = _get_slot_index()
		if slot_index >= 0 and bool(upgrade_core.call("has_upgrade", slot_index, HEALING_UPGRADE_ID)):
			heal_amount *= 1.5
	return int(round(heal_amount))

func _get_autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

func _get_slot_index() -> int:
	if _slot == null:
		return -1
	var raw_slot_index: Variant = _slot.get("slot_index")
	if raw_slot_index == null:
		return -1
	return int(raw_slot_index)
