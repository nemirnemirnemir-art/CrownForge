extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings player board expansion layout tests...")
	_test_player_board_is_wider_than_before()
	_test_main_layout_has_no_visible_ai_board_panel()
	_test_arena_panel_keeps_minimum_width()


func _instantiate_scene() -> Node:
	var scene: PackedScene = load("res://scenes/dev/TenKingsPrototype.tscn")
	return scene.instantiate()


func _test_player_board_is_wider_than_before() -> void:
	var proto := _instantiate_scene()
	var player_panel: PanelContainer = proto.get_node_or_null("UI/Root/MainVBox/MiddleHBox/PlayerBoardPanel")
	if player_panel == null:
		_fail("test_player_board_is_wider_than_before", "PlayerBoardPanel missing")
		proto.free()
		return
	if player_panel.custom_minimum_size.x >= 620.0:
		_pass("test_player_board_is_wider_than_before")
	else:
		_fail("test_player_board_is_wider_than_before", "expected width >= 620, got %.2f" % player_panel.custom_minimum_size.x)
	proto.free()


func _test_main_layout_has_no_visible_ai_board_panel() -> void:
	var proto := _instantiate_scene()
	var ai_panel: Node = proto.get_node_or_null("UI/Root/MainVBox/MiddleHBox/AiBoardPanel")
	if ai_panel == null:
		_pass("test_main_layout_has_no_visible_ai_board_panel")
	else:
		_fail("test_main_layout_has_no_visible_ai_board_panel", "AiBoardPanel should not be inside main MiddleHBox layout")
	proto.free()


func _test_arena_panel_keeps_minimum_width() -> void:
	var proto := _instantiate_scene()
	var arena_panel: PanelContainer = proto.get_node_or_null("UI/Root/MainVBox/MiddleHBox/ArenaPanel")
	if arena_panel == null:
		_fail("test_arena_panel_keeps_minimum_width", "ArenaPanel missing")
		proto.free()
		return
	if arena_panel.custom_minimum_size.x >= 300.0:
		_pass("test_arena_panel_keeps_minimum_width")
	else:
		_fail("test_arena_panel_keeps_minimum_width", "arena width too small: %.2f" % arena_panel.custom_minimum_size.x)
	proto.free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
