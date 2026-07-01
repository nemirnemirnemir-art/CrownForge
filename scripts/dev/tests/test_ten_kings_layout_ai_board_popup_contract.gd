extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings AI board popup contract tests...")
	_test_scene_has_ai_board_button()
	_test_scene_has_ai_board_popup()
	_test_popup_contains_ai_grid_and_close_button()


func _instantiate_scene() -> Node:
	var scene: PackedScene = load("res://scenes/dev/TenKingsPrototype.tscn")
	return scene.instantiate()


func _test_scene_has_ai_board_button() -> void:
	var proto := _instantiate_scene()
	var button: Button = proto.get_node_or_null("UI/Root/AiBoardButton")
	if button != null and button.text == "AI Board":
		_pass("test_scene_has_ai_board_button")
	else:
		_fail("test_scene_has_ai_board_button", "AiBoardButton missing or wrong text")
	proto.free()


func _test_scene_has_ai_board_popup() -> void:
	var proto := _instantiate_scene()
	var popup: PanelContainer = proto.get_node_or_null("UI/Root/AiBoardPopup")
	if popup != null:
		_pass("test_scene_has_ai_board_popup")
	else:
		_fail("test_scene_has_ai_board_popup", "AiBoardPopup missing")
	proto.free()


func _test_popup_contains_ai_grid_and_close_button() -> void:
	var proto := _instantiate_scene()
	var grid: GridContainer = proto.get_node_or_null("UI/Root/AiBoardPopup/Margin/VBox/Slots")
	var close_button: Button = proto.get_node_or_null("UI/Root/AiBoardPopup/Margin/VBox/Header/CloseButton")
	if grid != null and close_button != null:
		_pass("test_popup_contains_ai_grid_and_close_button")
	else:
		_fail("test_popup_contains_ai_grid_and_close_button", "popup grid or close button missing")
	proto.free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
