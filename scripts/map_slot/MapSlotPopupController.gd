extends RefCounted
class_name MapSlotPopupController

const SPECIAL_POPUP_GROUP := "map_slot_special_popup"
const VZOR_GROUP := "vzor_zone"


func cancel_all_vzor_drag(reference_popup: Control = null) -> void:
	_cancel_all_vzor_drag(reference_popup)


func close_popup(popup: Control) -> void:
	_set_popup_visible(popup, false)


func close_other_special_popups(except_popup: Control = null) -> void:
	var tree := except_popup.get_tree() if except_popup else null
	if tree == null:
		return
	for node in tree.get_nodes_in_group(SPECIAL_POPUP_GROUP):
		if not (node is Control):
			continue
		var popup := node as Control
		if popup == except_popup:
			continue
		_set_popup_visible(popup, false)


func toggle_basic_construction_ui(
	basic_popup: Control,
	market_popup: Control,
	research_popup: Control,
	special_handler: RefCounted,
	slot_global_position: Vector2,
	viewport_rect: Rect2,
	prefer_right: bool = true
) -> bool:
	if basic_popup == null or special_handler == null:
		return false
	var should_open := not basic_popup.visible
	if not special_handler.has_method("is_ready"):
		return false
	if not bool(special_handler.call("is_ready")):
		close_popup(basic_popup)
		return false
	_enable_overlay_mode(basic_popup)
	if should_open:
		_cancel_all_vzor_drag(basic_popup)
		close_other_special_popups(basic_popup)
	_hide_other_popups(market_popup, research_popup)
	position_popup_near_slot(basic_popup, slot_global_position, viewport_rect, prefer_right)
	if basic_popup.has_method("setup"):
		basic_popup.call("setup", bool(special_handler.call("is_ready")))
	_set_popup_visible(basic_popup, should_open)
	return basic_popup.visible


func toggle_research_table_ui(
	research_popup: Control,
	market_popup: Control,
	basic_popup: Control,
	special_handler: RefCounted,
	current_building_id: String,
	slot_global_position: Vector2,
	viewport_rect: Rect2,
	prefer_right: bool = true
) -> bool:
	if research_popup == null or special_handler == null:
		return false
	var should_open := not research_popup.visible
	if not special_handler.has_method("get_mode"):
		return false
	_enable_overlay_mode(research_popup)
	if should_open:
		_cancel_all_vzor_drag(research_popup)
		close_other_special_popups(research_popup)
	_hide_other_popups(market_popup, basic_popup)
	position_popup_near_slot(research_popup, slot_global_position, viewport_rect, prefer_right)
	if research_popup.has_method("set_title"):
		research_popup.call("set_title", "Research Laboratory" if current_building_id == "research_laboratory" else "Research")
	if research_popup.has_method("setup_options") and special_handler.has_method("get_ui_options"):
		research_popup.call("setup_options", special_handler.call("get_ui_options"), int(special_handler.call("get_mode")))
	elif research_popup.has_method("setup"):
		research_popup.call("setup", int(special_handler.call("get_mode")))
	_set_popup_visible(research_popup, should_open)
	return research_popup.visible


func position_popup_near_slot(popup: Control, slot_global_position: Vector2, viewport_rect: Rect2, prefer_right: bool = true) -> void:
	if popup == null:
		return
	_enable_overlay_mode(popup)
	var popup_size := popup.get_combined_minimum_size()
	if popup_size == Vector2.ZERO:
		popup_size = popup.custom_minimum_size
	if popup_size == Vector2.ZERO:
		popup_size = Vector2(320.0, 140.0)
	var margin := 12.0
	var up_offset := -118.0
	var local_x := 42.0 if prefer_right else -popup_size.x - margin
	var desired_global_x := slot_global_position.x + local_x
	if desired_global_x < margin:
		local_x = 42.0
	elif viewport_rect.size.x > 0.0 and desired_global_x + popup_size.x > viewport_rect.size.x - margin:
		local_x = -popup_size.x - margin
	var desired_global_position := Vector2(slot_global_position.x + local_x, slot_global_position.y + up_offset)
	if viewport_rect.size.y > 0.0:
		if desired_global_position.y < margin:
			desired_global_position.y = margin
	if popup.top_level:
		popup.global_position = desired_global_position
	else:
		popup.position = desired_global_position - slot_global_position


func _hide_other_popups(first_popup: Control, second_popup: Control) -> void:
	if first_popup:
		first_popup.visible = false
	if second_popup:
		second_popup.visible = false


func _enable_overlay_mode(popup: Control) -> void:
	if popup == null:
		return
	popup.top_level = true
	popup.z_as_relative = false
	popup.z_index = max(popup.z_index, 3000)
	if popup.has_method("enable_overlay_mode"):
		popup.call("enable_overlay_mode")


func _set_popup_visible(popup: Control, visible: bool) -> void:
	if popup == null:
		return
	popup.visible = visible
	_notify_slot_owner(popup)


func _notify_slot_owner(popup: Control) -> void:
	if popup == null or not popup.has_meta("slot_owner"):
		return
	var slot_owner = popup.get_meta("slot_owner", null)
	if slot_owner != null and is_instance_valid(slot_owner) and slot_owner.has_method("_refresh_special_ui_visibility"):
		slot_owner.call("_refresh_special_ui_visibility")


func _cancel_all_vzor_drag(reference_popup: Control) -> void:
	var tree := reference_popup.get_tree() if reference_popup else null
	if tree == null:
		return
	for node in tree.get_nodes_in_group(VZOR_GROUP):
		if node != null and is_instance_valid(node) and node.has_method("cancel_drag"):
			node.call("cancel_drag")
