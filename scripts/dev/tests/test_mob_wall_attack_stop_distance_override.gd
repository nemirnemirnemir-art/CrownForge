extends SceneTree

const WallScene := preload("res://scenes/map/Wall.tscn")
const MobScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")
const MobMovingToWallStateScript := preload("res://scripts/mob/states/MobMovingToWallState.gd")


class FakeStateMachine:
	extends Node

	var last_state: String = ""

	func change_state(state_name: String) -> void:
		last_state = state_name


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var wall := WallScene.instantiate() as Wall
	root.add_child(wall)
	wall.global_position = Vector2(540.0, 320.0)

	var mob := MobScene.instantiate() as Mob
	root.add_child(mob)

	await process_frame

	mob.set_map_bounds(Rect2(0.0, -400.0, 1400.0, 1400.0))
	mob.set_assault_lane_y(220.0)
	mob.set_wall_attack_stop_distance(120.0)
	var script_constants: Dictionary = mob.get_script().get_script_constant_map()
	if script_constants.has("WALL_ATTACK_RANGE_MELEE") or script_constants.has("WALL_ATTACK_RANGE_RANGED") or script_constants.has("WALL_ATTACK_TOLERANCE"):
		push_error("[test_mob_wall_attack_stop_distance_override] Mob facade must not own wall-rule constants")
		quit(1)
		return

	if not mob.has_method("get_wall_front_offset_x"):
		push_error("[test_mob_wall_attack_stop_distance_override] Mob must expose get_wall_front_offset_x()")
		quit(1)
		return

	var front_offset: float = mob.get_wall_front_offset_x()
	if front_offset <= 0.0:
		push_error("[test_mob_wall_attack_stop_distance_override] expected positive front offset, got %.3f" % front_offset)
		quit(1)
		return

	if absf(mob.get_wall_attack_stand_off() - (120.0 + front_offset)) > 0.01:
		push_error("[test_mob_wall_attack_stop_distance_override] expected center stop distance %.3f, got %.3f" % [120.0 + front_offset, mob.get_wall_attack_stand_off()])
		quit(1)
		return

	var wall_rect := wall.get_world_rect()
	var approach := mob.get_wall_position()
	if approach.distance_to(Vector2(wall_rect.end.x + 120.0 + front_offset, 220.0)) > 0.01:
		push_error("[test_mob_wall_attack_stop_distance_override] approach point mismatch: %s" % [approach])
		quit(1)
		return

	mob.set_wall_attack_stop_distance(0.0)
	var zero_gap_approach := mob.get_wall_position()
	if zero_gap_approach.distance_to(Vector2(wall_rect.end.x + front_offset, 220.0)) > 0.01:
		push_error("[test_mob_wall_attack_stop_distance_override] zero stop distance must place front edge on wall, got %s" % [zero_gap_approach])
		quit(1)
		return

	mob.global_position = Vector2(wall_rect.end.x + front_offset + 10.0, 220.0)
	var machine := FakeStateMachine.new()
	root.add_child(machine)
	var state := MobMovingToWallStateScript.new()
	root.add_child(state)
	state.set_mob(mob)
	state.set_state_machine(machine)
	state.enter()
	state.update(0.016)
	if machine.last_state == "MobAttackWallState":
		push_error("[test_mob_wall_attack_stop_distance_override] zero stop distance must not trigger wall attack while still 10px from wall")
		quit(1)
		return

	print("[test_mob_wall_attack_stop_distance_override] PASS")
	quit(0)
