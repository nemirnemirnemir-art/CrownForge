extends "res://scripts/mob/states/MobState.gd"

## Mob Moving To Wall State (Refactored - Physics)
## Direct movement towards wall, attack when in range

var _wall_target: Node2D = null
var _wall_position: Vector2 = Vector2.ZERO
var _wall_approach_position: Vector2 = Vector2.ZERO
const WALL_ATTACK_RANGE_MELEE: float = 170.0
const WALL_ATTACK_RANGE_RANGED: float = 320.0
const WALL_STOP_BUFFER: float = 20.0
const WALL_STOP_EPSILON: float = 4.0
const WALL_VISUAL_STOP_OFFSET_X: float = 200.0
const WALL_APPROACH_TOLERANCE: float = 4.0

func _get_wall_approach_offset_x() -> float:
    if mob and mob.has_method("get_wall_attack_stand_off"):
        return float(mob.get_wall_attack_stand_off(WALL_STOP_BUFFER))
    var attack_range := _get_wall_attack_range()
    return maxf(0.0, minf(WALL_VISUAL_STOP_OFFSET_X, attack_range - WALL_STOP_BUFFER))

func _get_wall_attack_range() -> float:
    if mob and mob.has_method("get_wall_attack_trigger_distance"):
        return float(mob.get_wall_attack_trigger_distance(WALL_STOP_BUFFER))
    if mob and mob.has_method("get_wall_attack_range"):
        return float(mob.get_wall_attack_range())
    if mob and ("projectile_scene" in mob) and mob.projectile_scene:
        return WALL_ATTACK_RANGE_RANGED
    return WALL_ATTACK_RANGE_MELEE

func _refresh_wall_positions() -> void:
    if mob and mob.has_method("get_wall_contact_position"):
        _wall_position = mob.get_wall_contact_position()
    elif _wall_target and is_instance_valid(_wall_target):
        _wall_position = _wall_target.global_position

    if mob and mob.has_method("get_wall_approach_position"):
        _wall_approach_position = mob.get_wall_approach_position(WALL_STOP_BUFFER)
    else:
        _wall_approach_position = _wall_position + Vector2(_get_wall_approach_offset_x(), 0.0)

func enter() -> void:
    if not mob: return
    _wall_target = mob.get_wall_target_node() if mob.has_method("get_wall_target_node") else null
    
    if not _wall_target:
        if state_machine: state_machine.change_state("MobMoveState")
        return
    
    _refresh_wall_positions()
    
    if mob.animations:
        mob.animations.play_walk()

func update(delta: float) -> void:
    if not mob or not state_machine: return
    if mob.is_dead:
        state_machine.change_state("MobDeathState")
        return
    if not _wall_target or not is_instance_valid(_wall_target):
        state_machine.change_state("MobMoveState")
        return

    _refresh_wall_positions()
    
    # Priority: attack hero if in range
    if mob.combat:
        var hero = mob.combat.find_nearest_hero()
        if hero and mob.combat.is_in_attack_range(hero):
            mob.combat._combat_target = hero
            state_machine.change_state("MobAttackState")
            return
    
    var distance_to_wall: float = mob.get_distance_to_wall() if mob.has_method("get_distance_to_wall") else mob.global_position.distance_to(_wall_target.global_position)
    if distance_to_wall <= _get_wall_attack_range() + WALL_STOP_EPSILON:
        state_machine.change_state("MobAttackWallState")
        return

    var distance_to_approach = mob.global_position.distance_to(_wall_approach_position)
    if distance_to_approach <= WALL_APPROACH_TOLERANCE:
        state_machine.change_state("MobAttackWallState")
        return
    
    # If mob reached left edge of bounds, start attacking wall from there
    if mob.has_method("is_at_left_bounds_edge") and mob.is_at_left_bounds_edge(50.0):
        state_machine.change_state("MobAttackWallState")
        return

func physics_update(delta: float) -> void:
    if not mob: return
    _refresh_wall_positions()
    
    if _wall_target and is_instance_valid(_wall_target):
        var distance_to_wall: float = mob.get_distance_to_wall() if mob.has_method("get_distance_to_wall") else mob.global_position.distance_to(_wall_target.global_position)
        if distance_to_wall <= _get_wall_attack_range() + WALL_STOP_EPSILON:
            mob.velocity = Vector2.ZERO
            return

    var to_approach := _wall_approach_position - mob.global_position
    if to_approach.length() <= WALL_APPROACH_TOLERANCE:
        mob.velocity = Vector2.ZERO
        return
    var direction = to_approach.normalized()
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

func exit() -> void:
    if mob: mob.velocity = Vector2.ZERO
    _wall_target = null
