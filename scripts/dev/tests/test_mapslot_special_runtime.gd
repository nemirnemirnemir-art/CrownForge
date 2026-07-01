extends SceneTree

const MapSlotSpecialRuntimeScript := preload("res://scripts/map_slot/MapSlotSpecialRuntime.gd")


class FakeTownCore:
	extends RefCounted

	var set_calls: Array[Dictionary] = []
	var stored_state: Dictionary = {}

	func set_building_slot_state(building_id: String, slot_index: int, state: Dictionary, request_save: bool) -> void:
		set_calls.append({
			"building_id": building_id,
			"slot_index": slot_index,
			"state": state.duplicate(true),
			"request_save": request_save,
		})

	func get_building_slot_state(_building_id: String, _slot_index: int) -> Variant:
		return stored_state.duplicate(true)


class FakeSpecialHandler:
	extends RefCounted

	var runtime_state: Dictionary = {"mode": 2}
	var loaded_state: Dictionary = {}

	func get_runtime_state() -> Dictionary:
		return runtime_state.duplicate(true)

	func load_runtime_state(state: Dictionary) -> void:
		loaded_state = state.duplicate(true)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = MapSlotSpecialRuntimeScript.new()
	if helper == null:
		push_error("[test_mapslot_special_runtime] failed to instantiate helper")
		quit(1)
		return

	var town_core := FakeTownCore.new()
	var handler := FakeSpecialHandler.new()

	helper.persist_special_runtime_state("research_table", 4, town_core, handler, true)
	if town_core.set_calls.size() != 1:
		push_error("[test_mapslot_special_runtime] persist must store runtime state once")
		quit(1)
		return
	if not bool(town_core.set_calls[0].get("request_save", false)):
		push_error("[test_mapslot_special_runtime] request_save flag was not propagated")
		quit(1)
		return

	town_core.stored_state = {"mode": 5, "charges": 2}
	helper.restore_special_runtime_state("research_table", 4, town_core, handler)
	if handler.loaded_state.get("mode", -1) != 5:
		push_error("[test_mapslot_special_runtime] restore must load stored runtime state")
		quit(1)
		return

	handler.loaded_state.clear()
	town_core.stored_state = {}
	helper.restore_special_runtime_state("research_table", 4, town_core, handler)
	if not handler.loaded_state.is_empty():
		push_error("[test_mapslot_special_runtime] empty state must not be restored")
		quit(1)
		return

	print("[test_mapslot_special_runtime] PASS")
	quit(0)
