extends SceneTree

const VzorZoneDragControllerScript := preload("res://scripts/ui/gaze/VzorZoneDragController.gd")


class TestDragController:
	extends "res://scripts/ui/gaze/VzorZoneDragController.gd"

	var force_mouse_over_ui: bool = false
	var forced_pointer_world_pos: Vector2 = Vector2.ZERO

	func _is_mouse_over_ui() -> bool:
		return force_mouse_over_ui

	func _get_pointer_world_pos() -> Vector2:
		return forced_pointer_world_pos


class FakeModel:
	extends RefCounted

	var cell_size: Vector2 = Vector2(80.0, 80.0)
	var visual_offset: Vector2 = Vector2.ZERO
	var apply_drop_calls: int = 0
	var start_drag_calls: int = 0
	var update_preview_calls: int = 0

	func start_drag() -> void:
		start_drag_calls += 1

	func apply_drop() -> void:
		apply_drop_calls += 1

	func get_target_position() -> Vector2:
		return Vector2.ZERO

	func get_offsets() -> Array[Vector2i]:
		return [Vector2i.ZERO]

	func compute_cell_from_top_left(_top_left: Vector2) -> Vector2i:
		return Vector2i(int(floor(_top_left.x / cell_size.x)), int(floor(_top_left.y / cell_size.y)))

	func can_place_at(_cell: Vector2i, _orientation: int) -> bool:
		return true

	func get_orientation() -> int:
		return 0

	func update_preview(_cell: Vector2i, _valid: bool) -> void:
		update_preview_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	push_error("[test_vzorzone_drag_controller] %s" % message)
	quit(1)


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var zone := Node2D.new()
	root.add_child(zone)

	var model := FakeModel.new()
	var controller := TestDragController.new()
	controller.setup(zone, model)
	controller.forced_pointer_world_pos = Vector2(10.0, 10.0)

	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	controller.handle_input(press_event)

	if not bool(controller.get("_dragging")):
		_fail("left mouse press on vzor must start drag before hover-block regression check")
		return
	if model.start_drag_calls != 1:
		_fail("starting drag must notify model exactly once")
		return

	controller.force_mouse_over_ui = true
	controller.forced_pointer_world_pos = Vector2(150.0, 20.0)
	var motion_event := InputEventMouseMotion.new()
	motion_event.position = controller.forced_pointer_world_pos
	controller.handle_input(motion_event)

	if model.update_preview_calls != 1:
		_fail("mouse motion while already dragging must continue preview updates even when cursor is over UI")
		return
	if controller.get_target_position() != Vector2(80.0, 0.0):
		_fail("drag motion must keep updating the visual target position while hovered UI is present")
		return

	controller.set("_dragging", true)
	controller.set("_drag_pointer_offset", Vector2.ZERO)
	controller.force_mouse_over_ui = true

	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	controller.handle_input(release_event)

	if bool(controller.get("_dragging")):
		_fail("left mouse release over UI must still end drag")
		return
	if model.apply_drop_calls != 1:
		_fail("left mouse release over UI must still apply drop once")
		return

	controller.force_mouse_over_ui = true
	controller.forced_pointer_world_pos = Vector2(10.0, 10.0)
	controller.handle_input(press_event)

	if bool(controller.get("_dragging")):
		_fail("left mouse press while cursor is over UI must not start a new drag")
		return
	if model.start_drag_calls != 1:
		_fail("hover-blocked drag start must not notify model")
		return

	controller.set("_dragging", true)
	controller.call("cancel_drag")
	if bool(controller.get("_dragging")):
		_fail("cancel_drag must clear dragging state")
		return

	print("[test_vzorzone_drag_controller] PASS")
	quit(0)
