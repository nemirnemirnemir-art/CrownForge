extends Node2D

## Visual targeting circle for spells

@export var radius: float = 100.0
@export var color: Color = Color(0.2, 1.0, 0.2, 0.4)  # Semi-transparent green
@export var outline_width: float = 3.0

@export var shape_mode: String = "circle"  # circle | rect
@export var rect_size: Vector2 = Vector2(50.0, 300.0)

var _circle_polygon: Polygon2D

func _ready() -> void:
    _create_circle()

func _create_circle() -> void:
    if _circle_polygon:
        _circle_polygon.queue_free()
    
    _circle_polygon = Polygon2D.new()
    _circle_polygon.color = color
    add_child(_circle_polygon)
    
    _update_circle_shape()

func _update_circle_shape() -> void:
    if not _circle_polygon:
        return

    if shape_mode == "rect":
        var half := rect_size * 0.5
        var points_rect: PackedVector2Array = PackedVector2Array()
        points_rect.append(Vector2(-half.x, -half.y))
        points_rect.append(Vector2(half.x, -half.y))
        points_rect.append(Vector2(half.x, half.y))
        points_rect.append(Vector2(-half.x, half.y))
        _circle_polygon.polygon = points_rect
        return
    
    var points: PackedVector2Array = PackedVector2Array()
    var segments: int = 64
    
    for i in range(segments + 1):
        var angle: float = TAU * float(i) / float(segments)
        var point := Vector2(cos(angle), sin(angle)) * radius
        points.append(point)
    
    _circle_polygon.polygon = points

func set_radius(new_radius: float) -> void:
    shape_mode = "circle"
    radius = new_radius
    _update_circle_shape()

func set_rect_size(new_size: Vector2) -> void:
    shape_mode = "rect"
    rect_size = new_size
    _update_circle_shape()
