extends SceneTree

const MobHealStateScript := preload("res://scripts/mob/states/MobHealState.gd")


class FakeStateMachine:
	extends Node

	var last_state: String = ""

	func change_state(state_name: String) -> void:
		last_state = state_name


class FakeShamanMob:
	extends Node2D

	var fired_target: Vector2 = Vector2.ZERO
	var attack_count: int = 0

	func play_attack() -> void:
		attack_count += 1

	func fire_projectile(target_pos: Vector2) -> void:
		fired_target = target_pos

	func get_wall_contact_position() -> Vector2:
		return Vector2(500.0, 200.0)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var mob := FakeShamanMob.new()
	root.add_child(mob)

	var machine := FakeStateMachine.new()
	root.add_child(machine)

	var state = MobHealStateScript.new()
	root.add_child(state)
	state.set_mob(mob)
	state.set_state_machine(machine)
	state.enter()
	state.update(0.1)

	if mob.fired_target.distance_to(Vector2(500.0, 200.0)) > 0.01:
		push_error("[test_mob_heal_state_fallback_attacks_wall] shaman must fire at wall when no allies need healing")
		quit(1)
		return

	if machine.last_state == "MobMoveState":
		push_error("[test_mob_heal_state_fallback_attacks_wall] shaman must not abandon attack fallback for MoveState")
		quit(1)
		return

	print("[test_mob_heal_state_fallback_attacks_wall] PASS")
	quit(0)
