extends "res://scripts/mob/states/MobState.gd"

const RETARGET_RESET_INTERVAL: float = 0.35

var _time_left: float = 3.0
var _retarget_left: float = RETARGET_RESET_INTERVAL

func enter() -> void:
	if not mob:
		return

	mob.velocity = Vector2.ZERO
	_time_left = mob.get_charge_duration() if mob.has_method("get_charge_duration") else 3.0
	_retarget_left = 0.0

	if mob.has_method("reset_charge_cd"):
		mob.reset_charge_cd()
	if mob.has_method("set_invincible_active"):
		mob.set_invincible_active(true)
	if mob.has_method("clear_hero_targets_for_charge"):
		mob.clear_hero_targets_for_charge()
	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("charge")

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	mob.velocity = Vector2.ZERO

	_retarget_left -= delta
	if _retarget_left <= 0.0:
		_retarget_left = RETARGET_RESET_INTERVAL
		if mob.has_method("clear_hero_targets_for_charge"):
			mob.clear_hero_targets_for_charge()

	_time_left -= delta
	if _time_left <= 0.0:
		state_machine.change_state("MinotaurWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func exit() -> void:
	if mob and mob.has_method("set_invincible_active"):
		mob.set_invincible_active(false)
