extends SceneTree

const TownUpgradeFlowScript := preload("res://core/town/TownUpgradeFlow.gd")


class FakeBuildings:
	extends RefCounted

	var upgrade_result: bool = true
	var levels: Dictionary = {"farm": 1}
	var building_map: Dictionary = {}
	var set_level_calls: Array = []

	func try_upgrade_building(_building_id: String) -> bool:
		return upgrade_result

	func get_building_level(building_id: String) -> int:
		return int(levels.get(building_id, 0))

	func get_buildings() -> Dictionary:
		return building_map

	func set_building_level(building_id: String, target_level: int) -> void:
		levels[building_id] = target_level
		set_level_calls.append([building_id, target_level])

	func get_building_config(_building_id: String):
		return {"base_population_capacity": 1, "population_per_level": 0}


class FakeBonuses:
	extends RefCounted

	var invalidations: int = 0

	func invalidate_cache() -> void:
		invalidations += 1


class FakePerks:
	extends RefCounted

	var checks: Array = []

	func check_unlocked_perks(building_id: String, level: int) -> void:
		checks.append([building_id, level])


class FakePopulation:
	extends RefCounted

	var init_calls: int = 0

	func initialize_population() -> void:
		init_calls += 1


class FakeEmitter:
	extends RefCounted

	var events: Array = []

	func emit_population_changed(used: int, max_pop: int) -> void:
		events.append([used, max_pop])

	func emit_building_upgraded(building_id: String, level: int) -> void:
		events.append([building_id, level])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = TownUpgradeFlowScript.new()
	if flow == null:
		push_error("[test_towncore_upgrade_flow] failed to instantiate helper")
		quit(1)
		return

	var buildings := FakeBuildings.new()
	var bonuses := FakeBonuses.new()
	var perks := FakePerks.new()
	var emitter := FakeEmitter.new()

	var upgraded: bool = flow.try_upgrade_building(
		buildings,
		bonuses,
		perks,
		"farm",
		Callable(emitter, "emit_building_upgraded")
	)
	if not upgraded:
		push_error("[test_towncore_upgrade_flow] expected upgrade success")
		quit(1)
		return
	if bonuses.invalidations != 1:
		push_error("[test_towncore_upgrade_flow] bonuses cache must be invalidated")
		quit(1)
		return
	if perks.checks.is_empty():
		push_error("[test_towncore_upgrade_flow] perks unlock check missing")
		quit(1)
		return

	buildings.building_map = {"farm": true}
	var debug_result: bool = flow.debug_set_building_level(
		buildings,
		bonuses,
		perks,
		"farm",
		4,
		Callable(emitter, "emit_building_upgraded")
	)
	if not debug_result:
		push_error("[test_towncore_upgrade_flow] debug_set_building_level should succeed for existing building")
		quit(1)
		return
	if buildings.levels.get("farm", 0) != 4:
		push_error("[test_towncore_upgrade_flow] target level not applied")
		quit(1)
		return

	print("[test_towncore_upgrade_flow] PASS")
	quit(0)
