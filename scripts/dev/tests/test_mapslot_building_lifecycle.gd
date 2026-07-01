extends SceneTree

const MapSlotBuildingLifecycleScript := preload("res://scripts/map_slot/MapSlotBuildingLifecycle.gd")


class FakeUI:
	extends RefCounted

	var hide_progress_calls: int = 0
	var hide_unit_calls: int = 0
	var hide_durability_calls: int = 0
	var progress_updates: Array[Vector2] = []

	func hide_progress() -> void:
		hide_progress_calls += 1

	func hide_unit_count() -> void:
		hide_unit_calls += 1

	func hide_durability() -> void:
		hide_durability_calls += 1

	func update_progress(ratio: float, cycle_time: float) -> void:
		progress_updates.append(Vector2(ratio, cycle_time))


class FakeSprite:
	extends Node2D


class FakeBuildingRegistry:
	extends RefCounted

	var configs := {}

	func get_building(building_id: String):
		return configs.get(building_id, null)


class FakeSlot:
	extends Node

	var current_building_id: String = "old_building"
	var _king_vzor_active: bool = true
	var _vzor_active: bool = true
	var _external_vzor_sources: Dictionary = {"source": true}
	var _ui: FakeUI = FakeUI.new()
	var sprite: FakeSprite = FakeSprite.new()
	var _market_action_btn := Control.new()
	var _market_ui := Control.new()
	var _basic_construction_ui := Control.new()
	var _research_table_ui := Control.new()
	var _special_handler = null
	var _military_tracker = null
	var slot_index: int = 2
	var lifecycle_log: Array[String] = []

	func _init() -> void:
		_market_ui.visible = true
		_basic_construction_ui.visible = true
		_research_table_ui.visible = true

	func _clear_building(prev_building_id: String, _prev_cfg) -> void:
		lifecycle_log.append("clear:%s" % prev_building_id)

	func _setup_building(building_id: String, prev_building_id: String, _prev_cfg):
		lifecycle_log.append("setup:%s:%s" % [prev_building_id, building_id])
		return {"building_id": building_id}

	func _apply_building_config(config) -> void:
		lifecycle_log.append("apply:%s" % String(config.get("building_id", "")))

	func _refresh_vzor_state() -> void:
		lifecycle_log.append("refresh_vzor")

	func _update_market_visuals() -> void:
		lifecycle_log.append("update_market")

	func _update_research_table_visuals() -> void:
		lifecycle_log.append("update_research")

	func _update_basic_construction_visuals() -> void:
		lifecycle_log.append("update_basic")

	func _update_unit_label() -> void:
		lifecycle_log.append("update_units")

	func _update_durability_display() -> void:
		lifecycle_log.append("update_durability")

	func _update_upgrade_stripe() -> void:
		lifecycle_log.append("update_stripe")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = MapSlotBuildingLifecycleScript.new()
	if helper == null:
		push_error("[test_mapslot_building_lifecycle] failed to instantiate helper")
		quit(1)
		return

	var slot := FakeSlot.new()
	var registry := FakeBuildingRegistry.new()
	registry.configs["old_building"] = {"building_type": 0}

	helper.set_building(slot, "new_building", registry)

	if slot.current_building_id != "new_building":
		push_error("[test_mapslot_building_lifecycle] current_building_id was not updated")
		quit(1)
		return
	if not slot._king_vzor_active or slot._external_vzor_sources.is_empty():
		push_error("[test_mapslot_building_lifecycle] gaze state must be preserved across building change")
		quit(1)
		return
	if slot._market_ui.visible or slot._basic_construction_ui.visible or slot._research_table_ui.visible:
		push_error("[test_mapslot_building_lifecycle] building change must hide open slot popups")
		quit(1)
		return
	if slot.lifecycle_log.find("setup:old_building:new_building") == -1 or slot.lifecycle_log.find("apply:new_building") == -1:
		push_error("[test_mapslot_building_lifecycle] setup/apply flow did not run")
		quit(1)
		return

	helper.set_building(slot, "", registry)
	if slot.lifecycle_log.find("clear:new_building") == -1:
		push_error("[test_mapslot_building_lifecycle] clear flow did not run for empty building")
		quit(1)
		return

	print("[test_mapslot_building_lifecycle] PASS")
	quit(0)
