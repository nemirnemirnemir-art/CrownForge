extends "res://scripts/mob/states/MobState.gd"

func enter() -> void:
	var dragon := _get_dragon()
	if dragon == null:
		if state_machine:
			state_machine.change_state("MobMoveState")
		return

	if not bool(dragon.call("begin_flight_cycle")):
		if state_machine:
			state_machine.change_state("MobMoveState")
		return

	dragon.velocity = Vector2.ZERO
	dragon.call("set_facing_dir_x", -1.0)
	dragon.call("play_dragon_up_anim")

func update(_delta: float) -> void:
	var dragon := _get_dragon()
	if dragon == null or not state_machine:
		return
	if "is_dead" in dragon and bool(dragon.is_dead):
		state_machine.change_state("MobDeathState")

func physics_update(delta: float) -> void:
	var dragon := _get_dragon()
	if dragon == null or not state_machine:
		return

	var peak: Vector2 = dragon.call("get_flight_peak_position")
	var pos := dragon.global_position
	pos.y = move_toward(pos.y, peak.y, float(dragon.call("get_takeoff_speed")) * delta)
	dragon.global_position = pos

	if absf(dragon.global_position.y - peak.y) <= 0.5:
		dragon.global_position = peak
		state_machine.change_state("DragonFlyAcrossState")

func exit() -> void:
	var dragon := _get_dragon()
	if dragon:
		dragon.velocity = Vector2.ZERO

func _get_dragon() -> Node2D:
	if mob == null:
		return null
	if not mob.has_method("begin_flight_cycle"):
		return null
	return mob
