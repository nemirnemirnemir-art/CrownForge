extends SceneTree

const BUILDING_MENU_SCENE_PATH := "res://scenes/ui/building/BuildingMenu.tscn"
const EXPECTED_DETAILS_PANEL_PATH := "Content/DetailsPanel"
const EXPECTED_DETAILS_PANEL_SCRIPT_PATH := "res://scripts/ui/town/BuildingsTooltip.gd"
const TARGET_BUILDING_ID := "market"

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_menu_details_panel_runtime] %s" % message)
	quit(1)

func _init() -> void:
	var scene := load(BUILDING_MENU_SCENE_PATH) as PackedScene
	if scene == null:
		_fail("Missing BuildingMenu scene: %s" % BUILDING_MENU_SCENE_PATH)
		return

	var menu := scene.instantiate()
	if menu == null:
		_fail("Unable to instantiate BuildingMenu")
		return

	root.add_child(menu)
	await process_frame

	var details_panel := menu.get_node_or_null(EXPECTED_DETAILS_PANEL_PATH)
	if details_panel == null:
		_fail("BuildingMenu is missing DetailsPanel node at %s" % EXPECTED_DETAILS_PANEL_PATH)
		return

	var details_script := details_panel.get_script() as Script
	if details_script == null:
		_fail("DetailsPanel has no script")
		return
	if String(details_script.resource_path) != EXPECTED_DETAILS_PANEL_SCRIPT_PATH:
		_fail("DetailsPanel script mismatch: expected %s, got %s" % [EXPECTED_DETAILS_PANEL_SCRIPT_PATH, String(details_script.resource_path)])
		return
	if not details_panel.has_method("show_building"):
		_fail("DetailsPanel does not support show_building()")
		return

	details_panel.call("show_building", TARGET_BUILDING_ID)
	await process_frame

	var description_label := details_panel.get_node_or_null("Margin/VBox/DescriptionText") as Label
	if description_label == null:
		_fail("DetailsPanel is missing DescriptionText label")
		return
	if String(description_label.text).strip_edges() == "":
		_fail("DetailsPanel description is empty for %s" % TARGET_BUILDING_ID)
		return

	if not bool(details_panel.get("show_extras")):
		_fail("DetailsPanel must keep tooltip extras enabled for %s" % TARGET_BUILDING_ID)
		return

	var upgrade_popups: Array = details_panel.get("_upgrade_popups")
	if upgrade_popups.is_empty():
		_fail("DetailsPanel did not build old-style upgrade popups for %s" % TARGET_BUILDING_ID)
		return

	print("[test_building_menu_details_panel_runtime] PASS")
	quit(0)
