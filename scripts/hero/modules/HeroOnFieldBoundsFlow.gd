extends RefCounted
class_name HeroOnFieldBoundsFlow

var hero = null


func setup(hero_ref) -> void:
	hero = hero_ref


func set_map_bounds(movement, bounds: Rect2) -> void:
	if movement:
		movement.set_map_bounds(bounds)


func get_map_bounds(movement) -> Rect2:
	return movement.map_bounds if movement else Rect2()


func enforce_battlefield_bounds(movement, state_machine, desired_direction: Vector2, hit_threshold: int) -> Vector2:
	if hero == null or movement == null or movement.map_bounds.size == Vector2.ZERO:
		return desired_direction
	var bounds: Rect2 = movement.map_bounds
	var clamped := Vector2(
		clampf(hero.global_position.x, bounds.position.x, bounds.end.x),
		clampf(hero.global_position.y, bounds.position.y, bounds.end.y)
	)
	if clamped.is_equal_approx(hero.global_position):
		hero._bounds_hit_count = 0
		return desired_direction
	hero.global_position = clamped
	hero.velocity = Vector2.ZERO
	hero._bounds_hit_count += 1
	if hero._bounds_hit_count >= hit_threshold and state_machine:
		hero._bounds_hit_count = 0
		state_machine.change_state("HeroBoundsRetreatState")
		return Vector2.ZERO
	return movement.get_bounce_direction(clamped, desired_direction)
