extends RefCounted
class_name MapSlotBuildingLifecycle


func set_building(slot: Node, building_id: String, building_registry, options: Dictionary = {}) -> void:
    var prev_building_id: String = String(slot.current_building_id)
    var prev_cfg = null
    var preserved_king_vzor_active: bool = _get_preserved_king_vzor_active(slot)
    var preserved_external_vzor_sources: Dictionary = _get_preserved_external_vzor_sources(slot)
    if prev_building_id != "" and building_registry != null and building_registry.has_method("get_building"):
        prev_cfg = building_registry.get_building(prev_building_id)

    slot.current_building_id = building_id
    _reset_vzor_state(slot)

    if slot._ui:
        slot._ui.hide_progress()
        slot._ui.hide_unit_count()
        slot._ui.hide_durability()
        slot._ui.update_progress(0.0, 0.0)

    var placeholder_label := slot.sprite.get_node_or_null("PlaceholderLabel") as Label
    if placeholder_label:
        placeholder_label.queue_free()

    var config = null
    if building_id == "":
        _clear_building_with_options(slot, prev_building_id, prev_cfg, options)
    else:
        config = slot._setup_building(building_id, prev_building_id, prev_cfg)
        if config == null:
            slot.current_building_id = ""
            _clear_building_with_options(slot, prev_building_id, prev_cfg, options)

    if config:
        slot._apply_building_config(config)

    _restore_vzor_state(slot, preserved_king_vzor_active, preserved_external_vzor_sources)

    if slot._market_action_btn:
        slot._update_market_visuals()
    if slot._market_ui:
        slot._market_ui.visible = false
    if slot._basic_construction_ui:
        slot._basic_construction_ui.visible = false
    if slot._research_table_ui:
        slot._research_table_ui.visible = false
    if slot.has_method("_refresh_special_ui_visibility"):
        slot._refresh_special_ui_visibility()
    else:
        slot._update_research_table_visuals()
        slot._update_basic_construction_visuals()
    if slot.current_building_id == "basic_construction" and slot._basic_construction_ui and slot._basic_construction_ui.has_method("setup") and slot._special_handler and slot._special_handler.has_method("is_ready"):
        slot._basic_construction_ui.call("setup", bool(slot._special_handler.call("is_ready")))

    slot._update_unit_label()
    slot._update_durability_display()
    slot._update_upgrade_stripe()
    if slot._military_tracker and slot._military_tracker.has_method("refresh_military_unit_labels_across_map"):
        slot._military_tracker.refresh_military_unit_labels_across_map(slot, Callable(slot, "_update_unit_label"))

    if slot.current_building_id == "" and slot._ui:
        slot._ui.hide_progress()
        slot._ui.hide_unit_count()
        slot._ui.hide_durability()


func _get_preserved_king_vzor_active(slot: Node) -> bool:
    if slot.has_method("is_king_vzor_active"):
        return bool(slot.call("is_king_vzor_active"))
    return bool(slot.get("_king_vzor_active"))


func _get_preserved_external_vzor_sources(slot: Node) -> Dictionary:
    if slot.has_method("get_external_vzor_sources"):
        var sources: Variant = slot.call("get_external_vzor_sources")
        if sources is Dictionary:
            return (sources as Dictionary).duplicate(true)
    var fallback: Variant = slot.get("_external_vzor_sources")
    if fallback is Dictionary:
        return (fallback as Dictionary).duplicate(true)
    return {}


func _reset_vzor_state(slot: Node) -> void:
    if slot.has_method("set_vzor_active"):
        slot.call("set_vzor_active", false)
    else:
        slot.set("_king_vzor_active", false)
        slot.set("_vzor_active", false)

    var existing_sources := _get_preserved_external_vzor_sources(slot)
    if slot.has_method("set_external_vzor_active"):
        for source_id in existing_sources.keys():
            slot.call("set_external_vzor_active", String(source_id), false)
    else:
        slot.set("_external_vzor_sources", {})


func _restore_vzor_state(slot: Node, king_vzor_active: bool, external_vzor_sources: Dictionary) -> void:
    if slot.has_method("set_vzor_active"):
        slot.call("set_vzor_active", king_vzor_active)
    else:
        slot.set("_king_vzor_active", king_vzor_active)

    if slot.has_method("set_external_vzor_active"):
        for source_id in external_vzor_sources.keys():
            slot.call("set_external_vzor_active", String(source_id), bool(external_vzor_sources[source_id]))
    else:
        slot.set("_external_vzor_sources", external_vzor_sources.duplicate(true))
        if slot.has_method("_refresh_vzor_state"):
            slot.call("_refresh_vzor_state")


func _clear_building_with_options(slot: Node, prev_building_id: String, prev_cfg, options: Dictionary) -> void:
    if options.is_empty():
        slot._clear_building(prev_building_id, prev_cfg)
        return
    slot._clear_building(prev_building_id, prev_cfg, options)
