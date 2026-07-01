extends RefCounted
class_name MobWallTargetingFlow

const WALL_ATTACK_RANGE_MELEE: float = 170.0
const WALL_ATTACK_RANGE_RANGED: float = 320.0
const WALL_VISUAL_STOP_OFFSET_X: float = 200.0
const WALL_ATTACK_TOLERANCE: float = 20.0
const WALL_EXTRA_APPROACH_CLOSER_X: float = 100.0
const USE_DEFAULT_STOP_BUFFER: float = -1.0

var mob = null
var _fallback_wall_attack_stop_distance_override: float = -1.0


func setup(mob_ref) -> void:
	mob = mob_ref


func get_wall_target_node() -> Node2D:
	if mob == null:
		return null
	if mob._runtime_bridge:
		var runtime_wall = mob._runtime_bridge.get_singleton("Wall")
		if runtime_wall and is_instance_valid(runtime_wall) and runtime_wall is Node2D:
			return runtime_wall as Node2D
	var tree: SceneTree = mob.get_tree()
	if tree == null:
		return null
	var wall = tree.get_first_node_in_group("wall")
	if wall and is_instance_valid(wall) and wall is Node2D:
		return wall as Node2D
	return null


func get_wall_contact_position() -> Vector2:
	var wall_rect := _get_wall_rect()
	if wall_rect.size != Vector2.ZERO and mob._lane_assault:
		return mob._lane_assault.get_wall_contact_point(wall_rect, mob.global_position.y, mob.get_map_bounds())
	var wall_position := _get_wall_marker_position()
	return Vector2(wall_position.x, mob.get_assault_lane_y())


func get_wall_approach_position(stop_buffer: float = USE_DEFAULT_STOP_BUFFER) -> Vector2:
	var wall_rect := _get_wall_rect()
	var stand_off: float = get_wall_attack_stand_off(stop_buffer)
	if wall_rect.size != Vector2.ZERO and mob._lane_assault:
		return mob._lane_assault.get_wall_approach_point(wall_rect, mob.global_position.y, stand_off, mob.get_map_bounds())
	var wall_position := _get_wall_marker_position()
	return Vector2(wall_position.x + stand_off, mob.get_assault_lane_y())


func get_distance_to_wall() -> float:
	var wall_rect := _get_wall_rect()
	if wall_rect.size != Vector2.ZERO and mob._lane_assault:
		return mob._lane_assault.get_distance_to_wall(wall_rect, mob.global_position)
	return mob.global_position.distance_to(get_wall_contact_position())


func get_wall_attack_range() -> float:
	if mob and mob.projectile_scene:
		return WALL_ATTACK_RANGE_RANGED
	return WALL_ATTACK_RANGE_MELEE


func get_wall_attack_stand_off(stop_buffer: float = USE_DEFAULT_STOP_BUFFER) -> float:
	if mob == null:
		return 0.0
	var front_offset := get_wall_front_offset_x()
	var stop_distance_override := _get_wall_attack_stop_distance_override()
	# Ranged mobs ignore stop_distance_override, use their attack_range instead
	if stop_distance_override >= 0.0 and not (mob.projectile_scene != null):
		return stop_distance_override + front_offset
	var normalized_stop_buffer := _normalize_stop_buffer(stop_buffer)
	var attack_range := get_wall_attack_range()
	# Ranged mobs use full attack_range without visual offset limit
	if mob.projectile_scene != null:
		return attack_range - normalized_stop_buffer + front_offset
	var base_stand_off := minf(WALL_VISUAL_STOP_OFFSET_X, attack_range - normalized_stop_buffer)
	return maxf(0.0, base_stand_off - WALL_EXTRA_APPROACH_CLOSER_X) + front_offset


func get_wall_attack_trigger_distance(stop_buffer: float = USE_DEFAULT_STOP_BUFFER) -> float:
	return get_wall_attack_stand_off(stop_buffer)


func set_wall_attack_stop_distance(distance: float) -> void:
	if mob and mob.movement and mob.movement.has_method("set_wall_attack_stop_distance"):
		mob.movement.set_wall_attack_stop_distance(distance)
		return
	_fallback_wall_attack_stop_distance_override = maxf(0.0, distance)


func _get_wall_attack_stop_distance_override() -> float:
	if mob and mob.movement and mob.movement.has_method("get_wall_attack_stop_distance_override"):
		return float(mob.movement.get_wall_attack_stop_distance_override())
	return _fallback_wall_attack_stop_distance_override


func _normalize_stop_buffer(stop_buffer: float) -> float:
	if stop_buffer < 0.0:
		return WALL_ATTACK_TOLERANCE
	return stop_buffer


func _get_wall_rect() -> Rect2:
	var wall := get_wall_target_node()
	if wall and wall.has_method("get_world_rect"):
		var wall_rect: Rect2 = wall.call("get_world_rect")
		if wall_rect.size != Vector2.ZERO:
			return wall_rect
	return Rect2()


func _get_wall_marker_position() -> Vector2:
	var marker_service = mob._runtime_bridge.get_singleton("MapMarkerService") if mob and mob._runtime_bridge else null
	if marker_service and marker_service.has_method("get_wall_position"):
		return marker_service.call("get_wall_position")
	return Vector2.ZERO


## Returns the half-width of the mob's hurtbox collision shape, used to
## calculate the correct wall stand-off distance.
func get_wall_front_offset_x() -> float:
	if mob == null:
		return 25.0
	var hurtbox: Area2D = mob._hurtbox
	var fallback: float = 25.0 * abs(mob.scale.x)
	if hurtbox == null:
		return fallback
	var hurtbox_shape := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurtbox_shape == null:
		return fallback
	var rectangle_shape := hurtbox_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return fallback
	var shape_scale := hurtbox_shape.global_transform.get_scale().abs()
	return rectangle_shape.size.x * shape_scale.x * 0.5
