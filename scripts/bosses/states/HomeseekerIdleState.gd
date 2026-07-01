extends "res://scripts/mob/states/MobState.gd"

var _time_left: float = 1.2

func enter() -> void:
	_time_left = 1.2
	if mob and mob.has_method("play_boss_anim"):
		mob.play_boss_anim("idle")

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	var target := CombatTargetFinder.find_nearest(mob, "hero", 350.0)
	if target and is_instance_valid(target):
		_time_left = minf(_time_left, 0.35)

	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.change_state("HomeseekerWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func exit() -> void:
	if mob:
		mob.velocity = Vector2.ZERO
