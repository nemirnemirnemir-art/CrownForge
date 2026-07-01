extends SceneTree

const MapSlotInteractionControllerScript := preload("res://scripts/map_slot/MapSlotInteractionController.gd")


class FakeMenu:
	extends Node

	var active_tool: String = ""
	var cancelled: bool = false
	var affordability_updates: int = 0

	func get_active_tool() -> String:
		return active_tool

	func cancel_tool() -> void:
		cancelled = true

	func _update_affordability() -> void:
		affordability_updates += 1


class FakeViewport:
	extends RefCounted

	var handled_calls: int = 0

	func set_input_as_handled() -> void:
		handled_calls += 1


class FakeBuildingRegistry:
	extends RefCounted

	var returned_recipes: Array[String] = []
	var config = null

	func get_building(_building_id: String):
		return config

	func add_recipe(building_id: String, _amount: int) -> void:
		returned_recipes.append(building_id)


class FakeBuildingConfig:
	extends Resource

	var building_type: int = BuildingConfig.BuildingType.RESOURCE


class FakeTownCore:
	extends RefCounted

	var removed_slots: Array[int] = []

	func remove_building(slot_index: int) -> void:
		removed_slots.append(slot_index)


class FakeSlot:
	extends Node

	signal slot_clicked(slot_index: int)

	var slot_index: int = 4
	var current_building_id: String = ""
	var basic_toggle_calls: int = 0
	var research_toggle_calls: int = 0
	var destroy_calls: int = 0
	var cleared_buildings: Array[String] = []
	var _viewport := FakeViewport.new()

	func _toggle_basic_construction_ui() -> void:
		basic_toggle_calls += 1

	func _toggle_research_table_ui() -> void:
		research_toggle_calls += 1

	func set_building(building_id: String) -> void:
		cleared_buildings.append(building_id)
		current_building_id = building_id

	func _is_research_selector_building() -> bool:
		return current_building_id == "research_table" or current_building_id == "research_laboratory"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var helper = MapSlotInteractionControllerScript.new()
	if helper == null:
		push_error("[test_mapslot_interaction_controller] failed to instantiate helper")
		quit(1)
		return

	var slot := FakeSlot.new()
	get_root().add_child(slot)

	var clicked_events: Array[int] = []
	slot.slot_clicked.connect(func(index: int) -> void: clicked_events.append(index))

	var menu := FakeMenu.new()
	slot.current_building_id = "farm"
	helper.handle_click_tool(slot, menu)
	if clicked_events.size() != 1:
		push_error("[test_mapslot_interaction_controller] default click must emit slot_clicked")
		quit(1)
		return

	slot.current_building_id = "basic_construction"
	helper.handle_click_tool(slot, menu)
	if slot.basic_toggle_calls != 1:
		push_error("[test_mapslot_interaction_controller] basic construction click must open basic popup")
		quit(1)
		return

	slot.current_building_id = "research_table"
	helper.handle_click_tool(slot, menu)
	if slot.research_toggle_calls != 1:
		push_error("[test_mapslot_interaction_controller] research building click must open research popup")
		quit(1)
		return

	var registry := FakeBuildingRegistry.new()
	var resource_config := FakeBuildingConfig.new()
	resource_config.building_type = BuildingConfig.BuildingType.RESOURCE
	registry.config = resource_config
	var town_core := FakeTownCore.new()
	menu.active_tool = "destroy"
	slot.current_building_id = "well"
	helper.handle_click_tool(slot, menu, registry, town_core)
	if town_core.removed_slots != [4]:
		push_error("[test_mapslot_interaction_controller] destroy tool must remove building from town core")
		quit(1)
		return
	if registry.returned_recipes != ["well"]:
		push_error("[test_mapslot_interaction_controller] destroy tool must return recipe for well")
		quit(1)
		return
	if menu.affordability_updates != 1 or not menu.cancelled:
		push_error("[test_mapslot_interaction_controller] destroy tool must refresh menu and cancel tool")
		quit(1)
		return
	if slot.cleared_buildings.is_empty() or slot.cleared_buildings[-1] != "":
		push_error("[test_mapslot_interaction_controller] destroy tool must clear slot building")
		quit(1)
		return
	if slot._viewport.handled_calls <= 0:
		push_error("[test_mapslot_interaction_controller] destroy tool must mark input handled")
		quit(1)
		return

	menu.cancelled = false
	menu.affordability_updates = 0
	registry.returned_recipes.clear()
	town_core.removed_slots.clear()
	var military_config := FakeBuildingConfig.new()
	military_config.building_type = BuildingConfig.BuildingType.MILITARY
	registry.config = military_config
	slot.current_building_id = "barracks"
	helper.handle_click_tool(slot, menu, registry, town_core)
	if town_core.removed_slots != [4]:
		push_error("[test_mapslot_interaction_controller] destroy with BuildingConfig resource must still remove building")
		quit(1)
		return
	if registry.returned_recipes != ["barracks"]:
		push_error("[test_mapslot_interaction_controller] non-resource BuildingConfig destroy must return recipe")
		quit(1)
		return

	print("[test_mapslot_interaction_controller] PASS")
	quit(0)
