extends Node2D

@onready var _projectile_sprite: Sprite2D = $ProjectileSprite
@onready var _projectile_body: Polygon2D = $ProjectileBody

var _travel := Vector2.ZERO
var _start_position := Vector2.ZERO
var _travel_duration: float = 0.16
var _impact_duration: float = 0.08
var _elapsed: float = 0.0
var _projectile_kind: StringName = &""
var _active_node: CanvasItem = null
var _travel_duration_scale: float = 1.0


func launch_arrow(start_pos: Vector2, end_pos: Vector2, speed: float, tint: Color = Color.WHITE, travel_duration_scale: float = 1.0) -> void:
	_start_position = start_pos
	global_position = start_pos
	_travel = end_pos - start_pos
	_projectile_kind = &"arrow"
	_elapsed = 0.0
	_travel_duration_scale = maxf(travel_duration_scale, 0.01)
	_active_node = _projectile_sprite
	_projectile_sprite.visible = true
	_projectile_sprite.modulate = tint
	_projectile_sprite.rotation = _travel.angle()
	_projectile_body.visible = false
	_configure_duration(speed)


func launch_cannonball(start_pos: Vector2, end_pos: Vector2, speed: float, tint: Color = Color(0.08, 0.08, 0.1, 1.0), travel_duration_scale: float = 1.0) -> void:
	_start_position = start_pos
	global_position = start_pos
	_travel = end_pos - start_pos
	_projectile_kind = &"cannonball"
	_elapsed = 0.0
	_travel_duration_scale = maxf(travel_duration_scale, 0.01)
	_active_node = _projectile_body
	_projectile_body.visible = true
	_projectile_body.color = tint
	_projectile_sprite.visible = false
	_configure_duration(speed)


func get_projectile_kind() -> StringName:
	return _projectile_kind


func _configure_duration(speed: float) -> void:
	var distance := _travel.length()
	if speed > 0.0:
		_travel_duration = clampf(distance / speed, 0.05, 0.22) * _travel_duration_scale
	else:
		_travel_duration = 0.12 * _travel_duration_scale
	_impact_duration = 0.08
	_update_visual(0.0)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _travel_duration + _impact_duration:
		queue_free()
		return

	if _elapsed <= _travel_duration:
		var progress := 0.0
		if _travel_duration > 0.0:
			progress = clampf(_elapsed / _travel_duration, 0.0, 1.0)
		_update_visual(progress)
		return

	var impact_progress := 0.0
	if _impact_duration > 0.0:
		impact_progress = clampf((_elapsed - _travel_duration) / _impact_duration, 0.0, 1.0)
	_update_impact(impact_progress)


func _update_visual(progress: float) -> void:
	global_position = _start_position + _travel * progress
	if _active_node == null:
		return
	_active_node.modulate.a = 1.0
	_active_node.scale = Vector2.ONE


func _update_impact(progress: float) -> void:
	global_position = _start_position + _travel
	if _active_node == null:
		return
	_active_node.modulate.a = 1.0 - progress
	_active_node.scale = Vector2.ONE * lerpf(1.0, 1.3, progress)
