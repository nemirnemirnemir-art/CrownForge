extends SceneTree

const MAP_SLOT_SCENE := preload("res://scenes/map/MapSlot.tscn")
const BUILDING_ICON_TILE_SCENE := preload("res://scenes/ui/town/BuildingIconTile.tscn")
const BASIC_CONSTRUCTION_UI_SCENE := preload("res://scenes/ui/town/BasicConstructionUI.tscn")

var _failed := false

func _upgrade_core() -> Node:
	return get_root().get_node_or_null("BuildingUpgradeCore")

func _building_registry() -> Node:
	return get_root().get_node_or_null("BuildingRegistry")

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_stripes_runtime] %s" % message)
	quit(1)

func _assert_stripe(control: Node, expected_suffix: String, context: String) -> bool:
	var stripe := control.get_node_or_null("UpgradeStripe") as TextureRect
	if stripe == null:
		_fail("%s must have UpgradeStripe node" % context)
		return false
	if not stripe.visible:
		_fail("%s must show UpgradeStripe when upgrade level > 0" % context)
		return false
	if stripe.texture == null:
		_fail("%s stripe must have texture" % context)
		return false
	if not String(stripe.texture.resource_path).ends_with(expected_suffix):
		_fail("%s stripe must use %s" % [context, expected_suffix])
		return false
	return true

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var upgrade_core := _upgrade_core()
	var building_registry := _building_registry()
	if upgrade_core == null or building_registry == null:
		_fail("Required autoloads are missing")
		return

	upgrade_core.call("load_save_data", {"upgrades_by_slot": {}})
	upgrade_core.call("unlock_building_upgrade", "concert", "concert:0")
	upgrade_core.call("unlock_building_upgrade", "concert", "concert:1")
	upgrade_core.call("unlock_building_upgrade", "clay_mine", "clay_mine:0")

	var map_slot := MAP_SLOT_SCENE.instantiate() as Node2D
	if map_slot == null:
		_fail("Failed to instantiate MapSlot")
		return
	get_root().add_child(map_slot)
	map_slot.set("slot_index", 99)
	map_slot.call("set_building", "concert")
	await process_frame
	if not _assert_stripe(map_slot, "stripe2.png", "MapSlot"):
		return

	var tile := BUILDING_ICON_TILE_SCENE.instantiate() as Control
	if tile == null:
		_fail("Failed to instantiate BuildingIconTile")
		return
	get_root().add_child(tile)
	tile.call("setup", "concert", building_registry.call("get_building", "concert"))
	await process_frame
	if not _assert_stripe(tile, "stripe2.png", "BuildingIconTile"):
		return

	var basic_ui := BASIC_CONSTRUCTION_UI_SCENE.instantiate() as Control
	if basic_ui == null:
		_fail("Failed to instantiate BasicConstructionUI")
		return
	get_root().add_child(basic_ui)
	await process_frame

	var found_clay := false
	for child in basic_ui.get_node("Panel/Margin/VBox/OptionsRow").get_children():
		var button := child as Button
		if button == null:
			continue
		if String(button.get_meta("building_id", "")) != "clay_mine":
			continue
		found_clay = true
		if not _assert_stripe(button, "stripe.png", "BasicConstructionUI clay_mine button"):
			return
		break
	if not found_clay:
		_fail("BasicConstructionUI must include clay_mine option")
		return

	print("[test_building_upgrade_stripes_runtime] PASS")
	quit(0)
