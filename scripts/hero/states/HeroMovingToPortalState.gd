extends "res://scripts/hero/states/HeroState.gd"

## Состояние: движение к порталу и поиск мобов
## Заменяет компонент HeroGoals

var _portal_pos: Vector2 = Vector2.ZERO
var _reached_portal: bool = false
var _check_mob_timer: float = 0.0

func enter() -> void:
	if not hero:
		if state_machine: hero = state_machine._get_hero()
		if not hero: return
	
	var marker_service := _get_map_marker_service()
	if marker_service and marker_service.has_method("get_portal_position"):
		_portal_pos = marker_service.get_portal_position()
	else:
		_portal_pos = Vector2.ZERO
	
	if hero.has_method("_update_animation"):
		hero._update_animation("walk")
	
	_reached_portal = false
	_check_mob_timer = 0.0

func update(delta: float) -> void:
	if not hero or hero.is_dead:
		return
	
	# Check if hero is orphaned (not in HeroCore anymore)
	if _is_hero_orphaned():
		print("[HeroMovingToPortalState] %s is orphaned - removing" % hero.hero_id)
		hero.queue_free()
		return
	
	_check_mob_timer -= delta
	if _check_mob_timer <= 0.0:
		_check_mob_timer = 0.2
		if not _is_passive_patroller() and _check_for_mobs():
			return
	
	var dist = hero.global_position.distance_to(_portal_pos)
	if dist < 80.0:
		_reached_portal = true
		state_machine.change_state("HeroReturningHomeState")
		return

func physics_update(delta: float) -> void:
	if not hero or _reached_portal: return
	
	# Direct physics movement to portal
	var direction = (_portal_pos - hero.global_position).normalized()
	var move_speed := float(hero.move_speed)
	if "speed_multiplier" in hero:
		move_speed *= maxf(0.0, float(hero.speed_multiplier))
	hero.velocity = direction * move_speed
	hero.move_and_slide()
	if hero.has_method("enforce_battlefield_bounds"):
		var bounced_direction: Vector2 = hero.enforce_battlefield_bounds(direction)
		if bounced_direction != direction and bounced_direction != Vector2.ZERO:
			hero.velocity = bounced_direction * move_speed
	
	# Face direction - use flip_h on sprite instead of scale to avoid flickering
	if abs(direction.x) > 0.3:
		var should_flip = direction.x < 0
		var walk_sprite = hero.get_node_or_null("AnimWalk")
		var attack_sprite = hero.get_node_or_null("AnimAttack")
		if walk_sprite:
			walk_sprite.flip_h = should_flip
		if attack_sprite:
			attack_sprite.flip_h = should_flip
		if hero.animation_sprite:
			hero.animation_sprite.flip_h = should_flip

func _check_for_mobs() -> bool:
	if _is_passive_patroller():
		return false

	var aggro = hero.get_node_or_null("AggroArea")
	if not aggro: return false
	
	var candidates = aggro.get_targets()
	if candidates.is_empty(): return false
	
	var hero_pos = hero.global_position
	candidates.sort_custom(func(a, b):
		return hero_pos.distance_squared_to(a.global_position) < hero_pos.distance_squared_to(b.global_position)
	)
	
	for cand in candidates:
		if _try_reserve(cand):
			hero.set_current_target(cand)
			state_machine.change_state("HeroMovingToCombatState")
			return true
	
	return false

func _is_passive_patroller() -> bool:
	return hero and hero.has_method("is_passive_patroller") and hero.is_passive_patroller()

func _try_reserve(mob: Node2D) -> bool:
	if not is_instance_valid(mob): return false
	if hero.has_method("_is_target_dead") and hero._is_target_dead(mob): return false
	
	if mob.has_method("reserve_slot"):
		return mob.reserve_slot(hero.hero_id)
	return true

func exit() -> void:
	if hero: hero.velocity = Vector2.ZERO
