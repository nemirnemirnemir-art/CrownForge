## Provides arena geometry independent of UI layout.
## Defines spawn zones, center line, and arena bounds for the battle.
extends RefCounted
class_name TenKingsArenaGeometryService


# ---------------------------------------------------------------------------
# Constants (default arena dimensions, can be overridden)
# ---------------------------------------------------------------------------
const DEFAULT_ARENA_WIDTH: float = 800.0
const DEFAULT_ARENA_HEIGHT: float = 400.0
const DEFAULT_CENTER_X: float = 0.0
const MIN_EFFECTIVE_ARENA_WIDTH: float = 640.0
const MAX_EFFECTIVE_ARENA_WIDTH: float = 920.0
const MIN_EFFECTIVE_ARENA_HEIGHT: float = 360.0
const MAX_EFFECTIVE_ARENA_HEIGHT: float = 520.0
const FORMATION_SLOT_COUNT: int = 22
const MAX_DEPTH_ROWS: int = 2
const FORMATION_DEPTH_STEP: float = 34.0
const SLOT_OVERFLOW_WIDTH: float = 18.0
const SLOT_OVERFLOW_HEIGHT_RATIO: float = 0.72


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _arena_rect: Rect2 = Rect2()
var _center_x: float = 0.0


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

func _init() -> void:
	# Default centered arena
	_arena_rect = Rect2(
		-DEFAULT_ARENA_WIDTH * 0.5,
		-DEFAULT_ARENA_HEIGHT * 0.5,
		DEFAULT_ARENA_WIDTH,
		DEFAULT_ARENA_HEIGHT
	)
	_center_x = DEFAULT_CENTER_X


## Configure the arena from explicit dimensions.
func setup_from_dimensions(width: float, height: float, center: Vector2 = Vector2.ZERO) -> void:
	_arena_rect = Rect2(
		center.x - width * 0.5,
		center.y - height * 0.5,
		width,
		height
	)
	_center_x = center.x


## Configure the arena from a viewport rect (e.g., arena panel bounds).
func setup_from_viewport_rect(viewport_rect: Rect2, camera_zoom: Vector2 = Vector2.ONE) -> void:
	# Convert viewport rect to world space centered on camera
	var world_width: float = clampf(viewport_rect.size.x / camera_zoom.x, MIN_EFFECTIVE_ARENA_WIDTH, MAX_EFFECTIVE_ARENA_WIDTH)
	var world_height: float = clampf(viewport_rect.size.y / camera_zoom.y, MIN_EFFECTIVE_ARENA_HEIGHT, MAX_EFFECTIVE_ARENA_HEIGHT)
	setup_from_dimensions(world_width, world_height, Vector2.ZERO)


# ---------------------------------------------------------------------------
# Geometry Queries
# ---------------------------------------------------------------------------

## Returns the full arena rectangle in world space.
func get_arena_rect() -> Rect2:
	return _arena_rect


## Returns the center X coordinate where armies clash.
func get_center_line() -> float:
	return _center_x


## Returns the spawn zone for the player (left side).
func get_player_spawn_zone() -> Rect2:
	var half_width: float = _arena_rect.size.x * 0.5
	var zone_width: float = _arena_rect.size.x * 0.22
	return Rect2(
		_center_x - half_width * 0.48,
		_arena_rect.position.y,
		zone_width,
		_arena_rect.size.y
	)


## Returns the spawn zone for the enemy/AI (right side).
func get_enemy_spawn_zone() -> Rect2:
	var half_width: float = _arena_rect.size.x * 0.5
	var zone_width: float = _arena_rect.size.x * 0.22
	var right_start: float = _center_x + half_width * 0.26
	return Rect2(
		right_start,
		_arena_rect.position.y,
		zone_width,
		_arena_rect.size.y
	)


## Returns formation X position for a unit type on a given side.
## side: 0 = player (left), 1 = enemy (right)
## role: "melee", "ranged", "building"
func get_formation_x(side: int, role: String) -> float:
	var half_width: float = _arena_rect.size.x * 0.5
	var sign_x: float = -1.0 if side == 0 else 1.0
	
	match role:
		"melee":
			# Front line: compact and close to center
			return _center_x + sign_x * half_width * 0.18
		"ranged":
			# Ranged line: slightly behind melee
			return _center_x + sign_x * half_width * 0.28
		"building":
			# Back line behind ranged
			return _center_x + sign_x * half_width * 0.40
		_:
			return _center_x + sign_x * half_width * 0.18


## Returns the castle contact position for siege resolution.
## side: 0 = player castle (far left), 1 = enemy castle (far right)
func get_castle_contact_position(side: int) -> Vector2:
	var y_center: float = _arena_rect.position.y + _arena_rect.size.y * 0.5
	if side == 0:
		return Vector2(_arena_rect.position.x, y_center)
	else:
		return Vector2(_arena_rect.end.x, y_center)


