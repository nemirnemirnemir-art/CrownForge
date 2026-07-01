extends "res://scripts/hero/states/HeroState.gd"

## Save From Stack State
## Makes the hero move in a random direction to get unstuck

var move_timer: float = 0.0
var random_dir: Vector2 = Vector2.ZERO

func enter() -> void:
    move_timer = 0.5 # Quick nudge instead of long run
    var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, 
                Vector2(1,1).normalized(), Vector2(1,-1).normalized(),
                Vector2(-1,1).normalized(), Vector2(-1,-1).normalized()]
    random_dir = dirs[randi() % dirs.size()]
    
    if hero.has_method("stop_navigation"):
        hero.stop_navigation()
    
    if hero.has_method("_update_animation"):
        hero._update_animation("walk")
        
    # print("[HeroSaveFromStack] 🆘 Hero %s trying to get unstuck, dir=%s" % [hero.hero_id, random_dir])

func update(delta: float) -> void:
    if not hero:
        return

    move_timer -= delta
    var move_speed := float(hero.move_speed)
    if "speed_multiplier" in hero:
        move_speed *= maxf(0.0, float(hero.speed_multiplier))
    hero.velocity = random_dir * move_speed
    hero.move_and_slide()
    
    if hero.has_method("enforce_battlefield_bounds"):
        var bounced_direction: Vector2 = hero.enforce_battlefield_bounds(random_dir)
        if bounced_direction != random_dir and bounced_direction != Vector2.ZERO:
            hero.velocity = bounced_direction * move_speed
    
    # Simple flip logic while moving
    if abs(random_dir.x) > 0.1:
        hero.scale.x = abs(hero.scale.x) * (-1.0 if random_dir.x < 0 else 1.0)
    
    if move_timer <= 0:
        state_machine.change_state("HeroIdleState")

func exit() -> void:
    if hero:
        hero.velocity = Vector2.ZERO
