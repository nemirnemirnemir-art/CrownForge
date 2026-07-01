extends SceneTree

const RegistryFlowScript := preload("res://core/building_upgrade/BuildingUpgradeRegistryFlow.gd")


class FakeCounter:
	extends RefCounted

	var emits: Array = []
	var saves: int = 0

	func emit_change(building_id: String, level: int) -> void:
		emits.append([building_id, level])

	func save() -> void:
		saves += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = RegistryFlowScript.new()
	if flow == null:
		push_error("[test_building_upgrade_registry_flow] failed to instantiate helper")
		quit(1)
		return

	var state := {}
	var counter := FakeCounter.new()
	flow.unlock_building_upgrade(state, "concert", "concert:0", Callable(counter, "emit_change"), Callable(counter, "save"))
	if not flow.has_building_upgrade(state, "concert", "concert:0"):
		push_error("[test_building_upgrade_registry_flow] unlock failed")
		quit(1)
		return
	if counter.emits.is_empty() or counter.saves != 1:
		push_error("[test_building_upgrade_registry_flow] unlock side effects mismatch")
		quit(1)
		return

	var save_data: Dictionary = flow.get_save_data(2, state)
	var loaded := flow.load_save_data({"unlocked_by_building": save_data["unlocked_by_building"]})
	if not flow.has_building_upgrade(loaded, "concert", "concert:0"):
		push_error("[test_building_upgrade_registry_flow] save/load mismatch")
		quit(1)
		return

	print("[test_building_upgrade_registry_flow] PASS")
	quit(0)
