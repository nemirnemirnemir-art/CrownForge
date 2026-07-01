extends SceneTree

const BarracksTransferLogicScript := preload("res://scripts/ui/town/barracks/BarracksTransferLogic.gd")
const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")


class FakeCollector:
	extends Node

	func resolve_unit_id(hero_id: String) -> String:
		return hero_id


func _init() -> void:
	call_deferred("_run_test")


func _hero_core() -> Node:
	return get_root().get_node_or_null("HeroCore")


func _population_core() -> Node:
	return get_root().get_node_or_null("PopulationCore")


func _fail(message: String) -> void:
	push_error("[test_barracks_transfer_logic] %s" % message)
	quit(1)


func _create_hired_hero(hero_id: String, is_summon: bool, active: bool, produced_by_military: bool = false) -> void:
	var hero_core := _hero_core()
	if hero_core == null:
		_fail("HeroCore autoload must exist")
		return
	if not hero_core.create_hero(hero_id, hero_id.capitalize(), "peasant", 0.0):
		_fail("failed to create hero %s" % hero_id)
		return
	hero_core.update_hero(hero_id, {
		"is_hired": true,
		"is_summon": is_summon,
		"produced_by_building_type": int(BuildingConfigScript.BuildingType.MILITARY) if produced_by_military else -1,
	})
	if active:
		hero_core.add_to_squad(hero_id)


func _run_test() -> void:
	var hero_core := _hero_core()
	var population_core := _population_core()
	if hero_core == null or population_core == null:
		_fail("HeroCore and PopulationCore autoloads must exist")
		return
	hero_core.reset()
	population_core.set("_max_population", 5)

	_create_hired_hero("peasant_a", false, true)
	_create_hired_hero("peasant_b", false, true)
	_create_hired_hero("peasant_c", false, true)
	_create_hired_hero("peasant_d", false, true)
	_create_hired_hero("peasant_summon", true, true)
	_create_hired_hero("peasant_reserve", false, false, true)

	var logic = BarracksTransferLogicScript.new()
	logic.initialize(FakeCollector.new())

	if logic.can_add_to_field():
		_fail("barracks transfer must block normal deploy when field is full because of active summon occupancy")
		return
	if logic.move_one_from_barracks_to_field("peasant_reserve"):
		_fail("move_one_from_barracks_to_field must fail when battlefield is already at or above cap")
		return

	print("[test_barracks_transfer_logic] PASS")
	quit(0)
