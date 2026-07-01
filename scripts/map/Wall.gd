extends Area2D
class_name Wall

const WallGeometryScript := preload("res://scripts/map/WallGeometry.gd")

@export var max_health: int = 100
var current_health: int = 100
var is_destroyed: bool = false

const HP_PER_UI_POINT: int = 20
var max_health_internal: float = 2000.0
var current_health_internal: float = 2000.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _wall_geometry = WallGeometryScript.new()

signal wall_damaged(damage: int, current_hp: int, max_hp: int)
signal wall_destroyed()

func _ready() -> void:
    current_health = max_health
    max_health_internal = maxf(1.0, float(max_health) * float(HP_PER_UI_POINT))
    current_health_internal = max_health_internal
    is_destroyed = false
    # print("[Wall] Wall initialized with %d HP" % max_health)

func take_damage(damage: float) -> void:
    if is_destroyed: return

    var safe_damage_internal: float = maxf(0.0, damage)

    current_health_internal -= safe_damage_internal
    current_health_internal = maxf(0.0, current_health_internal)
    current_health = int(ceili(current_health_internal / float(HP_PER_UI_POINT)))
    current_health = clampi(current_health, 0, max_health)

    var ui_damage: int = 0
    if safe_damage_internal > 0.0:
        ui_damage = int(ceili(safe_damage_internal / float(HP_PER_UI_POINT)))
    
    var castle_core := _get_castle_core()
    if ui_damage > 0 and castle_core and castle_core.has_method("take_damage"):
        castle_core.take_damage(ui_damage)
    
    wall_damaged.emit(ui_damage, current_health, max_health)
    
    if current_health_internal <= 0:
        _on_wall_destroyed()

func _on_wall_destroyed() -> void:
    if is_destroyed: return
    is_destroyed = true
    wall_destroyed.emit()
    # print("[Wall] Wall destroyed!")


func get_world_rect() -> Rect2:
    if collision_shape == null:
        return Rect2(global_position, Vector2.ZERO)
    var rect_shape := collision_shape.shape as RectangleShape2D
    if rect_shape == null:
        return Rect2(collision_shape.global_position, Vector2.ZERO)
    var scale := collision_shape.global_transform.get_scale().abs()
    var size := rect_shape.size * scale
    var center := collision_shape.global_position
    return Rect2(center - size * 0.5, size)


func get_lane_contact_point(world_y: float) -> Vector2:
    return _wall_geometry.get_lane_contact_point(get_world_rect(), world_y)


func get_lane_approach_point(world_y: float, stand_off_distance: float) -> Vector2:
    return _wall_geometry.get_lane_approach_point(get_world_rect(), world_y, stand_off_distance)


func get_distance_to_point(world_position: Vector2) -> float:
    return _wall_geometry.get_distance_to_rect(get_world_rect(), world_position)


func _get_castle_core() -> Node:
    var tree := get_tree()
    if tree == null or tree.root == null:
        return null
    return tree.root.get_node_or_null("CastleCore")
