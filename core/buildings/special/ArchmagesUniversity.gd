extends RefCounted

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const CHOICE_UPGRADE_ID: String = "archmages_university:0"
const SPEED_UPGRADE_ID: String = "archmages_university:1"

var _slot: Node = null
var _config: BuildingConfig = null
var _timer: float = 0.0
var _is_producing: bool = false
var _pool: Array[String] = []

func initialize(slot: Node, config: BuildingConfig) -> void:
	_slot = slot
	_config = config
	_timer = 0.0
	_is_producing = false
	_pool.clear()
	var dir := DirAccess.open("res://resources/spells/configs")
	if dir == null:
		return
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if (not dir.current_is_dir()) and file.ends_with(".tres"):
			var spell_id := file.replace(".tres", "")
			if spell_id.begins_with("legendary_"):
				_pool.append(spell_id)
		file = dir.get_next()
	dir.list_dir_end()

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
	if _has_upgrade(CHOICE_UPGRADE_ID):
		_enqueue_spell_choice_reward(true)
		return
	if _pool.is_empty():
		return
	var picked_id: String = _pool[randi() % _pool.size()]
	_grant_spell(picked_id)

func _enqueue_spell_choice_reward(legendary_only: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	var scene := tree.current_scene
	if scene.has_method("enqueue_spell_choice_reward"):
		scene.call("enqueue_spell_choice_reward", 2, legendary_only, 1)

func _grant_spell(spell_id: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var spell_panel := tree.get_first_node_in_group("spell_panel") if tree else null
	if spell_panel and spell_panel.has_method("add_spell"):
		var config := PathRegistryScript.load_spell_config(spell_id)
		if config != null and bool(spell_panel.call("add_spell", config)):
			return
	if SpellCore and SpellCore.has_method("add_spell"):
		SpellCore.add_spell(spell_id, 1)

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
		speed_mult *= 1.2
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
