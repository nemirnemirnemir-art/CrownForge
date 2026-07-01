extends "res://scripts/hero/states/HeroState.gd"

const RETREAT_DURATION: float = 2.0
const RETREAT_SPEED_MULTIPLIER: float = 1.2

var _retreat_timer: float = 0.0
var _retreat_direction: Vector2 = Vector2.LEFT

func enter() -> void:
	if not hero:
		if state_machine:
			hero = state_machine._get_hero()
		if not hero:
			return

	_retreat_timer = RETREAT_DURATION
	_retreat_direction = _compute_retreat_direction()
	hero.velocity = Vector2.ZERO

	if hero.has_method("_update_animation"):
		hero._update_animation("walk")

func update(delta: float) -> void:
	if not hero or hero.is_dead:
		return

	if _is_hero_orphaned():
		print("[HeroHitAndRunRetreatState] %s is orphaned - removing" % hero.hero_id)
		hero.queue_free()
		return

	_retreat_timer -= delta
	if _retreat_timer <= 0.0:
		_finish_retreat()

func physics_update(_delta: float) -> void:
	if not hero or hero.is_dead:
		return

	var speed: float = float(hero.move_speed) * RETREAT_SPEED_MULTIPLIER
	if "speed_multiplier" in hero:
		speed *= maxf(0.0, float(hero.speed_multiplier))
	hero.velocity = _retreat_direction * speed
	hero.move_and_slide()
	if hero.has_method("enforce_battlefield_bounds"):
		var bounced_direction: Vector2 = hero.enforce_battlefield_bounds(_retreat_direction)
		if bounced_direction != _retreat_direction and bounced_direction != Vector2.ZERO:
			hero.velocity = bounced_direction * speed
	_update_facing(_retreat_direction)

func exit() -> void:
	if hero:
		hero.velocity = Vector2.ZERO

func _finish_retreat() -> void:
	if not hero or not state_machine:
		return

	var target = hero.get_current_target()
	if _is_valid_target(target):
		state_machine.change_state("HeroMovingToCombatState")
		return

	hero.set_current_target(null)
	state_machine.change_state("HeroIdleState")

func _compute_retreat_direction() -> Vector2:
	if not hero:
		return Vector2.LEFT

	var anchor := Vector2.ZERO
	var marker_service := _get_map_marker_service()
	if marker_service:
		if marker_service.has_method("get_wall_position"):
			anchor = marker_service.get_wall_position()
		if anchor == Vector2.ZERO and marker_service.has_method("get_bridge_position"):
			anchor = marker_service.get_bridge_position()

	if anchor == Vector2.ZERO:
		return Vector2.LEFT

	var dir := (anchor - hero.global_position).normalized()
	if dir == Vector2.ZERO:
		return Vector2.LEFT

	return dir

func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) <= 0.3:
		return

	var should_flip := direction.x < 0
	var walk_sprite = hero.get_node_or_null("AnimWalk")
	var attack_sprite = hero.get_node_or_null("AnimAttack")
	if walk_sprite:
		walk_sprite.flip_h = should_flip
	if attack_sprite:
		attack_sprite.flip_h = should_flip
	if hero.animation_sprite:
		hero.animation_sprite.flip_h = should_flip

func _is_valid_target(target) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if "is_dead" in target and bool(target.is_dead):
		return false
	return true
