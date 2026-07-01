extends SceneTree

const VzorZoneScene := preload("res://scenes/ui/gaze/VzorZone.tscn")


class FakeMapLayout:
	extends Node2D

	var slots: Array = []


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	push_error("[test_vzorzone_pause_cancel] %s" % message)
	quit(1)


func _run_test() -> void:
	var map_layout := FakeMapLayout.new()
	get_root().add_child(map_layout)

	var vzor := VzorZoneScene.instantiate()
	map_layout.add_child(vzor)
	await process_frame
	await process_frame

	var controller = vzor.get("_drag_controller")
	if controller == null:
		_fail("vzor scene must initialize drag controller")
		return
	controller.set("_dragging", true)
	paused = true
	vzor._process(0.016)
	paused = false

	if bool(controller.get("_dragging")):
		_fail("paused game must cancel active vzor drag")
		return

	var tick_manager := get_root().get_node_or_null("TickManager")
	if tick_manager == null:
		_fail("TickManager autoload must exist")
		return
	controller.set("_dragging", true)
	tick_manager.pause()
	vzor._process(0.016)
	tick_manager.set_speed(1.0)
	if bool(controller.get("_dragging")):
		_fail("tick-manager pause must cancel active vzor drag when settings menu pauses via speed scale")
		return

	print("[test_vzorzone_pause_cancel] PASS")
	quit(0)
