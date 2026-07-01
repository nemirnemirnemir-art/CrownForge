extends "res://scripts/mob/states/MobState.gd"

var _search_timer: float = 0.0
const SEARCH_INTERVAL: float = 0.25

var _shake_timer: float = 0.0
const SHAKE_INTERVAL: float = 0.25

var _move_target: Vector2 = Vector2.ZERO

func enter() -> void:
	_search_timer = 0.0
	_shake_timer = 0.0
	if mob and mob.has_method("play_boss_anim"):
		mob.play_boss_anim("walk")
	_move_target = _get_wall_position()

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return

	_search_timer -= delta
	if _search_timer <= 0.0:
		_search_timer = SEARCH_INTERVAL
		_search_and_transition()

func physics_update(delta: float) -> void:
	if not mob:
		return
	if _move_target == Vector2.ZERO:
		return

	var direction := (_move_target - mob.global_position).normalized()
	mob.velocity = direction * mob.move_speed
	mob.move_and_slide()

	if mob.has_method("face_target_x"):
		mob.face_target_x(_move_target.x)

	_shake_timer -= delta
	if _shake_timer <= 0.0:
		_shake_timer = SHAKE_INTERVAL
		if mob.has_method("request_walk_shake"):
			mob.request_walk_shake()

func exit() -> void:
	if mob:
		mob.velocity = Vector2.ZERO

func _search_and_transition() -> void:
	var aggro_range: float = float(mob.aggro_range)

	var target := CombatTargetFinder.find_nearest(mob, "hero", aggro_range)
	if target and is_instance_valid(target):
		_move_target = target.global_position
		var dist := mob.global_position.distance_to(target.global_position)
		var attack_range: float = float(mob.attack_range)
		var effective_range := attack_range + 20.0
		if mob.has_method("is_combo_ready") and mob.is_combo_ready() and dist <= effective_range:
			state_machine.change_state("HomeseekerComboState")
			return
		if dist <= effective_range:
			state_machine.change_state("HomeseekerAttackState")
			return
	else:
		_move_target = _get_wall_position()
		var dist_to_wall := mob.global_position.distance_to(_move_target)
		if dist_to_wall <= 18.0:
			state_machine.change_state("HomeseekerIdleState")

func _get_wall_position() -> Vector2:
	var wall_pos := Vector2(600, 550)
	if mob and mob.has_method("get_wall_position"):
		wall_pos = mob.get_wall_position()
	return wall_pos
