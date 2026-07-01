extends SceneTree

const BUILDING_MENU_SCENE_PATH := "res://scenes/ui/building/BuildingMenu.tscn"
const TARGET_BUILDING_ID := "peasants_hut"
const VIEWPORT_MARGIN := 24.0
const PANEL_GAP_TOLERANCE := 2.0

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_menu_tooltip_layout_runtime] %s" % message)
	quit(1)

func _init() -> void:
	var scene := load(BUILDING_MENU_SCENE_PATH) as PackedScene
	if scene == null:
		_fail("Missing BuildingMenu scene: %s" % BUILDING_MENU_SCENE_PATH)
		return

	var menu := scene.instantiate() as Control
	if menu == null:
		_fail("Unable to instantiate BuildingMenu")
		return

	root.add_child(menu)
	await process_frame
	await process_frame

	menu.call("_on_tile_hover_started", TARGET_BUILDING_ID)
	await process_frame
	await process_frame

	var details_panel := menu.get_node_or_null("Content/DetailsPanel") as Control
	if details_panel == null:
		_fail("BuildingMenu is missing Content/DetailsPanel")
		return
	if not details_panel.visible:
		_fail("DetailsPanel must be visible on hover")
		return

	if details_panel.global_position.x < 0.0 or details_panel.global_position.y < 0.0:
		_fail("DetailsPanel must stay on-screen, got %s" % str(details_panel.global_position))
		return

	var container := menu.get_node_or_null("Content/GridContainer") as Control
	if container == null:
		_fail("BuildingMenu is missing Content/GridContainer")
		return
	if details_panel.global_position.x < container.global_position.x + container.size.x - VIEWPORT_MARGIN:
		_fail("DetailsPanel must open beside the building menu, got %s for container end %.2f" % [str(details_panel.global_position), container.global_position.x + container.size.x])
		return

	var unit_panel := details_panel.get("_unit_panel_popup") as Control
	if unit_panel == null:
		_fail("Military building hover must create unit info popup")
		return

	await process_frame

	var details_rect := Rect2(details_panel.global_position, details_panel.size)
	var unit_rect := Rect2(unit_panel.global_position, unit_panel.size)
	if details_rect.intersects(unit_rect):
		_fail("Unit info popup overlaps main details panel")
		return
	if unit_rect.position.x < details_rect.end.x - PANEL_GAP_TOLERANCE:
		_fail("Unit info popup must be placed to the right of details panel")
		return

	print("[test_building_menu_tooltip_layout_runtime] PASS")
	quit(0)
