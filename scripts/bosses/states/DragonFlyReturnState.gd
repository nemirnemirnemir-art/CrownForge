extends "res://scripts/mob/states/MobState.gd"

const PHASE_WAIT: int = 0
const PHASE_DESCEND: int = 1

var _phase: int = PHASE_WAIT
var _wait_left: float = 0.0
var _landing_point: Vector2 = Vector2.ZERO

func enter() -> void:
	var dragon := _get_dragon()
	if dragon == null:
		if state_machine:
			state_machine.change_state("MobMoveState")
		return

	dragon.velocity = Vector2.ZERO
	_landing_point = dragon.call("get_flight_takeoff_origin")
	_wait_left = float(dragon.call("get_return_delay"))
	_phase = PHASE_WAIT
	dragon.call("hide_for_flight_return")

func update(delta: float) -> void:
	var dragon := _get_dragon()
	if dragon == null or not state_machine:
		return

	if "is_dead" in dragon and bool(dragon.is_dead):
		state_machine.change_state("MobDeathState")
		return

	if _phase == PHASE_WAIT:
		_wait_left -= delta
		if _wait_left <= 0.0:
			dragon.call("show_for_flight_return")
			dragon.call("play_dragon_fly_anim")
			_phase = PHASE_DESCEND

func physics_update(delta: float) -> void:
	var dragon := _get_dragon()
	if dragon == null or not state_machine:
		return

	if _phase != PHASE_DESCEND:
		return

	var pos := dragon.global_position
	pos.x = _landing_point.x
	pos.y = move_toward(pos.y, _landing_point.y, float(dragon.call("get_descent_speed")) * delta)
	dragon.global_position = pos

	if absf(dragon.global_position.y - _landing_point.y) <= 0.5:
		dragon.global_position = _landing_point
		dragon.call("finish_flight_cycle")
		state_machine.change_state("MobMoveState")

func exit() -> void:
	var dragon := _get_dragon()
	if dragon:
		dragon.visible = true
		dragon.velocity = Vector2.ZERO

func _get_dragon() -> Node2D:
	if mob == null:
		return null
	if not mob.has_method("hide_for_flight_return"):
		return null
	return mob
