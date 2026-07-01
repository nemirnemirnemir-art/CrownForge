extends RefCounted
class_name WallGeometry


func get_closest_point_on_rect(world_rect: Rect2, world_position: Vector2) -> Vector2:
	if world_rect.size == Vector2.ZERO:
		return world_rect.position
	return Vector2(
		clampf(world_position.x, world_rect.position.x, world_rect.end.x),
		clampf(world_position.y, world_rect.position.y, world_rect.end.y)
	)


func get_lane_contact_point(world_rect: Rect2, lane_y: float) -> Vector2:
	if world_rect.size == Vector2.ZERO:
		return Vector2(world_rect.position.x, lane_y)
	return Vector2(world_rect.end.x, clampf(lane_y, world_rect.position.y, world_rect.end.y))


func get_lane_approach_point(world_rect: Rect2, lane_y: float, stand_off_distance: float) -> Vector2:
	var contact_point := get_lane_contact_point(world_rect, lane_y)
	return contact_point + Vector2(maxf(0.0, stand_off_distance), 0.0)


func get_distance_to_rect(world_rect: Rect2, world_position: Vector2) -> float:
	return world_position.distance_to(get_closest_point_on_rect(world_rect, world_position))
