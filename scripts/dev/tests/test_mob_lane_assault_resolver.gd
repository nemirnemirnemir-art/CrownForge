extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var resolver_script := load("res://scripts/mob/MobLaneAssault.gd")
	if resolver_script == null:
		push_error("[test_mob_lane_assault_resolver] MobLaneAssault script is missing")
		quit(1)
		return

	var resolver = resolver_script.new()
	if resolver == null:
		push_error("[test_mob_lane_assault_resolver] failed to instantiate MobLaneAssault")
		quit(1)
		return

	if not resolver.has_method("capture_lane_from_spawn"):
		push_error("[test_mob_lane_assault_resolver] capture_lane_from_spawn() is missing")
		quit(1)
		return

	if not resolver.has_method("get_lane_y"):
		push_error("[test_mob_lane_assault_resolver] get_lane_y() is missing")
		quit(1)
		return

	resolver.call("capture_lane_from_spawn", 210.0)
	var lane_y: float = float(resolver.call("get_lane_y", 340.0, Rect2(0.0, 100.0, 1200.0, 400.0)))
	if absf(lane_y - 210.0) > 0.01:
		push_error("[test_mob_lane_assault_resolver] stored spawn lane must persist, got %.3f" % lane_y)
		quit(1)
		return

	if not resolver.has_method("get_wall_contact_point"):
		push_error("[test_mob_lane_assault_resolver] get_wall_contact_point() is missing")
		quit(1)
		return

	var wall_rect := Rect2(Vector2(500.0, 100.0), Vector2(80.0, 400.0))
	var wall_contact: Vector2 = resolver.call("get_wall_contact_point", wall_rect, 340.0, Rect2(0.0, 100.0, 1200.0, 400.0))
	if wall_contact.distance_to(Vector2(580.0, 210.0)) > 0.01:
		push_error("[test_mob_lane_assault_resolver] wall contact must stay on stored lane, got %s" % [wall_contact])
		quit(1)
		return

	if not resolver.has_method("get_wall_approach_point"):
		push_error("[test_mob_lane_assault_resolver] get_wall_approach_point() is missing")
		quit(1)
		return

	var wall_approach: Vector2 = resolver.call("get_wall_approach_point", wall_rect, 340.0, 150.0, Rect2(0.0, 100.0, 1200.0, 400.0))
	if wall_approach.distance_to(Vector2(730.0, 210.0)) > 0.01:
		push_error("[test_mob_lane_assault_resolver] wall approach must keep lane and standoff, got %s" % [wall_approach])
		quit(1)
		return

	print("[test_mob_lane_assault_resolver] PASS")
	quit(0)
