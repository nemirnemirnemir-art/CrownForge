extends RefCounted
class_name MobLaneAssault

const WallGeometryScript := preload("res://scripts/map/WallGeometry.gd")

var _wall_geometry = WallGeometryScript.new()
var _has_lane: bool = false
var _lane_y: float = 0.0


func capture_lane_from_spawn(spawn_y: float) -> void:
	_has_lane = true
	_lane_y = spawn_y


func clear_lane() -> void:
	_has_lane = false


func get_lane_y(current_y: float, map_bounds: Rect2 = Rect2()) -> float:
	var lane_y := _lane_y if _has_lane else current_y
	if map_bounds.size == Vector2.ZERO:
		return lane_y
	return clampf(lane_y, map_bounds.position.y, map_bounds.end.y)


func get_wall_contact_point(wall_rect: Rect2, current_y: float, map_bounds: Rect2 = Rect2()) -> Vector2:
	return _wall_geometry.get_lane_contact_point(wall_rect, get_lane_y(current_y, map_bounds))


func get_wall_approach_point(wall_rect: Rect2, current_y: float, stand_off_distance: float, map_bounds: Rect2 = Rect2()) -> Vector2:
	return _wall_geometry.get_lane_approach_point(wall_rect, get_lane_y(current_y, map_bounds), stand_off_distance)


func get_distance_to_wall(wall_rect: Rect2, world_position: Vector2) -> float:
	return _wall_geometry.get_distance_to_rect(wall_rect, world_position)
