extends SceneTree

const BuildingMenuScene := preload("res://scenes/ui/building/BuildingMenu.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var menu := BuildingMenuScene.instantiate() as Control
	if menu == null:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] failed to instantiate BuildingMenu")
		quit(1)
		return

	get_root().add_child(menu)
	await process_frame

	var details_panel := menu.get_node_or_null("Content/DetailsPanel") as Control
	if details_panel == null:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] DetailsPanel missing")
		quit(1)
		return

	if details_panel.visible:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] BuildingMenu details must stay hidden until hover")
		quit(1)
		return

	menu.call("_select_building", "house", false)
	await process_frame

	if details_panel.visible:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] BuildingMenu selection must not force details visible")
		quit(1)
		return

	menu.call("_on_tile_hover_started", "house")
	await process_frame

	if not details_panel.visible:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] BuildingMenu details must appear on hover")
		quit(1)
		return

	menu.call("_on_tile_hover_started", "farm")
	menu.call("_on_tile_hover_ended", "house")
	await process_frame

	if not details_panel.visible:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] Details must stay visible when leaving an older tile while another tile is hovered")
		quit(1)
		return

	menu.call("_on_tile_hover_ended", "farm")
	await process_frame

	if details_panel.visible:
		push_error("[test_building_menu_hover_does_not_show_tooltip_immediately] BuildingMenu details must hide after hover ends")
		quit(1)
		return

	print("[test_building_menu_hover_does_not_show_tooltip_immediately] PASS")
	quit(0)
