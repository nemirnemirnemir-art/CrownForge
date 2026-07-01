@tool
extends Area2D
class_name BattlefieldBounds2D

@export var show_debug_fill: bool = true:
	set(value):
		show_debug_fill = value
		queue_redraw()

@export var fill_color: Color = Color(0.15, 0.7, 1.0, 0.08):
	set(value):
		fill_color = value
		queue_redraw()

@export var outline_color: Color = Color(0.2, 0.85, 1.0, 0.9):
	set(value):
		outline_color = value
		queue_redraw()

@export var edge_margin: float = 16.0

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D

func _ready() -> void:
	monitoring = false
	monitorable = false
	input_pickable = false
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

func _draw() -> void:
	var local_rect := get_local_rect()
	if local_rect.size == Vector2.ZERO:
		return
	if show_debug_fill:
		draw_rect(local_rect, fill_color, true)
	draw_rect(local_rect, outline_color, false, 3.0)

func get_local_rect() -> Rect2:
	if collision_shape == null:
		return Rect2()
	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2()
	var size := rect_shape.size * collision_shape.scale.abs()
	var center := collision_shape.position
	return Rect2(center - size * 0.5, size)

func get_world_rect() -> Rect2:
	var local_rect := get_local_rect()
	if local_rect.size == Vector2.ZERO:
		return Rect2(global_position, Vector2.ZERO)
	var top_left := to_global(local_rect.position)
	var bottom_right := to_global(local_rect.position + local_rect.size)
	return Rect2(top_left, bottom_right - top_left)

func clamp_world_position(world_position: Vector2) -> Vector2:
	var rect := get_world_rect()
	if rect.size == Vector2.ZERO:
		return world_position
	return Vector2(
		clampf(world_position.x, rect.position.x, rect.end.x),
		clampf(world_position.y, rect.position.y, rect.end.y)
	)

func get_bounce_direction(world_position: Vector2, desired_direction: Vector2) -> Vector2:
	var rect := get_world_rect()
	if rect.size == Vector2.ZERO:
		return desired_direction
	var next_direction := desired_direction
	if world_position.x <= rect.position.x + edge_margin and desired_direction.x < 0.0:
		next_direction.x = absf(desired_direction.x)
	elif world_position.x >= rect.end.x - edge_margin and desired_direction.x > 0.0:
		next_direction.x = -absf(desired_direction.x)
	if world_position.y <= rect.position.y + edge_margin and desired_direction.y < 0.0:
		next_direction.y = absf(desired_direction.y)
	elif world_position.y >= rect.end.y - edge_margin and desired_direction.y > 0.0:
		next_direction.y = -absf(desired_direction.y)
	if next_direction == Vector2.ZERO:
		return next_direction
	return next_direction.normalized()

func contains_world_position(world_position: Vector2) -> bool:
	return get_world_rect().has_point(world_position)
