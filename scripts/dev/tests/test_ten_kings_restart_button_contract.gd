extends SceneTree

const PROTO_SCENE_PATH := "res://scenes/dev/TenKingsPrototype.tscn"


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var proto := _instantiate_proto()
	if proto == null:
		print("FAIL: test_ten_kings_restart_button_contract")
		quit(1)
		return
	await process_frame

	var restart_button := proto.get_node_or_null("UI/Root/RestartButton") as Button
	if restart_button == null:
		print("  ERROR: RestartButton not found")
		_cleanup(proto)
		_fail_and_quit(proto)
		return
	print("  RestartButton found")

	var ai_board_button := proto.get_node_or_null("UI/Root/AiBoardButton") as Button
	if ai_board_button == null:
		print("  ERROR: AiBoardButton not found")
		_cleanup(proto)
		_fail_and_quit(proto)
		return

	if restart_button.position.distance_to(ai_board_button.position) > 180.0:
		print("  ERROR: RestartButton is not placed near AiBoardButton")
		_cleanup(proto)
		_fail_and_quit(proto)
		return
	print("  RestartButton placed next to AiBoardButton")

	if not proto.has_method("_on_restart_button_pressed"):
		print("  ERROR: Prototype missing _on_restart_button_pressed")
		_cleanup(proto)
		_fail_and_quit(proto)
		return
	if not proto.has_method("_reload_current_scene"):
		print("  ERROR: Prototype missing _reload_current_scene helper")
		_cleanup(proto)
		_fail_and_quit(proto)
		return
	print("  Restart methods found")

	var connections := restart_button.pressed.get_connections()
	var is_connected := false
	for connection: Dictionary in connections:
		if connection.get("callable") == Callable(proto, "_on_restart_button_pressed"):
			is_connected = true
			break
	if not is_connected:
		print("  ERROR: RestartButton is not connected to _on_restart_button_pressed")
		_cleanup(proto)
		_fail_and_quit(proto)
		return
	print("  RestartButton signal connected")

	_cleanup(proto)
	print("PASS: test_ten_kings_restart_button_contract")
	quit(0)


func _instantiate_proto() -> Node:
	if not ResourceLoader.exists(PROTO_SCENE_PATH):
		print("  ERROR: Scene not found: %s" % PROTO_SCENE_PATH)
		return null
	var scene: PackedScene = load(PROTO_SCENE_PATH)
	if scene == null:
		print("  ERROR: Failed to load scene")
		return null
	var proto := scene.instantiate()
	if proto == null:
		print("  ERROR: Failed to instantiate scene")
		return null
	root.add_child(proto)
	return proto


func _cleanup(proto: Node) -> void:
	if proto != null and is_instance_valid(proto):
		proto.queue_free()


func _fail_and_quit(proto: Node) -> void:
	_cleanup(proto)
	print("FAIL: test_ten_kings_restart_button_contract")
	quit(1)
