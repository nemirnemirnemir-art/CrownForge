extends SceneTree

const MapSlotMiscFlowScript := preload("res://scripts/map_slot/MapSlotMiscFlow.gd")


class FakeSpecialHandler:
	extends RefCounted

	var mode: int = 0
	var options: Array = ["x"]
	var set_mode_calls: Array[int] = []

	func set_mode(next_mode: int) -> void:
		mode = next_mode
		set_mode_calls.append(next_mode)

	func get_mode() -> int:
		return mode

	func get_ui_options() -> Array:
		return options.duplicate(true)


class FakePopup:
	extends RefCounted

	var setup_calls: Array = []
	var visible: bool = true

	func setup(value) -> void:
		setup_calls.append(value)

	func setup_options(options: Array, mode: int) -> void:
		setup_calls.append({"options": options.duplicate(true), "mode": mode})


class FakeSaveCore:
	extends RefCounted

	var requests: int = 0

	func request_save() -> void:
		requests += 1


class FakeCounter:
	extends RefCounted

	var count: int = 0
	var last_building_id: String = ""

	func bump() -> void:
		count += 1

	func set_building(building_id: String) -> void:
		count += 1
		last_building_id = building_id


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotMiscFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_misc_flow] failed to instantiate helper")
		quit(1)
		return

	var special := FakeSpecialHandler.new()
	var popup := FakePopup.new()
	var persisted := FakeCounter.new()
	var visuals := FakeCounter.new()
	var save_core := FakeSaveCore.new()
	var replaced := FakeCounter.new()

	flow.on_research_mode_requested(
		2,
		special,
		Callable(persisted, "bump"),
		Callable(visuals, "bump"),
		popup
	)
	if special.set_mode_calls != [2]:
		push_error("[test_mapslot_misc_flow] research mode must be forwarded to handler")
		quit(1)
		return
	if persisted.count != 1 or visuals.count != 1:
		push_error("[test_mapslot_misc_flow] research mode change must persist and refresh visuals")
		quit(1)
		return
	if popup.visible:
		push_error("[test_mapslot_misc_flow] research popup must close after mode change")
		quit(1)
		return

	flow.replace_current_building("farm", Callable(replaced, "set_building"), save_core)
	if replaced.count != 1 or replaced.last_building_id != "farm" or save_core.requests != 1:
		push_error("[test_mapslot_misc_flow] replace_current_building must replace and request save")
		quit(1)
		return

	print("[test_mapslot_misc_flow] PASS")
	quit(0)
