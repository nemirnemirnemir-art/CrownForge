extends "res://scripts/mob/states/MobState.gd"

const SEARCH_INTERVAL: float = 0.25
const IDLE_BREAK_CHECK_INTERVAL: float = 0.7

var _search_left: float = 0.0
var _idle_break_left: float = 0.0
var _move_target: Vector2 = Vector2.ZERO

func enter() -> void:
	if not mob:
		return
	_search_left = 0.0
	_idle_break_left = IDLE_BREAK_CHECK_INTERVAL
	_move_target = _get_wall_position()
	if mob.has_method("play_gnoll_anim"):
		mob.play_gnoll_anim("walk")

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	if mob.has_method("consume_hit_reaction") and mob.consume_hit_reaction():
		state_machine.change_state("GnollHitState")
		return

	_search_left -= delta
	if _search_left <= 0.0:
		_search_left = SEARCH_INTERVAL
		_search_and_transition()

	_idle_break_left -= delta
	if _idle_break_left <= 0.0:
		_idle_break_left = IDLE_BREAK_CHECK_INTERVAL
		if mob.has_method("roll_walk_idle_break") and mob.roll_walk_idle_break():
			if mob.has_method("set_idle_request"):
				mob.set_idle_request(0.25)
			state_machine.change_state("GnollIdleState")

func physics_update(_delta: float) -> void:
	if not mob:
		return
	if _move_target == Vector2.ZERO:
		return

	var dir := (_move_target - mob.global_position).normalized()
	var move_speed: float = mob.get_effective_move_speed() if mob.has_method("get_effective_move_speed") else float(mob.move_speed)
	mob.velocity = dir * move_speed
	mob.move_and_slide()
	if mob.has_method("enforce_battlefield_bounds"):
		var bounced_direction: Vector2 = mob.enforce_battlefield_bounds(dir)
		if bounced_direction != dir and bounced_direction != Vector2.ZERO:
			mob.velocity = bounced_direction * move_speed

	if mob.has_method("face_target_x"):
		mob.face_target_x(_move_target.x)

func exit() -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func _search_and_transition() -> void:
	var target: Node2D = CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))
	if target and is_instance_valid(target):
		_move_target = target.global_position
		if mob.combat:
			mob.combat._combat_target = target
		var dist := mob.global_position.distance_to(target.global_position)
		if dist <= float(mob.attack_range) + 16.0:
			state_machine.change_state("GnollThrowState")
			return
	else:
		if mob.combat:
			mob.combat.clear_combat_target()
		_move_target = _get_wall_position()

	var dist_to_wall := mob.global_position.distance_to(_move_target)
	if dist_to_wall <= 20.0:
		if mob.has_method("set_idle_request"):
			mob.set_idle_request(0.2)
		state_machine.change_state("GnollIdleState")

func _get_wall_position() -> Vector2:
	if mob and mob.has_method("get_wall_position"):
		return mob.get_wall_position()
	return Vector2(600.0, 550.0)
