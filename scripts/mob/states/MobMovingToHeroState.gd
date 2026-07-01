extends "res://scripts/mob/states/MobState.gd"

## Mob moves towards a hero to attack
## Clear goal: Get in attack range of hero

var _repath_timer: float = 0.0
const REPATH_INTERVAL: float = 0.3

func enter() -> void:
	if not mob:
		return
	
	if mob.animations:
		mob.animations.play_walk()
	
	_update_navigation()

func update(delta: float) -> void:
	if not mob or not state_machine:
		return
	
	if mob.is_dead:
		state_machine.change_state("MobDeathState")
		return
	
	var hero = mob.combat.update_combat_target() if mob.combat else null
	
	if not hero or not is_instance_valid(hero):
		# Hero lost - continue to wall
		state_machine.change_state("MobMovingToWallState")
		return
	
	if mob.combat and mob.combat.is_in_attack_range(hero):
		state_machine.change_state("MobAttackState")
		return
	
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_update_navigation()
		_repath_timer = REPATH_INTERVAL

func physics_update(delta: float) -> void:
	if not mob or not mob.combat: return
	
	var hero = mob.combat.get_combat_target()
	if hero and is_instance_valid(hero):
		var direction = (hero.global_position - mob.global_position).normalized()
		var move_speed: float = mob.get_effective_move_speed() if mob.has_method("get_effective_move_speed") else float(mob.move_speed)
		mob.velocity = direction * move_speed
		mob.move_and_slide()
		if mob.has_method("enforce_battlefield_bounds"):
			var bounced_direction: Vector2 = mob.enforce_battlefield_bounds(direction)
			if bounced_direction != direction and bounced_direction != Vector2.ZERO:
				mob.velocity = bounced_direction * move_speed
		
		# Face direction - use flip_h on sprite instead of scale to avoid flickering
		if abs(direction.x) > 0.3:
			var should_flip = mob.get_should_flip_for_direction(direction.x)
			if mob.anim_walk:
				mob.anim_walk.flip_h = should_flip
			if mob.anim_attack:
				mob.anim_attack.flip_h = should_flip
			if mob.animation_sprite:
				mob.animation_sprite.flip_h = should_flip

func _update_navigation() -> void:
	# Legacy navigation removed - using direct physics movement now
	pass

func exit() -> void:
	pass
