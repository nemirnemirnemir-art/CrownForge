extends "res://scripts/hero/states/HeroState.gd"

## State: Hero retreats from battlefield bounds for a few seconds
## Triggered when hero touches the edge of BattlefieldBounds2D

const RETREAT_DURATION: float = 2.0
const RETREAT_SPEED_MULTIPLIER: float = 0.6

var _retreat_timer: float = 0.0
var _retreat_direction: Vector2 = Vector2.ZERO

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
	_update_facing(_retreat_direction)

func exit() -> void:
	if hero:
		hero.velocity = Vector2.ZERO

func _finish_retreat() -> void:
	if not hero or not state_machine:
		return
	
	# Check if we have a combat target
	var target = hero.get_current_target()
	if target and is_instance_valid(target) and not _is_target_dead(target):
		state_machine.change_state("HeroMovingToCombatState")
		return
	
	# Otherwise go idle
	hero.set_current_target(null)
	state_machine.change_state("HeroIdleState")

func _compute_retreat_direction() -> Vector2:
	if not hero:
		return Vector2.RIGHT
	
	# Get map bounds and compute direction toward center
	var bounds: Rect2 = Rect2()
	if hero.has_method("get_map_bounds"):
		bounds = hero.get_map_bounds()
	elif "map_bounds" in hero:
		bounds = hero.map_bounds
	
	if bounds.size == Vector2.ZERO:
		# No bounds, retreat toward bridge/wall
		var marker_service := _get_map_marker_service()
		if marker_service and marker_service.has_method("get_bridge_position"):
			var bridge_pos: Vector2 = marker_service.get_bridge_position()
			return (bridge_pos - hero.global_position).normalized()
		return Vector2.LEFT
	
	var center := bounds.get_center()
	var dir := (center - hero.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	return dir

func _is_target_dead(target) -> bool:
	if target == null or not is_instance_valid(target):
		return true
	if "is_dead" in target and bool(target.is_dead):
		return true
	return false

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
