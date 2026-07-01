extends SceneTree

const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings centered crowd slot tests...")
	_test_two_units_take_two_center_slots()
	_test_four_units_expand_symmetrically()
	_test_six_units_expand_symmetrically()


func _test_two_units_take_two_center_slots() -> void:
	var geometry := ArenaGeometryServiceScript.new()
	geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var assignments: Array = geometry.call("build_formation_assignments", 2, 0, "ranged")
	var slots: Array[int] = _extract_slots(assignments)
	_assert_equal_array(slots, [10, 11], "two units should occupy the two center slots")


func _test_four_units_expand_symmetrically() -> void:
	var geometry := ArenaGeometryServiceScript.new()
	geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var assignments: Array = geometry.call("build_formation_assignments", 4, 0, "ranged")
	var slots: Array[int] = _extract_slots(assignments)
	_assert_equal_array(slots, [10, 11, 9, 12], "four units should expand symmetrically around center")


func _test_six_units_expand_symmetrically() -> void:
	var geometry := ArenaGeometryServiceScript.new()
	geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var assignments: Array = geometry.call("build_formation_assignments", 6, 0, "ranged")
	var slots: Array[int] = _extract_slots(assignments)
	_assert_equal_array(slots, [10, 11, 9, 12, 8, 13], "six units should keep filling center-out slots")


func _extract_slots(assignments: Array) -> Array[int]:
	var result: Array[int] = []
	for assignment: Dictionary in assignments:
		result.append(int(assignment.get("slot_index", -1)))
	return result


func _assert_equal_array(actual: Array[int], expected: Array[int], message: String) -> void:
	if actual == expected:
		_pass(message)
		return
	_fail(message, "actual=%s expected=%s" % [str(actual), str(expected)])


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
