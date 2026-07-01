extends "res://scripts/mob/states/MobState.gd"

const SEARCH_INTERVAL: float = 0.2

var _search_left: float = 0.0
var _move_target: Vector2 = Vector2.ZERO

func enter() -> void:
	if not mob:
		return
	_search_left = 0.0
	_move_target = _get_wall_position()
	if mob.has_method("play_boss_anim"):
		mob.play_boss_anim("walk")

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	_search_left -= delta
	if _search_left <= 0.0:
		_search_left = SEARCH_INTERVAL
		_search_and_transition()

func physics_update(_delta: float) -> void:
	if not mob:
		return
	if _move_target == Vector2.ZERO:
		return

	var direction := (_move_target - mob.global_position).normalized()
	mob.velocity = direction * mob.move_speed
	mob.move_and_slide()
	if mob.has_method("face_target_x"):
		mob.face_target_x(_move_target.x)

func exit() -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func _search_and_transition() -> void:
	var target := CombatTargetFinder.find_nearest(mob, "hero", float(mob.aggro_range))
	if target and is_instance_valid(target):
		_move_target = target.global_position
		if mob.combat:
			mob.combat._combat_target = target

		if mob.has_method("is_point_ready") and mob.is_point_ready():
			state_machine.change_state("MinotaurPointState")
			return

		if mob.has_method("is_charge_ready") and mob.is_charge_ready():
			state_machine.change_state("MinotaurChargeState")
			return

		var dist := mob.global_position.distance_to(target.global_position)
		if dist <= float(mob.attack_range) + 20.0:
			state_machine.change_state("MinotaurAttackState")
			return
	else:
		_move_target = _get_wall_position()

		if mob.has_method("is_point_ready") and mob.is_point_ready():
			state_machine.change_state("MinotaurPointState")
			return

		var dist_to_wall := mob.global_position.distance_to(_move_target)
		if dist_to_wall <= 18.0:
			state_machine.change_state("MinotaurIdleState")

func _get_wall_position() -> Vector2:
	if mob and mob.has_method("get_wall_position"):
		return mob.get_wall_position()
	return Vector2(600.0, 550.0)
