extends SceneTree

const WallScene := preload("res://scenes/map/Wall.tscn")
const MobScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var wall := WallScene.instantiate() as Wall
	if wall == null:
		push_error("[test_mob_lane_assault_runtime] failed to instantiate Wall")
		quit(1)
		return
	wall.global_position = Vector2(540.0, 320.0)
	root.add_child(wall)

	var mob := MobScene.instantiate() as Mob
	if mob == null:
		push_error("[test_mob_lane_assault_runtime] failed to instantiate GoblinSwordsman")
		quit(1)
		return
	root.add_child(mob)

	await process_frame

	var wall_rect := wall.get_world_rect()
	var lane_y := wall_rect.position.y + 60.0
	mob.global_position = Vector2(wall_rect.end.x + 240.0, lane_y)
	mob.set_map_bounds(Rect2(0.0, -400.0, 1400.0, 1400.0))
	mob.set_assault_lane_y(lane_y)

	var wall_contact := mob.get_wall_contact_position()
	if wall_contact.distance_to(Vector2(wall_rect.end.x, lane_y)) > 0.01:
		push_error("[test_mob_lane_assault_runtime] wall contact must preserve lane, got %s" % [wall_contact])
		quit(1)
		return

	var wall_approach := mob.get_wall_position()
	var expected_x := wall_rect.end.x + mob.get_wall_attack_stand_off()
	if wall_approach.distance_to(Vector2(expected_x, lane_y)) > 0.01:
		push_error("[test_mob_lane_assault_runtime] wall approach mismatch: %s" % [wall_approach])
		quit(1)
		return

	if not mob.has_method("get_wall_front_offset_x"):
		push_error("[test_mob_lane_assault_runtime] Mob must expose get_wall_front_offset_x()")
		quit(1)
		return

	var front_offset: float = mob.get_wall_front_offset_x()
	if absf(mob.get_wall_attack_stand_off() - (50.0 + front_offset)) > 0.01:
		push_error("[test_mob_lane_assault_runtime] melee mobs must now stop with 50px visual gap, got center gap %.3f" % mob.get_wall_attack_stand_off())
		quit(1)
		return

	var distance_to_wall := mob.get_distance_to_wall()
	if absf(distance_to_wall - 240.0) > 0.01:
		push_error("[test_mob_lane_assault_runtime] expected 240.0 wall distance, got %.3f" % distance_to_wall)
		quit(1)
		return

	print("[test_mob_lane_assault_runtime] PASS")
	quit(0)
