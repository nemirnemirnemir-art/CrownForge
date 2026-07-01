extends RefCounted
class_name MobMovement

## Handles state related to moving, getting stuck, and bounds checking for Mob

var mob: Node2D

var target_position: Vector2 = Vector2.ZERO
var move_direction: Vector2 = Vector2.ZERO
var behavior_target_type: String = "portal"
var center_position: Vector2 = Vector2(1000, 1000)
var bridge_position: Vector2 = Vector2(400, 1000)
var portal_position: Vector2 = Vector2.ZERO
var map_bounds: Rect2 = Rect2(0, 0, 500, 500)
const BOUNDS_EDGE_MARGIN: float = 14.0
var wall_attack_stop_distance_override: float = -1.0

var wander_target: Vector2 = Vector2.ZERO

var last_stuck_pos: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0

func setup(mob_ref: Node2D) -> void:
    mob = mob_ref

func set_map_bounds(bounds: Rect2) -> void:
    map_bounds = bounds

func set_wall_attack_stop_distance(distance: float) -> void:
    wall_attack_stop_distance_override = maxf(0.0, distance)

func get_wall_attack_stop_distance_override() -> float:
    return wall_attack_stop_distance_override

func get_should_flip_for_direction(direction_x: float, invert_visual_facing: bool) -> bool:
    var should_flip: bool = direction_x < 0.0
    if invert_visual_facing:
        should_flip = not should_flip
    return should_flip

func get_bounce_direction(world_position: Vector2, desired_direction: Vector2) -> Vector2:
    if map_bounds.size == Vector2.ZERO:
        return desired_direction
    var next_direction := desired_direction
    if world_position.x <= map_bounds.position.x + BOUNDS_EDGE_MARGIN and desired_direction.x < 0.0:
        next_direction.x = absf(desired_direction.x)
    elif world_position.x >= map_bounds.end.x - BOUNDS_EDGE_MARGIN and desired_direction.x > 0.0:
        next_direction.x = -absf(desired_direction.x)
    if world_position.y <= map_bounds.position.y + BOUNDS_EDGE_MARGIN and desired_direction.y < 0.0:
        next_direction.y = absf(desired_direction.y)
    elif world_position.y >= map_bounds.end.y - BOUNDS_EDGE_MARGIN and desired_direction.y > 0.0:
        next_direction.y = -absf(desired_direction.y)
    if next_direction == Vector2.ZERO:
        return next_direction
    return next_direction.normalized()

func check_stuck(current_hp: float, last_hp: float, total_damage_dealt: float, last_damage_dealt: float) -> bool:
    var moved = mob.global_position.distance_to(last_stuck_pos)
    var hp_changed = not is_equal_approx(current_hp, last_hp)
    var dmg_changed = not is_equal_approx(total_damage_dealt, last_damage_dealt)
    
    var is_stuck = false
    if moved < 10.0 and not hp_changed and not dmg_changed:
        stuck_timer += 1.0
        if stuck_timer >= 5.0:
            stuck_timer = 0.0
            is_stuck = true
    else:
        stuck_timer = 0.0
        
    last_stuck_pos = mob.global_position
    return is_stuck


## Clamps mob to map bounds, zeroes velocity, and returns a bounce direction
## if the mob was outside. Returns desired_direction unchanged if in bounds.
func enforce_battlefield_bounds(mob_ref: Node2D, desired_direction: Vector2) -> Vector2:
    if map_bounds.size == Vector2.ZERO:
        return desired_direction
    var clamped := Vector2(
        clampf(mob_ref.global_position.x, map_bounds.position.x, map_bounds.end.x),
        clampf(mob_ref.global_position.y, map_bounds.position.y, map_bounds.end.y)
    )
    if clamped.is_equal_approx(mob_ref.global_position):
        return desired_direction
    mob_ref.global_position = clamped
    mob_ref.velocity = Vector2.ZERO
    return get_bounce_direction(clamped, desired_direction)
