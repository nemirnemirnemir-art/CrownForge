extends SceneTree

const MapSlotStatusFlowScript := preload("res://scripts/map_slot/MapSlotStatusFlow.gd")


class FakeUI:
	extends RefCounted

	var unit_updates: Array[Vector2] = []
	var hide_unit_calls: int = 0
	var durability_updates: Array[int] = []

	func update_unit_count(current: int, maximum: int) -> void:
		unit_updates.append(Vector2(current, maximum))

	func hide_unit_count() -> void:
		hide_unit_calls += 1

	func update_durability(remaining: int) -> void:
		durability_updates.append(remaining)


class FakeMilitaryTracker:
	extends RefCounted

	var info := {"show": true, "count": 3, "capacity": 7}

	func get_unit_label_info(_building_id: String) -> Dictionary:
		return info.duplicate(true)


class FakeProduction:
	extends RefCounted

	var durability: int = 5

	func get_durability() -> int:
		return durability


class FakeCounter:
	extends RefCounted

	var count: int = 0

	func bump() -> void:
		count += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = MapSlotStatusFlowScript.new()
	if helper == null:
		push_error("[test_mapslot_status_flow] failed to instantiate helper")
		quit(1)
		return

	var ui := FakeUI.new()
	var tracker := FakeMilitaryTracker.new()
	var production := FakeProduction.new()
	var stripe_updates := FakeCounter.new()
	var unit_label_updates := FakeCounter.new()

	helper.update_unit_label(ui, tracker, "barracks")
	if ui.unit_updates.is_empty() or ui.unit_updates[-1].distance_to(Vector2(3, 7)) > 0.01:
		push_error("[test_mapslot_status_flow] unit label must show tracker info")
		quit(1)
		return

	tracker.info = {"show": false}
	helper.update_unit_label(ui, tracker, "barracks")
	if ui.hide_unit_calls <= 0:
		push_error("[test_mapslot_status_flow] unit label must hide when tracker says so")
		quit(1)
		return

	helper.update_durability_display(ui, production)
	if ui.durability_updates.is_empty() or ui.durability_updates[-1] != 5:
		push_error("[test_mapslot_status_flow] durability display must reflect production durability")
		quit(1)
		return

	helper.on_building_upgrades_changed("farm", "farm", Callable(stripe_updates, "bump"))
	if stripe_updates.count != 1:
		push_error("[test_mapslot_status_flow] stripe update must trigger for current building")
		quit(1)
		return

	helper.on_hero_produced(Callable(unit_label_updates, "bump"))
	if unit_label_updates.count != 1:
		push_error("[test_mapslot_status_flow] hero produced must refresh labels")
		quit(1)
		return

	print("[test_mapslot_status_flow] PASS")
	quit(0)
