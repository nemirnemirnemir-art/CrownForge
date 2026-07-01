extends SceneTree

const MapSlotTickRoutingScript := preload("res://scripts/map_slot/MapSlotTickRouting.gd")


class FakeTickManager:
	extends RefCounted

	var scaled_delta: float = 0.0

	func get_scaled_delta(_delta: float) -> float:
		return scaled_delta


class FakeUI:
	extends RefCounted
	var hidden := false
	func hide_progress() -> void:
		hidden = true


class FakeProductionFlow:
	extends RefCounted
	var market_ticked := false
	func tick_market(_ui: Variant, _market: Variant, _delta: float) -> Dictionary:
		market_ticked = true
		return {}


class FakeProduction:
	extends RefCounted
	func tick(_delta: float, _bid: String, _cfg: Variant) -> Dictionary:
		return {"completed": true, "is_producing": true, "progress_ratio": 1.0}


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = MapSlotTickRoutingScript.new()
	if helper == null:
		push_error("[test_mapslot_tick_routing] failed to instantiate helper")
		quit(1)
		return

	var ticked: Array[float] = []
	var tick_manager := FakeTickManager.new()
	tick_manager.scaled_delta = 0.75

	helper.tick_active_building(
		"windmill",
		false,
		tick_manager,
		0.5,
		func(next_delta: float) -> void: ticked.append(next_delta)
	)
	if ticked.size() != 1 or absf(ticked[0] - 0.75) > 0.01:
		push_error("[test_mapslot_tick_routing] active building must tick with scaled delta")
		quit(1)
		return

	ticked.clear()
	helper.tick_active_building("", false, tick_manager, 0.5, func(next_delta: float) -> void: ticked.append(next_delta))
	if not ticked.is_empty():
		push_error("[test_mapslot_tick_routing] empty building must not tick")
		quit(1)
		return

	ticked.clear()
	helper.tick_passive_special_building(
		"tesla_tower",
		false,
		{},
		["tesla_tower", "monument_to_the_kings_gaze"],
		false,
		tick_manager,
		0.4,
		func(next_delta: float) -> void: ticked.append(next_delta)
	)
	if ticked.size() != 1:
		push_error("[test_mapslot_tick_routing] passive special building must tick when not under gaze")
		quit(1)
		return

	ticked.clear()
	helper.tick_passive_special_building(
		"tesla_tower",
		true,
		{},
		["tesla_tower", "monument_to_the_kings_gaze"],
		false,
		tick_manager,
		0.4,
		func(next_delta: float) -> void: ticked.append(next_delta)
	)
	if not ticked.is_empty():
		push_error("[test_mapslot_tick_routing] passive special building must stop ticking under king gaze")
		quit(1)
		return

	# --- dispatch_production_tick tests ---

	# empty building_id must hide progress and return {}
	var fake_ui := FakeUI.new()
	var dispatch_result = helper.dispatch_production_tick(
		"", fake_ui, null, null, null, null, null, null, null,
		0.1, Callable(), Callable(), Callable(), Callable(), Callable(), false, 0
	)
	if not fake_ui.hidden:
		push_error("[test_mapslot_tick_routing] dispatch with empty building must hide progress")
		quit(1)
		return
	if not dispatch_result.is_empty():
		push_error("[test_mapslot_tick_routing] dispatch with empty building must return empty dict")
		quit(1)
		return

	# market branch: delegates to production_flow.tick_market
	var fake_flow := FakeProductionFlow.new()
	var market_result := helper.dispatch_production_tick(
		"market", null, null, "fake_market", fake_flow, null, null, null, null,
		0.1, Callable(), Callable(), Callable(), Callable(), Callable(), false, 0
	)
	if not fake_flow.market_ticked:
		push_error("[test_mapslot_tick_routing] dispatch with market must call production_flow.tick_market")
		quit(1)
		return
	if not market_result.is_empty():
		push_error("[test_mapslot_tick_routing] dispatch market must return empty dict")
		quit(1)
		return

	# regular building: durability and depletion callbacks fired on completion
	var cb_state := {"durability": false, "depletion": false}
	var fake_prod := FakeProduction.new()
	helper.dispatch_production_tick(
		"windmill", null, fake_prod, null, null, null, null, null, null,
		0.1,
		func() -> void: cb_state["durability"] = true,
		func(_cfg: Variant) -> void: cb_state["depletion"] = true,
		Callable(), Callable(), Callable(), false, 0
	)
	if not cb_state["durability"]:
		push_error("[test_mapslot_tick_routing] dispatch regular completed must call update_durability_cb")
		quit(1)
		return
	if not cb_state["depletion"]:
		push_error("[test_mapslot_tick_routing] dispatch regular completed must call handle_resource_depletion_cb")
		quit(1)
		return

	print("[test_mapslot_tick_routing] PASS")
	quit(0)
