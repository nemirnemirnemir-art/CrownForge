extends RefCounted
class_name MapSlotInteractionController


func handle_click_tool(slot, menu: Node = null, building_registry = null, town_core = null) -> void:
    if menu and menu.has_method("get_active_tool"):
        var tool = menu.get_active_tool()
        if tool == "destroy" and String(slot.current_building_id) != "":
            execute_destroy(slot, menu, building_registry, town_core)
            return
        if tool == "sell" and String(slot.current_building_id) != "":
            menu.cancel_tool()
            _mark_input_handled(slot)
            return

    if String(slot.current_building_id) == "basic_construction":
        slot._toggle_basic_construction_ui()
    elif slot._is_research_selector_building():
        slot._toggle_research_table_ui()
    else:
        slot.slot_clicked.emit(int(slot.slot_index))


func execute_destroy(slot, menu: Node, building_registry = null, town_core = null) -> void:
    var removed_building_id: String = String(slot.current_building_id)
    var removed_config = null
    if building_registry and building_registry.has_method("get_building"):
        removed_config = building_registry.get_building(removed_building_id)

    slot.set_building("")
    if town_core and town_core.has_method("remove_building"):
        town_core.remove_building(int(slot.slot_index))

    var should_return_recipe := false
    if removed_config:
        var building_type: int = _get_building_type(removed_config)
        if building_type != int(BuildingConfig.BuildingType.RESOURCE):
            should_return_recipe = true
        elif removed_building_id == "well":
            should_return_recipe = true

    if building_registry and should_return_recipe and building_registry.has_method("add_recipe"):
        building_registry.add_recipe(removed_building_id, 1)

    if menu and menu.has_method("_update_affordability"):
        menu._update_affordability()
    if menu and menu.has_method("cancel_tool"):
        menu.cancel_tool()
    _mark_input_handled(slot)


func _mark_input_handled(slot) -> void:
    if "_viewport" in slot:
        var fallback_viewport = slot._viewport
        if fallback_viewport and fallback_viewport.has_method("set_input_as_handled"):
            fallback_viewport.set_input_as_handled()
            return
    if slot.has_method("get_viewport"):
        var viewport = slot.get_viewport()
        if viewport and viewport.has_method("set_input_as_handled"):
            viewport.set_input_as_handled()
            return


func _get_building_type(config) -> int:
    if config == null:
        return -1
    if config is BuildingConfig:
        return int((config as BuildingConfig).building_type)
    if config is Dictionary:
        return int((config as Dictionary).get("building_type", -1))
    var value: Variant = config.get("building_type") if config.has_method("get") else null
    return int(value) if value != null else -1
