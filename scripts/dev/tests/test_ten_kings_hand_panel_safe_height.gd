extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings hand panel safe height tests...")
	_test_bottom_panel_has_safe_minimum_height()
	_test_hand_scroll_has_minimum_height()


func _instantiate_scene() -> Node:
	var scene: PackedScene = load("res://scenes/dev/TenKingsPrototype.tscn")
	return scene.instantiate()


func _test_bottom_panel_has_safe_minimum_height() -> void:
	var proto := _instantiate_scene()
	var bottom_panel: PanelContainer = proto.get_node_or_null("UI/Root/MainVBox/BottomPanel")
	if bottom_panel != null and bottom_panel.custom_minimum_size.y >= 156.0:
		_pass("test_bottom_panel_has_safe_minimum_height")
	else:
		_fail("test_bottom_panel_has_safe_minimum_height", "BottomPanel minimum height is too small")
	proto.free()


func _test_hand_scroll_has_minimum_height() -> void:
	var proto := _instantiate_scene()
	var hand_scroll: ScrollContainer = proto.get_node_or_null("UI/Root/MainVBox/BottomPanel/Margin/VBox/HandScroll")
	if hand_scroll != null and hand_scroll.custom_minimum_size.y >= 104.0:
		_pass("test_hand_scroll_has_minimum_height")
	else:
		_fail("test_hand_scroll_has_minimum_height", "HandScroll minimum height is too small")
	proto.free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
