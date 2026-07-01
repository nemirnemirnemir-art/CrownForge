extends SceneTree

const SaveAutosaveFlowScript := preload("res://core/save/SaveAutosaveFlow.gd")


class FakeCounter:
	extends RefCounted

	var saves: int = 0

	func save_game() -> void:
		saves += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = SaveAutosaveFlowScript.new()
	if flow == null:
		push_error("[test_savecore_autosave_flow] failed to instantiate helper")
		quit(1)
		return

	var state := {"save_requested": false, "save_due_time": 0.0}
	flow.request_save(state, false, 10.0, 1.0)
	if not bool(state["save_requested"]):
		push_error("[test_savecore_autosave_flow] request_save did not mark pending state")
		quit(1)
		return

	var counter := FakeCounter.new()
	flow.process_tick(state, 10.2, Callable(counter, "save_game"))
	if counter.saves != 0:
		push_error("[test_savecore_autosave_flow] save fired too early")
		quit(1)
		return
	flow.process_tick(state, 11.1, Callable(counter, "save_game"))
	if counter.saves != 1:
		push_error("[test_savecore_autosave_flow] save should fire after debounce")
		quit(1)
		return

	print("[test_savecore_autosave_flow] PASS")
	quit(0)
