extends Node
class_name BarracksTransferLogic

const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")
const PopulationBattlefieldQueryScript := preload("res://core/population/PopulationBattlefieldQuery.gd")

var _collector = null
var _battlefield_query: RefCounted = PopulationBattlefieldQueryScript.new()

func initialize(collector) -> void:
	_collector = collector

func _hero_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("HeroCore")

func _population_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("PopulationCore")

func can_add_to_field() -> bool:
	var population_core := _population_core()
	var hero_core := _hero_core()
	if population_core == null or hero_core == null:
		return true
	return _battlefield_query.has_field_capacity(hero_core, population_core)

func deploy_any_from_barracks() -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	
	var candidates: Array[String] = []
	for hero_value in hero_core.heroes.values():
		var hero: Dictionary = hero_value if hero_value is Dictionary else {}
		if not (hero is Dictionary):
			continue
		if not bool(hero.get("is_hired", false)) or bool(hero.get("isDead", false)):
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if bool(hero.get("isActive", false)):
			continue
		var produced_type := int(hero.get("produced_by_building_type", -1))
		if produced_type != int(BuildingConfigScript.BuildingType.MILITARY):
			continue
		var hero_id := str(hero.get("id", ""))
		if hero_id == "":
			continue
		candidates.append(hero_id)
	
	for hero_id in candidates:
		if not can_add_to_field():
			break
		hero_core.add_to_squad(hero_id)

func move_one_from_barracks_to_field(unit_id: String) -> bool:
	var hero_core := _hero_core()
	if hero_core == null:
		return false
	if not can_add_to_field():
		return false
	var hero_id := find_barracks_inactive_hero_id(unit_id)
	if hero_id != "":
		hero_core.add_to_squad(hero_id)
		return true
	return false

func move_one_from_field_to_barracks(unit_id: String, in_battle: bool, unit_info: Dictionary) -> bool:
	var hero_core := _hero_core()
	if hero_core == null:
		return false
	if in_battle:
		return false
	if not unit_info.is_empty():
		var cap := int(unit_info.get("capacity", 0))
		var in_barracks := int(unit_info.get("barracks_in_barracks", 0))
		if cap > 0 and in_barracks >= cap:
			return false
	var hero_id := find_barracks_active_hero_id(unit_id)
	if hero_id != "":
		hero_core.remove_from_squad(hero_id)
		return true
	return false

func dismiss_one_unowned_from_field(unit_id: String) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	var chosen := find_dismissable_active_hero_id(unit_id)
	if chosen != "":
		hero_core.remove_hero(chosen)

func dismiss_one_barracks_from_field(unit_id: String) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		return
	var chosen := find_barracks_active_hero_id(unit_id)
	if chosen != "":
		hero_core.remove_hero(chosen)

func find_barracks_active_hero_id(unit_id: String) -> String:
	var hero_core := _hero_core()
	if hero_core == null:
		return ""
	for hero_id in hero_core.active_hero_ids:
		var hero: Dictionary = hero_core.get_hero(hero_id)
		if hero.is_empty():
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if _collector.resolve_unit_id(hero_id) != unit_id:
			continue
		var produced_type := int(hero.get("produced_by_building_type", -1))
		if produced_type != int(BuildingConfigScript.BuildingType.MILITARY):
			continue
		return str(hero_id)
	return ""

func find_barracks_inactive_hero_id(unit_id: String) -> String:
	var hero_core := _hero_core()
	if hero_core == null:
		return ""
	for hero_value in hero_core.heroes.values():
		var hero: Dictionary = hero_value if hero_value is Dictionary else {}
		if not (hero is Dictionary):
			continue
		if not bool(hero.get("is_hired", false)) or bool(hero.get("isDead", false)):
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if bool(hero.get("isActive", false)):
			continue
		var produced_type := int(hero.get("produced_by_building_type", -1))
		if produced_type != int(BuildingConfigScript.BuildingType.MILITARY):
			continue
		var hero_id := str(hero.get("id", ""))
		if hero_id == "":
			continue
		if _collector.resolve_unit_id(hero_id) != unit_id:
			continue
		return hero_id
	return ""

func find_dismissable_active_hero_id(unit_id: String) -> String:
	var hero_core := _hero_core()
	if hero_core == null:
		return ""
	for hero_id in hero_core.active_hero_ids:
		var hero: Dictionary = hero_core.get_hero(hero_id)
		if hero.is_empty():
			continue
		if bool(hero.get("is_summon", false)):
			continue
		if _collector.resolve_unit_id(hero_id) != unit_id:
			continue
		var produced_type := int(hero.get("produced_by_building_type", -1))
		if produced_type == int(BuildingConfigScript.BuildingType.MILITARY):
			continue
		return str(hero_id)
	return ""
