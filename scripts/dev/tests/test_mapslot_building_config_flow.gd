extends SceneTree

const MapSlotBuildingConfigFlowScript := preload("res://scripts/map_slot/MapSlotBuildingConfigFlow.gd")


func _artifact_core() -> Node:
	return get_root().get_node_or_null("ArtifactCore")


class FakeProduction:
	extends RefCounted

	var init_calls: Array[Dictionary] = []
	var reset_calls: int = 0
	var durability: int = 0

	func initialize(cycle_time: float, next_durability: int, slot_index: int, building_id: String) -> void:
		init_calls.append({"cycle_time": cycle_time, "durability": next_durability, "slot_index": slot_index, "building_id": building_id})

	func reset() -> void:
		reset_calls += 1

	func get_durability() -> int:
		return durability


class FakeMarket:
	extends RefCounted

	var reset_calls: int = 0

	func reset() -> void:
		reset_calls += 1


class FakeMilitaryTracker:
	extends RefCounted

	var removed: Array[String] = []

	func on_military_building_removed(building_id: String, _slot_index: int) -> void:
		removed.append(building_id)


class FakeTownCore:
	extends RefCounted

	var cleared: Array[String] = []

	func clear_building_slot_state(building_id: String, _slot_index: int, _request_save: bool) -> void:
		cleared.append(building_id)


class FakeSealLogic:
	extends RefCounted

	var calls: int = 0

	func _update_seal_modifier() -> void:
		calls += 1


class FakeSlot:
	extends Node

	var _special_handler = null
	var _military_tracker := FakeMilitaryTracker.new()
	var _production := FakeProduction.new()
	var _market := FakeMarket.new()
	var _seal_logic := FakeSealLogic.new()
	var sprite := Sprite2D.new()
	var anim_vzor := AnimatedSprite2D.new()
	var _basic_construction_ui := Control.new()
	var _basic_action_btn := Button.new()
	var _research_table_ui := Control.new()
	var slot_index: int = 3
	var _mine_anim_time: float = 0.0
	var _base_sprite_position := Vector2.ZERO
	var _base_sprite_rotation: float = 0.0
	var _base_sprite_scale := Vector2.ONE
	var _default_sprite_position := Vector2.ZERO
	var _default_sprite_rotation: float = 0.0
	var _default_sprite_scale := Vector2.ONE
	var current_building_id: String = ""
	var visuals_log: Array[String] = []

	func _update_research_table_visuals() -> void:
		visuals_log.append("research")

	func _update_basic_construction_visuals() -> void:
		visuals_log.append("basic")

	func _update_upgrade_stripe() -> void:
		visuals_log.append("stripe")

	func _apply_mine_visual_state() -> void:
		visuals_log.append("mine")

	func _reset_active_mine_transform() -> void:
		visuals_log.append("reset_mine")

	func _restore_special_runtime_state(_building_id: String) -> void:
		visuals_log.append("restore_runtime")


class FakeConfig:
	extends RefCounted

	var building_id: String = ""
	var display_name: String = ""
	var building_type: int = BuildingConfig.BuildingType.RESOURCE
	var has_special_behavior: bool = false
	var special_script_path: String = ""
	var use_vzor_animation: bool = false
	var vzor_frames = null
	var vzor_animation_name: String = ""
	var icon = null
	var cycle_time: float = 2.0
	var max_units: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotBuildingConfigFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_building_config_flow] failed to instantiate helper")
		quit(1)
		return

	var slot := FakeSlot.new()
	var town_core := FakeTownCore.new()
	var prev_cfg := FakeConfig.new()
	prev_cfg.building_id = "barracks"
	prev_cfg.building_type = BuildingConfig.BuildingType.MILITARY

	flow.clear_building(slot, "barracks", prev_cfg, town_core)
	if slot._production.reset_calls != 1 or slot._market.reset_calls != 1:
		push_error("[test_mapslot_building_config_flow] clear must reset production and market")
		quit(1)
		return
	if slot._military_tracker.removed != ["barracks"]:
		push_error("[test_mapslot_building_config_flow] clear must unregister previous military building")
		quit(1)
		return
	if town_core.cleared != ["barracks"]:
		push_error("[test_mapslot_building_config_flow] clear must clear persisted runtime state")
		quit(1)
		return

	var config := FakeConfig.new()
	config.building_id = "small_wheat_field"
	config.display_name = "Wheat"
	config.building_type = BuildingConfig.BuildingType.RESOURCE
	config.cycle_time = 4.0
	config.max_units = 3
	var artifact_core := _artifact_core()
	if artifact_core == null:
		push_error("[test_mapslot_building_config_flow] ArtifactCore autoload must exist")
		quit(1)
		return
	artifact_core.call("reset")
	artifact_core.call("add_artifact", "iron_hoe", true)
	flow.apply_building_config(slot, config, null)
	if slot._production.init_calls.is_empty():
		push_error("[test_mapslot_building_config_flow] apply must initialize production")
		quit(1)
		return
	if int(slot._production.init_calls[-1].get("durability", -1)) != 6:
		push_error("[test_mapslot_building_config_flow] iron_hoe must double starter resource durability")
		quit(1)
		return
	if slot._seal_logic.calls != 1:
		push_error("[test_mapslot_building_config_flow] apply must refresh seal modifier")
		quit(1)
		return

	slot.current_building_id = "small_wheat_field"
	slot._production.durability = 0
	flow.handle_resource_depletion(slot, config, func() -> void: slot.visuals_log.append("depleted"))
	if slot.visuals_log.find("depleted") == -1:
		push_error("[test_mapslot_building_config_flow] depleted resource building must request clear/build reset")
		quit(1)
		return

	print("[test_mapslot_building_config_flow] PASS")
	quit(0)
