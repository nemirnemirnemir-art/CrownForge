extends SceneTree

const MapSlotSpecialFlowScript := preload("res://scripts/map_slot/MapSlotSpecialFlow.gd")


class FakeUI:
	extends RefCounted

	var progress_updates: Array[Vector2] = []
	var hide_progress_calls: int = 0

	func update_progress(ratio: float, cycle: float) -> void:
		progress_updates.append(Vector2(ratio, cycle))

	func hide_progress() -> void:
		hide_progress_calls += 1


class FakePopup:
	extends RefCounted

	var setup_calls: Array = []

	func setup(value) -> void:
		setup_calls.append(value)


class FakeSpecialHandler:
	extends RefCounted

	var next_result: Dictionary = {}
	var ready: bool = false

	func tick(_delta: float) -> Dictionary:
		return next_result.duplicate(true)

	func get_runtime_state() -> Dictionary:
		return {"ready": ready}

	func is_ready() -> bool:
		return ready


class FakeBuildingConfig:
	extends RefCounted

	var cycle_time: float = 5.0


class FakeCounter:
	extends RefCounted

	var count: int = 0

	func bump() -> void:
		count += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotSpecialFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_special_flow] failed to instantiate helper")
		quit(1)
		return

	var ui := FakeUI.new()
	var popup := FakePopup.new()
	var handler := FakeSpecialHandler.new()
	var config := FakeBuildingConfig.new()
	var persisted: Array[bool] = []
	var counter := FakeCounter.new()

	handler.ready = true
	handler.next_result = {
		"is_producing": true,
		"progress_ratio": 0.4,
		"completed": true,
		"cycle_time": 7.0,
	}
	flow.tick_special(
		ui,
		handler,
		config,
		"basic_construction",
		popup,
		func(request_save: bool) -> void: persisted.append(request_save),
		Callable(counter, "bump"),
		func() -> bool: return true,
		false,
		0.1
	)

	if ui.progress_updates.is_empty() or ui.progress_updates[-1].distance_to(Vector2(0.4, 7.0)) > 0.01:
		push_error("[test_mapslot_special_flow] special tick must update progress")
		quit(1)
		return
	if persisted.is_empty() or not persisted[-1]:
		push_error("[test_mapslot_special_flow] completed special tick must persist runtime state with save")
		quit(1)
		return
	if popup.setup_calls.is_empty() or not bool(popup.setup_calls[-1]):
		push_error("[test_mapslot_special_flow] basic construction popup must be refreshed from special handler readiness")
		quit(1)
		return
	if counter.count != 1:
		push_error("[test_mapslot_special_flow] basic construction visuals must refresh after tick")
		quit(1)
		return

	handler.next_result = {"is_producing": false, "completed": false}
	flow.tick_special(
		ui,
		handler,
		config,
		"tesla_tower",
		popup,
		func(request_save: bool) -> void: persisted.append(request_save),
		Callable(counter, "bump"),
		func() -> bool: return false,
		false,
		0.1
	)
	if ui.hide_progress_calls <= 0:
		push_error("[test_mapslot_special_flow] non-producing special tick must hide progress")
		quit(1)
		return

	print("[test_mapslot_special_flow] PASS")
	quit(0)
