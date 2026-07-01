extends SceneTree

const SaveResetFlowScript := preload("res://core/save/SaveResetFlow.gd")


class FakeStage:
	extends RefCounted

	var stage: int = 1
	var max_stage: int = 3
	var reset_calls: int = 0

	func get_current_stage() -> int: return stage
	func get_max_stage_reached() -> int: return max_stage
	func reset_progress() -> void: reset_calls += 1


class FakeSimpleReset:
	extends RefCounted

	var reset_calls: int = 0

	func reset() -> void:
		reset_calls += 1


class FakeInventory:
	extends RefCounted

	var init_calls: int = 0
	var reset_calls: int = 0
	var items: Array = [1]

	func initialize() -> void:
		init_calls += 1

	func reset() -> void:
		reset_calls += 1


class FakeBuildings:
	extends RefCounted

	func get_building_registry() -> Array:
		return ["town_hall", "farm"]

	func set_buildings(_value: Dictionary) -> void:
		pass


class FakePotions:
	extends RefCounted

	func set_potions(_value: int) -> void:
		pass

	func set_potion_timer(_value: float) -> void:
		pass


class FakePerks:
	extends RefCounted

	func set_unlocked_perks(_value: Array) -> void:
		pass

	func set_available_perks(_value: Array) -> void:
		pass


class FakePopulation:
	extends RefCounted

	var init_calls: int = 0

	func set_population_status(_value: Dictionary) -> void:
		pass

	func set_worker_assignments(_value: Dictionary) -> void:
		pass

	func initialize_population() -> void:
		init_calls += 1


class FakeHospital:
	extends RefCounted

	var timer: float = 5.0

	func set_hospital_timer(value: float) -> void:
		timer = value


class FakeBonuses:
	extends RefCounted

	var invalidations: int = 0

	func invalidate_cache() -> void:
		invalidations += 1


class FakeDamagePool:
	extends RefCounted

	var resets: int = 0

	func reset_pool() -> void:
		resets += 1


class FakeGameScene:
	extends Node

	func _ready() -> void:
		add_to_group("game_scene")

	var resets: int = 0

	func reset_scene() -> void:
		resets += 1


class FakeDelete:
	extends RefCounted

	var deletes: int = 0

	func delete_file(_path: String) -> bool:
		deletes += 1
		return true


class FakeCounter:
	extends RefCounted

	var saves: int = 0
	var food_events: int = 0
	var pop_events: int = 0

	func save_game() -> void:
		saves += 1

	func emit_food(_a: float, _b: float) -> void:
		food_events += 1

	func emit_pop(_a: int, _b: int) -> void:
		pop_events += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SaveResetFlowScript.new()
	if flow == null:
		push_error("[test_savecore_reset_flow] failed to instantiate helper")
		quit(1)
		return

	var root := Node.new()
	get_root().add_child(root)
	var game_scene := FakeGameScene.new()
	root.add_child(game_scene)
	await process_frame

	var stage := FakeStage.new()
	var economy := FakeSimpleReset.new()
	var hero := FakeSimpleReset.new()
	var town := FakeSimpleReset.new()
	var resource := FakeSimpleReset.new()
	var gaze := FakeSimpleReset.new()
	var forge := FakeSimpleReset.new()
	var mine := FakeSimpleReset.new()
	var artifact := FakeSimpleReset.new()
	var inventory := FakeInventory.new()
	var buildings := FakeBuildings.new()
	var potions := FakePotions.new()
	var perks := FakePerks.new()
	var population := FakePopulation.new()
	var hospital := FakeHospital.new()
	var bonuses := FakeBonuses.new()
	var damage_pool := FakeDamagePool.new()
	var delete_stub := FakeDelete.new()
	var counter := FakeCounter.new()

	flow.reset_progress(
		stage,
		economy,
		hero,
		town,
		inventory,
		resource,
		gaze,
		artifact,
		forge,
		mine,
		damage_pool,
		buildings,
		potions,
		perks,
		population,
		hospital,
		bonuses,
		delete_stub,
		"user://save.json",
		Callable(counter, "save_game"),
		Callable(counter, "emit_food"),
		Callable(counter, "emit_pop"),
		func() -> int: return 9
	)

	if stage.reset_calls != 1 or economy.reset_calls != 1 or hero.reset_calls != 1 or town.reset_calls != 1:
		push_error("[test_savecore_reset_flow] core reset cascade mismatch")
		quit(1)
		return
	if resource.reset_calls != 1 or gaze.reset_calls != 1 or forge.reset_calls != 1 or mine.reset_calls != 1 or artifact.reset_calls != 1:
		push_error("[test_savecore_reset_flow] secondary reset cascade mismatch")
		quit(1)
		return
	if counter.saves != 1 or delete_stub.deletes != 1:
		push_error("[test_savecore_reset_flow] delete/save tail mismatch")
		quit(1)
		return
	if game_scene.resets != 1 or damage_pool.resets != 1:
		push_error("[test_savecore_reset_flow] scene/pool reset mismatch")
		quit(1)
		return

	print("[test_savecore_reset_flow] PASS")
	quit(0)
