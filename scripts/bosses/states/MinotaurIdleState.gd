extends "res://scripts/mob/states/MobState.gd"

var _time_left: float = 1.0
var _allow_target_interrupt: bool = true

func enter() -> void:
	if not mob:
		return

	mob.velocity = Vector2.ZERO
	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("idle")

	if mob.has_method("consume_initial_idle") and mob.consume_initial_idle():
		_allow_target_interrupt = false
		if "start_idle_duration" in mob:
			_time_left = maxf(0.1, float(mob.start_idle_duration))
		else:
			_time_left = 2.0
	elif mob.has_method("consume_idle_cycle_after_kill") and mob.consume_idle_cycle_after_kill():
		_allow_target_interrupt = false
		if mob.has_method("get_idle_cycle_duration"):
			_time_left = mob.get_idle_cycle_duration()
		else:
			_time_left = 1.6
	else:
		_allow_target_interrupt = true
		_time_left = 0.9

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	mob.velocity = Vector2.ZERO

	var target := CombatTargetFinder.find_nearest(mob, "hero", 420.0)
	if _allow_target_interrupt and target and is_instance_valid(target):
		_time_left = minf(_time_left, 0.35)

	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.change_state("MinotaurWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func exit() -> void:
	if mob:
		mob.velocity = Vector2.ZERO
