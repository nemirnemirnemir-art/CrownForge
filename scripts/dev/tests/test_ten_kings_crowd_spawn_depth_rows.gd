extends SceneTree

const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings formation depth-row tests...")
	_test_forty_four_units_use_two_depth_rows()


func _test_forty_four_units_use_two_depth_rows() -> void:
	var geometry := ArenaGeometryServiceScript.new()
	geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var assignments: Array = geometry.call("build_formation_assignments", 44, 1, "ranged")
	var row0_count: int = 0
	var row1_count: int = 0
	var row0_x: float = 0.0
	var row1_x: float = 0.0
	for assignment: Dictionary in assignments:
		var depth_row: int = int(assignment.get("depth_row", -1))
		var pos: Vector2 = assignment.get("position", Vector2.ZERO)
		if depth_row == 0:
			row0_count += 1
			row0_x = pos.x
		elif depth_row == 1:
			row1_count += 1
			row1_x = pos.x
	var valid_counts: bool = row0_count == 22 and row1_count == 22
	var valid_depth: bool = row1_x > row0_x
	if valid_counts and valid_depth:
		_pass("forty-four units should fill two depth rows on the same side")
	else:
		_fail("forty-four units should fill two depth rows on the same side", "row0=%d row1=%d row0_x=%.2f row1_x=%.2f" % [row0_count, row1_count, row0_x, row1_x])


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
