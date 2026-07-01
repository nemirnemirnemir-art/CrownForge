extends SceneTree

const MapSlotScene := preload("res://scenes/map/MapSlot.tscn")

var _failed := false

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_mapslot_preserves_external_gaze_on_build] %s" % message)
	quit(1)

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var slot := MapSlotScene.instantiate()
	if slot == null:
		_fail("MapSlot scene must instantiate")
		return
	get_root().add_child(slot)
	slot.set("slot_index", 9)
	await process_frame

	if not slot.has_method("set_external_vzor_active"):
		_fail("MapSlot must support external gaze")
		return
	slot.call("set_external_vzor_active", "monument_to_kings_gaze:13", true)
	await process_frame

	if not slot.has_method("is_external_vzor_active") or not bool(slot.call("is_external_vzor_active")):
		_fail("External gaze must become active before building placement")
		return

	if not slot.has_method("set_building"):
		_fail("MapSlot must support set_building")
		return
	slot.call("set_building", "small_wheat_field")
	await process_frame

	if not bool(slot.call("is_external_vzor_active")):
		_fail("MapSlot must preserve external gaze when a building is placed on an already-activated slot")
		return
	if not slot.has_method("is_effectively_vzor_active") or not bool(slot.call("is_effectively_vzor_active")):
		_fail("Placed building must remain effectively under gaze without reapplying king gaze")
		return

	print("[test_mapslot_preserves_external_gaze_on_build] PASS")
	quit(0)
