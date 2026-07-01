extends SceneTree

const MapSlotProductionFlowScript := preload("res://scripts/map_slot/MapSlotProductionFlow.gd")


class FakeUI:
	extends RefCounted

	var progress_updates: Array[Vector2] = []
	var hide_progress_calls: int = 0

	func update_progress(ratio: float, cycle: float) -> void:
		progress_updates.append(Vector2(ratio, cycle))

	func hide_progress() -> void:
		hide_progress_calls += 1


class FakeProduction:
	extends RefCounted

	var next_result: Dictionary = {}
	var tick_calls: int = 0
	var recover_calls: int = 0
	var _current_cycle: float = 2.0

	func tick(_delta: float, _building_id: String, _config) -> Dictionary:
		tick_calls += 1
		return next_result.duplicate(true)

	func recover_runtime_state(_config) -> Dictionary:
		recover_calls += 1
		return next_result.duplicate(true)


class FakeMarket:
	extends RefCounted

	var next_result: Dictionary = {}
	var tick_calls: int = 0
	const CYCLE_TIME := 1.0

	func tick(_delta: float) -> Dictionary:
		tick_calls += 1
		return next_result.duplicate(true)

	func _get_effective_cycle_time() -> float:
		return 1.5


class FakeConfig:
	extends RefCounted

	var building_type: int = BuildingConfig.BuildingType.RESOURCE
	var cycle_time: float = 3.0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotProductionFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_production_flow] failed to instantiate helper")
		quit(1)
		return

	var ui := FakeUI.new()
	var production := FakeProduction.new()
	var market := FakeMarket.new()
	var config := FakeConfig.new()

	production.next_result = {
		"is_producing": true,
		"progress_ratio": 0.5,
		"completed": false,
		"cycle_time": 4.0,
	}
	var result: Dictionary = flow.tick_regular_building(ui, production, 0.1, "farm", config)
	if production.tick_calls != 1:
		push_error("[test_mapslot_production_flow] regular production tick not forwarded")
		quit(1)
		return
	if ui.progress_updates.is_empty() or ui.progress_updates[-1].distance_to(Vector2(0.5, 4.0)) > 0.01:
		push_error("[test_mapslot_production_flow] regular production progress not shown")
		quit(1)
		return
	if not bool(result.get("is_producing", false)):
		push_error("[test_mapslot_production_flow] regular tick result lost")
		quit(1)
		return

	market.next_result = {
		"is_trading": true,
		"progress_ratio": 0.25,
	}
	flow.tick_market(ui, market, 0.1)
	if market.tick_calls != 1:
		push_error("[test_mapslot_production_flow] market tick not forwarded")
		quit(1)
		return
	if ui.progress_updates[-1].distance_to(Vector2(0.25, 1.5)) > 0.01:
		push_error("[test_mapslot_production_flow] market progress not shown with effective cycle")
		quit(1)
		return

	production.next_result = {
		"is_producing": false,
		"progress_ratio": 0.0,
		"completed": false,
		"cycle_time": 3.0,
	}
	flow.recover_runtime(ui, production, "farm", config)
	if production.recover_calls != 1:
		push_error("[test_mapslot_production_flow] recover_runtime_state not called")
		quit(1)
		return
	if ui.hide_progress_calls <= 0:
		push_error("[test_mapslot_production_flow] non-producing recovery must hide progress")
		quit(1)
		return

	print("[test_mapslot_production_flow] PASS")
	quit(0)
