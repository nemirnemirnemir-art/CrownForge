extends RefCounted
class_name SpellBoundsEnforcer


func move_within_rect(position: Vector2, velocity: Vector2, delta: float, radius: float, margin: float, rect: Rect2, random_velocity: Callable) -> Dictionary:
	var next_position := position + velocity * delta
	var next_velocity := velocity
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return {"position": next_position, "velocity": next_velocity}

	var half := Vector2(radius, radius)
	var min_x := rect.position.x + half.x + margin
	var max_x := rect.position.x + rect.size.x - half.x - margin
	var min_y := rect.position.y + half.y + margin
	var max_y := rect.position.y + rect.size.y - half.y - margin

	if next_position.x < min_x:
		next_position.x = min_x
		next_velocity.x = absf(next_velocity.x)
	elif next_position.x > max_x:
		next_position.x = max_x
		next_velocity.x = -absf(next_velocity.x)

	if next_position.y < min_y:
		next_position.y = min_y
		next_velocity.y = absf(next_velocity.y)
	elif next_position.y > max_y:
		next_position.y = max_y
		next_velocity.y = -absf(next_velocity.y)

	if next_velocity.length_squared() < 1.0 and random_velocity.is_valid():
		next_velocity = random_velocity.call()

	return {"position": next_position, "velocity": next_velocity}