## Returns a random position within the spawn zone for a given side.
## Useful for distributing soldiers with some variance.
func get_random_spawn_position(side: int, rng: RandomNumberGenerator = null) -> Vector2:
	var zone: Rect2 = get_player_spawn_zone() if side == 0 else get_enemy_spawn_zone()
	var actual_rng: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	return Vector2(
		actual_rng.randf_range(zone.position.x, zone.end.x),
		actual_rng.randf_range(zone.position.y, zone.end.y)
	)


## Returns a grid of positions within a spawn zone for distributing soldiers.
## count: number of soldiers to position
## side: 0 = player, 1 = enemy
## Returns Array of Vector2 positions.
func get_spawn_grid_positions(count: int, side: int, role: String = "melee") -> Array:
	var assignments: Array = build_formation_assignments(count, side, role)
	var positions: Array = []
	for assignment: Dictionary in assignments:
		positions.append(assignment.get("position", Vector2.ZERO))
	return positions


func get_center_out_slot_indices(slot_count: int = FORMATION_SLOT_COUNT) -> Array:
	var indexed_slots: Array = []
	var midpoint: float = float(slot_count) * 0.5
	for slot_index in range(slot_count):
		var slot_center: float = float(slot_index) + 0.5
		indexed_slots.append({
			"slot_index": slot_index,
			"distance": absf(slot_center - midpoint),
		})
	indexed_slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a["distance"]), float(b["distance"])):
			return float(a["distance"]) < float(b["distance"])
		return int(a["slot_index"]) < int(b["slot_index"])
	)
	var ordered_slots: Array = []
	for entry: Dictionary in indexed_slots:
		ordered_slots.append(int(entry["slot_index"]))
	return ordered_slots


func build_formation_assignments(count: int, side: int, role: String = "melee") -> Array:
	if count <= 0:
		return []

	var slot_order: Array = get_center_out_slot_indices(FORMATION_SLOT_COUNT)
	var slot_height: float = _arena_rect.size.y / float(FORMATION_SLOT_COUNT)
	var slot_overflow_height: float = slot_height * SLOT_OVERFLOW_HEIGHT_RATIO
	var sign_x: float = -1.0 if side == 0 else 1.0
	var front_x: float = get_formation_x(side, role)
	var primary_bucket_count: int = FORMATION_SLOT_COUNT * MAX_DEPTH_ROWS
	var bucket_counts: Dictionary = {}
	var bucket_local_indices: Array = []

	for unit_index in range(count):
		var bucket_index: int = unit_index % primary_bucket_count
		var local_index: int = int(bucket_counts.get(bucket_index, 0))
		bucket_counts[bucket_index] = local_index + 1
		bucket_local_indices.append({
			"bucket_index": bucket_index,
			"local_index": local_index,
		})

	var assignments: Array = []
	for unit_index in range(count):
		var local_entry: Dictionary = bucket_local_indices[unit_index]
		var bucket_index: int = int(local_entry["bucket_index"])
		var local_index: int = int(local_entry["local_index"])
		var bucket_size: int = int(bucket_counts.get(bucket_index, 1))
		var depth_row: int = bucket_index / FORMATION_SLOT_COUNT
		var slot_order_index: int = bucket_index % FORMATION_SLOT_COUNT
		var slot_index: int = int(slot_order[slot_order_index])
		var slot_center_y: float = _arena_rect.position.y + slot_height * (float(slot_index) + 0.5)
		var row_x: float = front_x + sign_x * FORMATION_DEPTH_STEP * float(depth_row)
		var sub_offset: Vector2 = _get_bucket_sub_offset(local_index, bucket_size, SLOT_OVERFLOW_WIDTH, slot_overflow_height)
		var position := Vector2(row_x + sign_x * sub_offset.x, slot_center_y + sub_offset.y)
		assignments.append({
			"unit_index": unit_index,
			"slot_index": slot_index,
			"depth_row": depth_row,
			"bucket_index": bucket_index,
			"bucket_size": bucket_size,
			"bucket_local_index": local_index,
			"position": position,
		})
	return assignments


func _get_bucket_sub_offset(local_index: int, bucket_size: int, width: float, height: float) -> Vector2:
	if bucket_size <= 1:
		return Vector2.ZERO
	var cols: int = ceili(sqrt(float(bucket_size)))
	var rows: int = ceili(float(bucket_size) / float(cols))
	var col: int = local_index % cols
	var row: int = local_index / cols
	var x_step: float = width / float(maxi(cols, 1))
	var y_step: float = height / float(maxi(rows, 1))
	var x: float = (float(col) - float(cols - 1) * 0.5) * x_step
	var y: float = (float(row) - float(rows - 1) * 0.5) * y_step
	return Vector2(x, y)
