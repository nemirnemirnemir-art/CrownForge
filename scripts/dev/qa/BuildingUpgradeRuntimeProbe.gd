extends RefCounted
class_name BuildingUpgradeRuntimeProbe

class FakeSlot:
	extends Node

	var slot_index: int = -1
	var current_building_id: String = ""
	var _vzor_active: bool = false
	var _special_handler: Variant = null

	func _init(new_slot_index: int, building_id: String, vzor_active: bool, special_handler: Variant = null) -> void:
		slot_index = new_slot_index
		current_building_id = building_id
		_vzor_active = vzor_active
		_special_handler = special_handler

	func is_effectively_vzor_active() -> bool:
		return _vzor_active

	func get_special_handler() -> Variant:
		return _special_handler


class FakeMapLayout:
	extends Node

	var slots: Array = []


class FakeGameScene:
	extends Node

	var map_layout_node: Node = null


var _tree: SceneTree = Engine.get_main_loop() as SceneTree
var _root: Node = _tree.root if _tree else null
var _scene_fixture: Node = null
var _previous_current_scene: Node = null
var _hero_counter: int = 0


func reset_runtime() -> void:
	_cleanup_scene_fixture()
	_reset_artifact_core()
	_reset_building_upgrade_core()
	_reset_hero_core()
	_reset_troop_bonus_core()
	_reset_morale_system()
	_hero_counter = 0


func create_game_scene_with_slots(slot_specs: Array[Dictionary]) -> Node:
	_cleanup_scene_fixture()
	if _tree == null or _root == null:
		return null
	var map_layout := FakeMapLayout.new()
	var slots: Array = []
	for spec: Dictionary in slot_specs:
		slots.append(FakeSlot.new(
			int(spec.get("slot_index", slots.size())),
			String(spec.get("building_id", "")),
			bool(spec.get("active", false)),
			spec.get("special_handler", null)
		))
	map_layout.slots = slots
	var scene := FakeGameScene.new()
	scene.name = "QaRuntimeScene"
	scene.map_layout_node = map_layout
	scene.add_to_group("game_scene")
	_root.add_child(scene)
	_previous_current_scene = _tree.current_scene
	_tree.current_scene = scene
	_scene_fixture = scene
	return scene


func create_active_hero(unit_id: String, icon_id: String = "") -> String:
	var hero_core := get_hero_core()
	if hero_core == null:
		return ""
	_hero_counter += 1
	var hero_id := "%s_%d" % [unit_id, _hero_counter]
	var final_icon_id := icon_id if icon_id != "" else unit_id
	var created := false
	if hero_core.has_method("create_hero"):
		created = bool(hero_core.call("create_hero", hero_id, unit_id.capitalize(), final_icon_id, 0.0))
	if not created:
		return ""
	if hero_core.has_method("update_hero"):
		hero_core.call("update_hero", hero_id, {
			"is_hired": true,
			"mood": 50.0,
			"isDead": false,
			"isRemoved": false,
		})
	if hero_core.has_method("add_to_squad"):
		hero_core.call("add_to_squad", hero_id)
	return hero_id


func unlock_upgrade(upgrade_id: String) -> void:
	var upgrade_core := get_building_upgrade_core()
	if upgrade_core == null:
		return
	var building_id := String(upgrade_id).split(":", false, 1)[0]
	if upgrade_core.has_method("unlock_building_upgrade"):
		upgrade_core.call("unlock_building_upgrade", building_id, upgrade_id)


func get_building_bonus_morale() -> int:
	var morale_system := get_morale_system()
	if morale_system == null:
		return 0
	if morale_system.has_method("_get_building_bonus"):
		var raw_bonus: Variant = morale_system.call("_get_building_bonus")
		if raw_bonus is Dictionary:
			var total_bonus: int = 0
			for value in (raw_bonus as Dictionary).values():
				total_bonus += int(value)
			return total_bonus
		return int(raw_bonus)
	return 0


func get_total_morale() -> int:
	var morale_system := get_morale_system()
	if morale_system == null:
		return 0
	if morale_system.has_method("calculate_morale"):
		morale_system.call("calculate_morale")
	if morale_system.has_method("get_total_morale"):
		return int(morale_system.call("get_total_morale"))
	return 0


