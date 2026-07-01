extends RefCounted
class_name BuildingMenuDetails

const TOOLTIP_VIEWPORT_MARGIN := 8.0

func get_displayed_building_id(menu: BuildingMenu) -> String:
	return menu._hovered_id

func refresh_details_panel(menu: BuildingMenu) -> void:
	if menu.details_panel == null:
		return
	var displayed_id := get_displayed_building_id(menu)
	if displayed_id == "":
		hide_details_panel(menu)
		return
	show_details_for_building(menu, displayed_id)

func show_details_for_building(menu: BuildingMenu, building_id: String) -> void:
	if menu.details_panel == null:
		return
	if menu.details_panel is CanvasItem:
		(menu.details_panel as CanvasItem).top_level = true
		(menu.details_panel as CanvasItem).z_index = 1100
	menu.details_panel.show()
	if menu.details_panel.has_method("show_building"):
		menu.details_panel.call("show_building", building_id)
	elif menu.details_panel.has_method("setup"):
		menu.details_panel.call("setup", building_id)
	position_details_panel(menu)
	menu.call_deferred("_position_details_panel")

func position_details_panel(menu: BuildingMenu) -> void:
	if menu.details_panel == null or menu.container == null:
		return
	if menu.details_panel is CanvasItem:
		(menu.details_panel as CanvasItem).top_level = true
		(menu.details_panel as CanvasItem).z_index = 1100
	var target_pos := menu.details_panel_custom_global_position
	if not menu.details_panel_use_custom_position:
		target_pos = menu.container.global_position + Vector2(menu.container.size.x, 0.0) + menu.details_panel_offset
	menu.details_panel.global_position = _clamp_to_viewport(menu, target_pos)

func _clamp_to_viewport(menu: BuildingMenu, target_pos: Vector2) -> Vector2:
	var viewport := menu.get_viewport()
	if viewport == null:
		return target_pos
	var visible_rect := viewport.get_visible_rect()
	var panel_size := menu.details_panel.size
	if panel_size == Vector2.ZERO:
		panel_size = menu.details_panel.get_combined_minimum_size()
	var max_x := maxf(visible_rect.position.x + TOOLTIP_VIEWPORT_MARGIN, visible_rect.end.x - panel_size.x - TOOLTIP_VIEWPORT_MARGIN)
	var max_y := maxf(visible_rect.position.y + TOOLTIP_VIEWPORT_MARGIN, visible_rect.end.y - panel_size.y - TOOLTIP_VIEWPORT_MARGIN)
	return Vector2(
		clampf(target_pos.x, visible_rect.position.x + TOOLTIP_VIEWPORT_MARGIN, max_x),
		clampf(target_pos.y, visible_rect.position.y + TOOLTIP_VIEWPORT_MARGIN, max_y)
	)

func hide_details_panel(menu: BuildingMenu) -> void:
	if menu.details_panel:
		menu.details_panel.hide()
