## Test: TenKingsPrototype arena layout contract
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	var exit_code: int = 0 if _failed == 0 else 1
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(exit_code)


func _run_tests() -> void:
	print("Running TenKingsPrototype arena layout contract tests...")
	_test_slot_size_is_80x80()
	_test_boards_have_central_corridor()
	_test_corridor_minimum_width()


func _test_slot_size_is_80x80() -> void:
	var BoardSlotUIScript = preload("res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd")
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(0, 0))
	
	var min_size: Vector2 = slot.custom_minimum_size
	var expected_size := Vector2(80.0, 80.0)
	
	if min_size != expected_size:
		_fail("test_slot_size_is_80x80", "Slot size should be 80x80, got %s" % str(min_size))
	else:
		_pass("test_slot_size_is_80x80")
	
	slot.queue_free()


func _test_boards_have_central_corridor() -> void:
	var scene_path := "res://scenes/dev/TenKingsPrototype.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_boards_have_central_corridor", "Scene not found")
		return
	
	var scene: PackedScene = load(scene_path)
	var instance: Node = scene.instantiate()
	
	var player_panel: PanelContainer = instance.get_node_or_null("UI/Root/PlayerBoardPanel")
	var ai_panel: PanelContainer = instance.get_node_or_null("UI/Root/AiBoardPanel")
	
	if player_panel == null or ai_panel == null:
		_fail("test_boards_have_central_corridor", "Missing board panels")
		instance.queue_free()
		return
	
	# Get panel positions
	var player_right: float = player_panel.position.x + player_panel.size.x
	var ai_left: float = ai_panel.position.x
	
	# For scene file offsets, use offset values
	# PlayerBoardPanel: offset_right = panel end X
	# AiBoardPanel: offset_left = panel start X
	var player_offset_right: float = player_panel.get("offset_right")
	var ai_offset_left: float = ai_panel.get("offset_left")
	
	# Boards should not touch edge-to-edge
	var corridor_width: float = ai_offset_left - player_offset_right
	
	if corridor_width <= 0:
		_fail("test_boards_have_central_corridor", "Boards overlap or touch, corridor width: %f" % corridor_width)
	else:
		_pass("test_boards_have_central_corridor")
	
	instance.queue_free()


func _test_corridor_minimum_width() -> void:
	var scene_path := "res://scenes/dev/TenKingsPrototype.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_corridor_minimum_width", "Scene not found")
		return
	
	var scene: PackedScene = load(scene_path)
	var instance: Node = scene.instantiate()
	
	var player_panel: PanelContainer = instance.get_node_or_null("UI/Root/PlayerBoardPanel")
	var ai_panel: PanelContainer = instance.get_node_or_null("UI/Root/AiBoardPanel")
	
	if player_panel == null or ai_panel == null:
		_fail("test_corridor_minimum_width", "Missing board panels")
		instance.queue_free()
		return
	
	var player_offset_right: float = player_panel.get("offset_right")
	var ai_offset_left: float = ai_panel.get("offset_left")
	var corridor_width: float = ai_offset_left - player_offset_right
	
	var min_corridor: float = 180.0
	
	if corridor_width < min_corridor:
		_fail("test_corridor_minimum_width", "Corridor too narrow: %f < %f" % [corridor_width, min_corridor])
	else:
		_pass("test_corridor_minimum_width")
	
	instance.queue_free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
