extends "res://scripts/hero/states/HeroState.gd"

## Состояние: возвращение к мосту
## Заменяет компонент HeroGoHome

var _bridge_pos: Vector2 = Vector2.ZERO
var _reached_bridge: bool = false

func enter() -> void:
    if not hero:
        if state_machine: hero = state_machine._get_hero()
        if not hero: return
    
    hero.release_current_slot()
    hero.current_target = null
    hero.is_returning = true
    _reached_bridge = false
    
    var marker_service := _get_map_marker_service()
    if marker_service and marker_service.has_method("get_bridge_position"):
        _bridge_pos = marker_service.get_bridge_position()
    else:
        _bridge_pos = Vector2.ZERO
    
    if hero.has_method("_update_animation"):
        hero._update_animation("walk")

func update(_delta: float) -> void:
    if not hero or hero.is_dead: return
    
    # Check if hero is orphaned (not in HeroCore anymore)
    if _is_hero_orphaned():
        print("[HeroReturningHomeState] %s is orphaned - removing" % hero.hero_id)
        hero.queue_free()
        return
    
    var dist = hero.global_position.distance_to(_bridge_pos)
    if dist < 60.0:
        _reached_bridge = true
        _despawn()
        return

func physics_update(_delta: float) -> void:
    if not hero or _reached_bridge: return

    # Direct physics movement to bridge
    var direction = (_bridge_pos - hero.global_position).normalized()
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

func _despawn() -> void:
    var hero_core := _get_hero_core()
    if hero_core and hero and hero_core.has_method("remove_from_squad"):
        hero_core.remove_from_squad(hero.hero_id)
    hero.queue_free()

func exit() -> void:
    if hero:
        hero.is_returning = false
        hero.velocity = Vector2.ZERO
