extends SceneTree

const MobRunIdleStateScript := preload("res://scripts/mob/states/MobRunIdleState.gd")


class FakeWall:
	extends Node2D

	var total_damage: float = 0.0

	func take_damage(amount: float) -> void:
		total_damage += amount


class FakeStateMachine:
	extends Node

	var last_state: String = ""

	func change_state(state_name: String) -> void:
		last_state = state_name


class FakeMob:
	extends Node2D

	var velocity: Vector2 = Vector2.ZERO
	var wall_target: Node2D = null

	func play_walk() -> void:
		pass

	func get_slide_collision_count() -> int:
		return 0

	func get_distance_to_wall() -> float:
		return 0.0

	func get_wall_target_node() -> Node2D:
		return wall_target


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var wall := FakeWall.new()
	root.add_child(wall)

	var mob := FakeMob.new()
	mob.wall_target = wall
	root.add_child(mob)

	var machine := FakeStateMachine.new()
	root.add_child(machine)

	var state = MobRunIdleStateScript.new()
	state.set_mob(mob)
	state.set_state_machine(machine)
	state.enter()
	state._check_wall_collision()

	if wall.total_damage <= 0.0:
		push_error("[test_mob_run_idle_state_explodes_on_wall_distance] wall buster must explode when wall distance is zero")
		quit(1)
		return

	if machine.last_state != "MobDeathState":
		push_error("[test_mob_run_idle_state_explodes_on_wall_distance] expected MobDeathState, got %s" % machine.last_state)
		quit(1)
		return

	print("[test_mob_run_idle_state_explodes_on_wall_distance] PASS")
	quit(0)
