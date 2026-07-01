extends "res://scripts/mob/states/MobState.gd"

var _idle_left: float = 0.0

func enter() -> void:
	if not mob:
		return

	mob.velocity = Vector2.ZERO
	if mob.has_method("play_gnoll_anim"):
		mob.play_gnoll_anim("idle")

	if mob.has_method("consume_idle_request"):
		_idle_left = mob.consume_idle_request(0.45)
	else:
		_idle_left = 0.45

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	mob.velocity = Vector2.ZERO

	if mob.has_method("consume_hit_reaction") and mob.consume_hit_reaction():
		state_machine.change_state("GnollHitState")
		return

	var target: Node2D = null
	if mob.has_method("find_nearest_hero"):
		target = mob.find_nearest_hero(float(mob.aggro_range))
	else:
		target = CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))

	if target and is_instance_valid(target):
		if mob.combat:
			mob.combat._combat_target = target
		var dist := mob.global_position.distance_to(target.global_position)
		if dist <= float(mob.attack_range) + 16.0:
			state_machine.change_state("GnollThrowState")
			return

	_idle_left -= delta
	if _idle_left <= 0.0:
		state_machine.change_state("GnollWalkState")

func physics_update(_delta: float) -> void:
	if mob:
		mob.velocity = Vector2.ZERO
