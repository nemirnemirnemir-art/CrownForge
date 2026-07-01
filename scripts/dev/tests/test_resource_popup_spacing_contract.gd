extends SceneTree

const MAP_SLOT_PATH := "res://scripts/map/MapSlot.gd"
const FAIRY_FOUNTAIN_PATH := "res://core/buildings/special/FairyFountain.gd"
const ANIMATIONS_PATH := "res://scripts/map_slot/MapSlotAnimations.gd"

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_resource_popup_spacing_contract] %s" % message)
	quit(1)

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing file: %s" % path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open file: %s" % path)
		return ""
	return file.get_as_text()

func _init() -> void:
	var map_slot_text := _read_text(MAP_SLOT_PATH)
	if map_slot_text.find("PRODUCTION_POPUP_SPACING") == -1:
		_fail("MapSlot must define a named popup spacing constant for multi-output resources")
		return
	if map_slot_text.find("PRODUCTION_POPUP_VERTICAL_STEP") == -1:
		_fail("MapSlot must define a vertical popup staggering constant for multi-output resources")
		return

	var fairy_text := _read_text(FAIRY_FOUNTAIN_PATH)
	if fairy_text.find("POPUP_SPACING") == -1:
		_fail("FairyFountain must define popup spacing for 5-resource bursts")
		return

	var animations_text := _read_text(ANIMATIONS_PATH)
	if animations_text.find("container.get_combined_minimum_size()") == -1:
		_fail("MapSlotAnimations must size popup containers from their content before centering")
		return
	if animations_text.find("-container_size.x * 0.5") == -1:
		_fail("MapSlotAnimations must center popups horizontally using measured width")
		return

	print("[test_resource_popup_spacing_contract] PASS")
	quit(0)
