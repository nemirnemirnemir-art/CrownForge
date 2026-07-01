extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var geometry_script := load("res://scripts/map/WallGeometry.gd")
	if geometry_script == null:
		push_error("[test_wall_geometry_lane_points] WallGeometry script is missing")
		quit(1)
		return

	var geometry = geometry_script.new()
	if geometry == null:
		push_error("[test_wall_geometry_lane_points] failed to instantiate WallGeometry")
		quit(1)
		return

	var wall_rect := Rect2(Vector2(500.0, 100.0), Vector2(80.0, 400.0))

	if not geometry.has_method("get_lane_contact_point"):
		push_error("[test_wall_geometry_lane_points] get_lane_contact_point() is missing")
		quit(1)
		return

	var top_contact: Vector2 = geometry.call("get_lane_contact_point", wall_rect, -50.0)
	if top_contact.distance_to(Vector2(580.0, 100.0)) > 0.01:
		push_error("[test_wall_geometry_lane_points] top lane contact mismatch: %s" % [top_contact])
		quit(1)
		return

	var bottom_contact: Vector2 = geometry.call("get_lane_contact_point", wall_rect, 900.0)
	if bottom_contact.distance_to(Vector2(580.0, 500.0)) > 0.01:
		push_error("[test_wall_geometry_lane_points] bottom lane contact mismatch: %s" % [bottom_contact])
		quit(1)
		return

	if not geometry.has_method("get_lane_approach_point"):
		push_error("[test_wall_geometry_lane_points] get_lane_approach_point() is missing")
		quit(1)
		return

	var approach_point: Vector2 = geometry.call("get_lane_approach_point", wall_rect, 140.0, 150.0)
	if approach_point.distance_to(Vector2(730.0, 140.0)) > 0.01:
		push_error("[test_wall_geometry_lane_points] lane approach mismatch: %s" % [approach_point])
		quit(1)
		return

	if not geometry.has_method("get_distance_to_rect"):
		push_error("[test_wall_geometry_lane_points] get_distance_to_rect() is missing")
		quit(1)
		return

	var distance_to_wall: float = float(geometry.call("get_distance_to_rect", wall_rect, Vector2(730.0, 140.0)))
	if absf(distance_to_wall - 150.0) > 0.01:
		push_error("[test_wall_geometry_lane_points] expected 150.0 distance, got %.3f" % distance_to_wall)
		quit(1)
		return

	print("[test_wall_geometry_lane_points] PASS")
	quit(0)
