extends SceneTree

const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _run_tests() -> void:
	print("Running Ten Kings slot overflow split tests...")
	_test_eighty_eight_units_split_inside_existing_buckets()


func _test_eighty_eight_units_split_inside_existing_buckets() -> void:
	var geometry := ArenaGeometryServiceScript.new()
	geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
	var assignments: Array = geometry.call("build_formation_assignments", 88, 1, "ranged")
	var bucket_counts: Dictionary = {}
	var bucket_positions: Dictionary = {}
	var max_depth_row: int = -1
	for assignment: Dictionary in assignments:
		var bucket_key: String = "%d:%d" % [int(assignment.get("depth_row", -1)), int(assignment.get("slot_index", -1))]
		bucket_counts[bucket_key] = int(bucket_counts.get(bucket_key, 0)) + 1
		max_depth_row = maxi(max_depth_row, int(assignment.get("depth_row", -1)))
		if not bucket_positions.has(bucket_key):
			bucket_positions[bucket_key] = []
		(bucket_positions[bucket_key] as Array).append(assignment.get("position", Vector2.ZERO))

	var all_buckets_split: bool = true
	for bucket_key: String in bucket_counts.keys():
		if int(bucket_counts[bucket_key]) != 2:
			all_buckets_split = false
			break
		var positions: Array = bucket_positions[bucket_key]
		if positions.size() == 2 and positions[0] == positions[1]:
			all_buckets_split = false
			break

	if max_depth_row == 1 and all_buckets_split:
		_pass("eighty-eight units should split inside the same two formation rows")
	else:
		_fail("eighty-eight units should split inside the same two formation rows", "max_depth_row=%d all_buckets_split=%s" % [max_depth_row, str(all_buckets_split)])


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
