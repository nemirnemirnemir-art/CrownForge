extends SceneTree

const SlotQueryScript := preload("res://core/building_upgrade/BuildingUpgradeSlotQuery.gd")


class FakeSlot:
	extends Node

	var slot_index: int = -1
	var current_building_id: String = ""
	var vzor: bool = false
	var handler = null

	func is_effectively_vzor_active() -> bool:
		return vzor

	func get_special_handler():
		return handler


class FakeHandler:
	extends RefCounted

	func get_morale_bonus() -> int:
		return 7


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var q = SlotQueryScript.new()
	if q == null:
		push_error("[test_building_upgrade_slot_query] failed to instantiate helper")
		quit(1)
		return

	var slot_a := FakeSlot.new()
	slot_a.slot_index = 1
	slot_a.current_building_id = "concert"
	slot_a.vzor = true
	var slot_b := FakeSlot.new()
	slot_b.slot_index = 2
	slot_b.current_building_id = "hospital"
	slot_b.handler = FakeHandler.new()
	var slots := [slot_a, slot_b]

	if q.count_built_buildings(slots, "concert") != 1:
		push_error("[test_building_upgrade_slot_query] count_built_buildings mismatch")
		quit(1)
		return
	if q.count_active_buildings(slots, "concert") != 1:
		push_error("[test_building_upgrade_slot_query] count_active_buildings mismatch")
		quit(1)
		return
	if q.get_slot_building_id(slots, 1) != "concert":
		push_error("[test_building_upgrade_slot_query] slot building lookup mismatch")
		quit(1)
		return
	if q.get_active_hospital_morale_bonus(slots) != 7:
		push_error("[test_building_upgrade_slot_query] hospital morale aggregation mismatch")
		quit(1)
		return

	print("[test_building_upgrade_slot_query] PASS")
	quit(0)
