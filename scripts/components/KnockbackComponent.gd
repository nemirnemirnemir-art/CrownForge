extends Node
class_name KnockbackComponent

## Компонент для обработки отталкивания
## Должен быть дочерним элементом Node2D, который нужно толкать

@export var enabled: bool = true

# Текущая активная анимация отталкивания
var _tween: Tween

func apply_knockback(source_position: Vector2, force: float, duration: float = 0.2):
	if not enabled:
		return
		
	var parent = get_parent()
	if not parent is Node2D:
		push_warning("KnockbackComponent: Parent is not Node2D!")
		return

	# Calculate direction away from source
	var direction = (parent.global_position - source_position).normalized()
	# If perfectly on top, pick random direction
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(randf() * TAU)
		
	var target_pos = parent.global_position + direction * force
	
	# Cancel existing knockback if any
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_OUT)
	
	# Move parent
	_tween.tween_property(parent, "global_position", target_pos, duration)
	
	print("[KnockbackComponent] Pushing %s away from %s with force %.1f" % [parent.name, source_position, force])