func get_spell_damage_multiplier() -> float:
	var artifact_core := get_artifact_core()
	if artifact_core == null:
		return 1.0
	if artifact_core.has_method("get_spell_damage_multiplier"):
		return float(artifact_core.call("get_spell_damage_multiplier"))
	return 1.0


func get_cost_multiplier(building_id: String) -> float:
	var upgrade_core := get_building_upgrade_core()
	if upgrade_core == null:
		return 1.0
	if upgrade_core.has_method("get_cost_multiplier"):
		return float(upgrade_core.call("get_cost_multiplier", building_id))
	return 1.0


func resolve_mega_militia_unit(building_id: String, produced_unit_id: String) -> String:
	var upgrade_core := get_building_upgrade_core()
	if upgrade_core == null:
		return produced_unit_id
	if upgrade_core.has_method("resolve_mega_militia_unit"):
		return String(upgrade_core.call("resolve_mega_militia_unit", building_id, produced_unit_id))
	return produced_unit_id


func get_mega_militia_counter() -> int:
	var upgrade_core := get_building_upgrade_core()
	if upgrade_core == null:
		return 0
	if upgrade_core.has_method("get_mega_militia_counter"):
		return int(upgrade_core.call("get_mega_militia_counter"))
	return 0


func get_hero_total_stats(hero_id: String) -> Dictionary:
	var hero_core := get_hero_core()
	if hero_core == null:
		return {}
	if hero_core.has_method("get_hero_total_stats"):
		return hero_core.call("get_hero_total_stats", hero_id)
	return {}


func resolve_candidate_with_class(target_class: int, candidates: Array[String]) -> String:
	var troop_bonus_core := get_troop_bonus_core()
	if troop_bonus_core == null or not troop_bonus_core.has_method("get_unit_classes"):
		return ""
	for unit_id: String in candidates:
		var classes: Variant = troop_bonus_core.call("get_unit_classes", unit_id)
		if classes is Array and (classes as Array).has(target_class):
			return unit_id
	return ""


func get_building_upgrade_core() -> Node:
	return _get_autoload("BuildingUpgradeCore")


func get_hero_core() -> Node:
	return _get_autoload("HeroCore")


func get_troop_bonus_core() -> Node:
	return _get_autoload("TroopBonusCore")


func get_morale_system() -> Node:
	return _get_autoload("MoraleSystem")


func get_artifact_core() -> Node:
	return _get_autoload("ArtifactCore")


func cleanup() -> void:
	_cleanup_scene_fixture()


func _get_autoload(node_name: String) -> Node:
	if _root == null:
		return null
	return _root.get_node_or_null(node_name)


func _reset_building_upgrade_core() -> void:
	var upgrade_core := get_building_upgrade_core()
	if upgrade_core and upgrade_core.has_method("load_save_data"):
		upgrade_core.call("load_save_data", {"unlocked_by_building": {}, "mega_militia_counter": 0})


func _reset_hero_core() -> void:
	var hero_core := get_hero_core()
	if hero_core and hero_core.has_method("reset"):
		hero_core.call("reset")


func _reset_troop_bonus_core() -> void:
	var troop_bonus_core := get_troop_bonus_core()
	if troop_bonus_core and troop_bonus_core.has_method("reset"):
		troop_bonus_core.call("reset")


func _reset_morale_system() -> void:
	var morale_system := get_morale_system()
	if morale_system == null:
		return
	if morale_system.has_method("reset_debug_morale"):
		morale_system.call("reset_debug_morale")
	if morale_system.has_method("calculate_morale"):
		morale_system.call("calculate_morale")


func _reset_artifact_core() -> void:
	var artifact_core := get_artifact_core()
	if artifact_core and artifact_core.has_method("reset"):
		artifact_core.call("reset")


func _cleanup_scene_fixture() -> void:
	if _scene_fixture == null or not is_instance_valid(_scene_fixture):
		_scene_fixture = null
		_previous_current_scene = null
		return
	if _tree and _tree.current_scene == _scene_fixture:
		_tree.current_scene = _previous_current_scene
	if _scene_fixture.get_parent() != null:
		_scene_fixture.get_parent().remove_child(_scene_fixture)
	_scene_fixture.free()
	_scene_fixture = null
	_previous_current_scene = null
