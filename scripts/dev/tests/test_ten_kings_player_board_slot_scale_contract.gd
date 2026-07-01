extends SceneTree

const BoardSlotUIScript = preload("res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings player board slot scale contract tests...")
	_test_player_slot_can_be_built_larger_than_default()
	_test_default_slot_size_remains_supported()


func _test_player_slot_can_be_built_larger_than_default() -> void:
	var slot := BoardSlotUIScript.new()
	slot.setup(Vector2i.ZERO, 104.0)
	if slot.custom_minimum_size == Vector2(104.0, 104.0):
		_pass("test_player_slot_can_be_built_larger_than_default")
	else:
		_fail("test_player_slot_can_be_built_larger_than_default", "actual=%s" % str(slot.custom_minimum_size))


func _test_default_slot_size_remains_supported() -> void:
	var slot := BoardSlotUIScript.new()
	slot.setup(Vector2i.ZERO)
	if slot.custom_minimum_size == Vector2(56.0, 56.0):
		_pass("test_default_slot_size_remains_supported")
	else:
		_fail("test_default_slot_size_remains_supported", "actual=%s" % str(slot.custom_minimum_size))


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
