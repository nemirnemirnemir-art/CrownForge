extends RefCounted
class_name HeroOnFieldMovement

## Handles movement logic and stuck detection for HeroOnField

var hero: Node2D
var _debug: HeroOnFieldDebug # Debug helper reference for stuck detection

@export var move_speed: float = 37.5 
var stop_tolerance: float = 10.0
var bridge_position: Vector2 = Vector2.ZERO
var is_returning: bool = false
var patrol_center: Vector2 = Vector2.ZERO
var patrol_box_size: Vector2 = Vector2(150.0, 300.0)
var map_bounds: Rect2 = Rect2()

const MELEE_OVER_RANGED_SPEED_RATIO: float = 1.15
const BOUNDS_EDGE_MARGIN: float = 14.0

func setup(hero_ref: Node2D, debug_module: HeroOnFieldDebug) -> void:
    hero = hero_ref
    _debug = debug_module

func apply_speed_modifiers(stats: HeroOnFieldStats, is_melee: bool, override_move_speed: float) -> void:
    if override_move_speed > 0:
        move_speed = override_move_speed
        
    if stats and not is_melee:
        move_speed = float(move_speed) / MELEE_OVER_RANGED_SPEED_RATIO

func get_adjusted_speed(speed_multiplier: float) -> float:
    return move_speed * speed_multiplier

func set_map_bounds(bounds: Rect2) -> void:
    map_bounds = bounds

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
