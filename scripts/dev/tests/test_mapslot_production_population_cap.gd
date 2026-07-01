extends SceneTree

const MapSlotProductionScript := preload("res://scripts/map_slot/MapSlotProduction.gd")
const BuildingConfigScript := preload("res://core/buildings/BuildingConfig.gd")


func _init() -> void:
	call_deferred("_run_test")


func _hero_core() -> Node:
	return get_root().get_node_or_null("HeroCore")


func _population_core() -> Node:
	return get_root().get_node_or_null("PopulationCore")


func _artifact_core() -> Node:
	return get_root().get_node_or_null("ArtifactCore")


func _fail(message: String) -> void:
	push_error("[test_mapslot_production_population_cap] %s" % message)
	quit(1)


func _create_hired_hero(hero_id: String, is_summon: bool, active: bool) -> void:
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
	})
	if active:
		hero_core.add_to_squad(hero_id)


func _run_test() -> void:
	var hero_core := _hero_core()
	var population_core := _population_core()
	if hero_core == null or population_core == null:
		_fail("HeroCore and PopulationCore autoloads must exist")
		return
	var artifact_core := _artifact_core()
	if artifact_core == null:
		_fail("ArtifactCore autoload must exist")
		return
	artifact_core.reset()
	hero_core.reset()
	hero_core.set_troop_spawn_mode(hero_core.TROOP_SPAWN_MODE_BATTLEFIELD)
	population_core.set("_max_population", 5)

	_create_hired_hero("peasant_a", false, true)
	_create_hired_hero("peasant_b", false, true)
	_create_hired_hero("peasant_c", false, true)
	_create_hired_hero("peasant_d", false, true)
	_create_hired_hero("peasant_summon", true, true)

	var production = MapSlotProductionScript.new()
	production.initialize(1.0, -1, 4, "test_barracks")

	var config := BuildingConfigScript.new()
	config.building_id = "test_barracks"
	config.building_type = BuildingConfigScript.BuildingType.MILITARY
	config.produced_unit_id = "peasant"
	config.max_units = 3
	config.cycle_time = 1.0

	var result: Dictionary = production.tick(0.25, "test_barracks", config)
	if bool(result.get("is_producing", false)):
		_fail("military production must not start battlefield deploy production when summon occupancy already fills cap")
		return

	hero_core.reset()
	hero_core.set_troop_spawn_mode(hero_core.TROOP_SPAWN_MODE_BARRACKS)
	artifact_core.add_artifact("iron_hoe", true)
	for i in range(3):
		var hero_id := "starter_peasant_%d" % i
		if not hero_core.create_hero(hero_id, hero_id.capitalize(), "peasant", 0.0):
			_fail("failed to create starter hero %s" % hero_id)
			return
		hero_core.update_hero(hero_id, {
			"is_hired": true,
			"produced_by_building_id": "small_peasants_hut",
			"produced_by_slot_index": 4,
		})

	var starter_production = MapSlotProductionScript.new()
	starter_production.initialize(1.0, -1, 4, "small_peasants_hut")
	var starter_config := BuildingConfigScript.new()
	starter_config.building_id = "small_peasants_hut"
	starter_config.building_type = BuildingConfigScript.BuildingType.MILITARY
	starter_config.produced_unit_id = "peasant"
	starter_config.max_units = 3
	starter_config.cycle_time = 1.0
	var starter_result: Dictionary = starter_production.tick(0.25, "small_peasants_hut", starter_config)
	if not bool(starter_result.get("is_producing", false)):
		_fail("iron_hoe must let starter troop production continue past the base 3-unit limit")
		return

	print("[test_mapslot_production_population_cap] PASS")
	quit(0)
