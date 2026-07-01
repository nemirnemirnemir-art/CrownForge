extends "res://scripts/mob/states/MobState.gd"

## Mob Move State (Refactored - Physics)
## Direct movement towards heroes or wall. Searches for targets frequently.
const ATTACK_TOLERANCE: float = 20.0  ## Unified buffer for attack range checks

var _search_timer: float = 0.0
const SEARCH_INTERVAL: float = 0.5

# Movement target (hero or wall)
var _move_target: Vector2 = Vector2.ZERO

func enter() -> void:
    if mob and mob.has_method("play_anim"):
        mob.play_anim("walk")
    _search_timer = 0.0
    _move_target = _get_wall_position()

func update(delta: float) -> void:
    if not mob or not state_machine: return
    
    if mob.get("is_dead") == true:
        state_machine.change_state("MobDeathState")
        return
    
    # Throttled hero search
    _search_timer -= delta
    if _search_timer <= 0:
        _search_timer = SEARCH_INTERVAL
        _search_for_heroes()
    
    # Range checks (logic only)
    if _move_target != Vector2.ZERO:
        var dist_to_wall = mob.global_position.distance_to(_move_target)
        var wall_approach_distance: float = 125.0
        if mob and ("projectile_scene" in mob) and mob.projectile_scene:
            wall_approach_distance = 320.0
        # For melee mobs, use the configured wall attack stand-off if available
        if mob and mob.has_method("get_wall_attack_stand_off"):
            var configured_stand_off: float = float(mob.get_wall_attack_stand_off())
            if configured_stand_off > 0.0:
                wall_approach_distance = maxf(configured_stand_off, wall_approach_distance)
        # If targeting wall and close enough
        if _move_target == _get_wall_position() and dist_to_wall < wall_approach_distance:
            state_machine.change_state("MobMovingToWallState")

func physics_update(delta: float) -> void:
    if not mob or _move_target == Vector2.ZERO: return
    
    # Physics-based movement
    var direction = (_move_target - mob.global_position).normalized()
    var move_speed: float = mob.get_effective_move_speed() if mob.has_method("get_effective_move_speed") else float(mob.move_speed)
    mob.velocity = direction * move_speed
    mob.move_and_slide()
    if mob.has_method("enforce_battlefield_bounds"):
        var bounced_direction: Vector2 = mob.enforce_battlefield_bounds(direction)
        if bounced_direction != direction and bounced_direction != Vector2.ZERO:
            mob.velocity = bounced_direction * move_speed
    
    # Face direction - use flip_h on sprite instead of scale to avoid flickering
    # Only flip when direction change is significant (threshold 0.3)
    if abs(direction.x) > 0.3:
        var should_flip = mob.get_should_flip_for_direction(direction.x)
        if mob.anim_walk:
            mob.anim_walk.flip_h = should_flip
        if mob.anim_attack:
            mob.anim_attack.flip_h = should_flip
        if mob.animation_sprite:
            mob.animation_sprite.flip_h = should_flip

func exit() -> void:
    if mob: mob.velocity = Vector2.ZERO

func _search_for_heroes() -> void:
    # For Shaman: check if allies need healing first
    if _is_healer_mob() and _has_damaged_allies():
        state_machine.change_state("MobHealState")
        return
    
    var aggro_range: float = 300.0
    if mob.combat and "aggro_range" in mob.combat:
        aggro_range = mob.combat.aggro_range
    
    var target = CombatTargetFinder.find_nearest(mob, "hero", aggro_range)
    
    if target and is_instance_valid(target):
        if mob.combat:
            mob.combat._combat_target = target
        _move_target = target.global_position
        
        var dist := mob.global_position.distance_to(target.global_position)
        var attack_range: float = 50.0
        if mob.combat:
            attack_range = float(mob.combat.attack_range)
        var effective_range = attack_range + ATTACK_TOLERANCE
        
        if dist <= effective_range:
            state_machine.change_state(_get_attack_state_name())
    else:
        if mob.combat: mob.combat.clear_combat_target()
        _move_target = _get_wall_position()

func _is_healer_mob() -> bool:
    return "shaman" in mob.name.to_lower() or "Shaman" in mob.name

func _has_damaged_allies() -> bool:
    var all_mobs = get_tree().get_nodes_in_group("enemy")
    for ally in all_mobs:
        if not is_instance_valid(ally) or ally == mob:
            continue
        if ally.get("projectile_scene") != null:
            continue  # Skip ranged mobs
        var current_hp = ally.current_health if "current_health" in ally else 0
        var max_hp = ally.max_health if "max_health" in ally else 1
        if current_hp < max_hp:
            var dist = mob.global_position.distance_to(ally.global_position)
            if dist <= 200.0:  # Heal range
                return true
    return false

func _get_wall_position() -> Vector2:
    var wall_pos := Vector2(600, 550)
    if mob.has_method("get_wall_position"):
        wall_pos = mob.get_wall_position()
    return wall_pos

func _get_attack_state_name() -> String:
    if mob.has_method("get_attack_state_name"):
        return mob.get_attack_state_name()
    return "MobAttackState"
