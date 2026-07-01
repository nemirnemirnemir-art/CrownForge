extends Control

## Visual cooldown progress indicator for skills

var cooldown_progress: float = 0.0
var max_cooldown: float = 1.0

func _ready() -> void:
	pass

func set_cooldown_progress(progress: float, max_time: float) -> void:
	cooldown_progress = progress
	max_cooldown = max_time
	queue_redraw()

func _draw() -> void:
	if max_cooldown <= 0.0:
		return
	
	var progress_ratio: float = cooldown_progress / max_cooldown
	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0
	
	# Draw cooldown circle
	var start_angle: float = -PI / 2.0
	var end_angle: float = start_angle + (2.0 * PI * progress_ratio)
	
	draw_arc(center, radius, start_angle, end_angle, 32, Color(0.0, 0.0, 0.0, 0.5), 3.0)

