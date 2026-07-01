extends RefCounted

# Config (set from VzorZone @export values)
var cell_size: Vector2 = Vector2(80, 80)
var visual_offset: Vector2 = Vector2(-30, -45)

# Gaze-core reference (Node, stored as Object to avoid Node import dependency)
var _gaze_core: Object = null

# Placement state
var _corner_cell: Vector2i = Vector2i(0, 0)
var _orientation: int = 3
var _valid_cells: Dictionary = {}
var _last_valid_corner_cell: Vector2i = Vector2i.ZERO
var _last_valid_orientation: int = 0
var _preview_corner_cell: Vector2i = Vector2i.ZERO
var _preview_valid: bool = true

const _SHAPES_3 := [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], # Default: xx / ox
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # Rotated 90°
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], # Rotated 180°
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], # Rotated 270°
]

const _BASE_OFFSETS := {
	4: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	5: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	6: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
}

func setup(gaze_core: Object) -> void:
	_gaze_core = gaze_core

# --- State accessors ---

func get_corner_cell() -> Vector2i:
	return _corner_cell

func get_orientation() -> int:
	return _orientation

func get_preview_corner_cell() -> Vector2i:
	return _preview_corner_cell

func is_preview_valid() -> bool:
	return _preview_valid

func get_target_position() -> Vector2:
	return Vector2(_corner_cell) * cell_size + visual_offset

# --- Shape / offset computation ---

func get_offsets() -> Array:
	return get_offsets_for_orientation(_orientation)

func get_offsets_for_orientation(orientation: int) -> Array:
	var tiles := get_current_tile_count()
	if tiles <= 3:
		return _SHAPES_3[orientation]
	if not _BASE_OFFSETS.has(tiles):
		return _SHAPES_3[orientation]
	var base: Array = _BASE_OFFSETS[tiles]
	return rotate_offsets(base, orientation)

func get_current_tile_count() -> int:
	if _gaze_core and _gaze_core.has_method("get_current_tiles"):
		return int(_gaze_core.call("get_current_tiles"))
	return 3

func rotate_offsets(base: Array, orientation: int) -> Array:
	if base.is_empty():
		return []
	var rotated: Array[Vector2i] = []
	rotated.resize(base.size())
	for i in range(base.size()):
		var off: Vector2i = base[i]
		var x := off.x
		var y := off.y
		var v := Vector2i(x, y)
		match orientation % 4:
			0: v = Vector2i(x, y)
			1: v = Vector2i(-y, x)
			2: v = Vector2i(-x, -y)
			3: v = Vector2i(y, -x)
		rotated[i] = v
	var min_x := rotated[0].x
	var min_y := rotated[0].y
	for v in rotated:
		min_x = min(min_x, v.x)
		min_y = min(min_y, v.y)
	var shift := Vector2i(min_x, min_y)
	for i in range(rotated.size()):
		rotated[i] = rotated[i] - shift
	rotated.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a.x < b.x) if a.y == b.y else (a.y < b.y)
	)
	return rotated

func get_bounding_rect() -> Rect2:
	var offsets := get_offsets()
	var min_x := (offsets[0] as Vector2i).x
	var max_x := (offsets[0] as Vector2i).x
	var min_y := (offsets[0] as Vector2i).y
	var max_y := (offsets[0] as Vector2i).y
	for offset in offsets:
		min_x = min(min_x, (offset as Vector2i).x)
		max_x = max(max_x, (offset as Vector2i).x)
		min_y = min(min_y, (offset as Vector2i).y)
		max_y = max(max_y, (offset as Vector2i).y)
	var rect_pos := Vector2(min_x * cell_size.x, min_y * cell_size.y)
	var rect_size := Vector2((max_x - min_x + 1) * cell_size.x, (max_y - min_y + 1) * cell_size.y)
	return Rect2(rect_pos, rect_size)

# --- Cell coordinate helpers ---

func get_cell_from_position(world_pos: Vector2) -> Vector2i:
	if cell_size.x == 0 or cell_size.y == 0:
		return Vector2i.ZERO
	return Vector2i(
		int(round(world_pos.x / cell_size.x)),
		int(round(world_pos.y / cell_size.y))
	)

func compute_cell_from_top_left(desired_top_left: Vector2) -> Vector2i:
	var adjusted := desired_top_left - visual_offset
	return Vector2i(
		int(round(adjusted.x / cell_size.x)),
		int(round(adjusted.y / cell_size.y))
	)

func get_placement_center_for(corner_cell: Vector2i, orientation: int) -> Vector2:
	var offsets := get_offsets_for_orientation(orientation)
	if offsets.is_empty():
		return Vector2(corner_cell) * cell_size + visual_offset
	var min_x: int = (offsets[0] as Vector2i).x
	var max_x: int = (offsets[0] as Vector2i).x
	var min_y: int = (offsets[0] as Vector2i).y
	var max_y: int = (offsets[0] as Vector2i).y
	for offset in offsets:
		min_x = min(min_x, (offset as Vector2i).x)
		max_x = max(max_x, (offset as Vector2i).x)
		min_y = min(min_y, (offset as Vector2i).y)
		max_y = max(max_y, (offset as Vector2i).y)
	var top_left := Vector2(corner_cell) * cell_size + visual_offset + Vector2(min_x * cell_size.x, min_y * cell_size.y)
	var sz := Vector2((max_x - min_x + 1) * cell_size.x, (max_y - min_y + 1) * cell_size.y)
	return top_left + sz * 0.5

# --- Valid cell management ---

func rebuild_valid_cells(slots: Array) -> void:
	_valid_cells.clear()
	for slot in slots:
		if slot == null:
			continue
		var slot_cell: Vector2i = get_cell_from_position(slot.position)
		_valid_cells[slot_cell] = true

func can_place_at(corner_cell: Vector2i, orientation: int) -> bool:
	if _valid_cells.is_empty():
		return false
	var offsets := get_offsets_for_orientation(orientation)
	for offset in offsets:
		var cell: Vector2i = corner_cell + offset
		if not _valid_cells.has(cell):
			return false
	return true

# --- Placement search ---

func move_to_first_valid_placement() -> void:
	if _valid_cells.is_empty():
		return
	var cells := _valid_cells.keys()
	if cells.is_empty():
		return
	cells.sort()
	for cell in cells:
		var c: Vector2i = cell
		for o in range(4):
			if can_place_at(c, o):
				_corner_cell = c
				_orientation = o
				_last_valid_corner_cell = _corner_cell
				_last_valid_orientation = _orientation
				return

func move_to_central_placement(viewport_center: Vector2) -> void:
	if _valid_cells.is_empty():
		return
	var cells := _valid_cells.keys()
	if cells.is_empty():
		return

	var target_center := viewport_center
	if target_center == Vector2.ZERO:
		for cell in cells:
			target_center += Vector2(cell) * cell_size
		target_center /= float(cells.size())

	target_center += Vector2(-cell_size.x * 2.0, -cell_size.y)

	var best_cell := Vector2i.ZERO
	var best_orientation := 0
	var best_distance := INF
	var found := false

	for cell in cells:
		var c: Vector2i = cell
		for o in range(4):
			if not can_place_at(c, o):
				continue
			var placement_center := get_placement_center_for(c, o)
			var distance := placement_center.distance_squared_to(target_center)
			if not found or distance < best_distance:
				best_distance = distance
				best_cell = c
				best_orientation = o
				found = true

	if found:
		_corner_cell = best_cell
		_orientation = best_orientation
		_last_valid_corner_cell = _corner_cell
		_last_valid_orientation = _orientation
		return

	move_to_first_valid_placement()

# --- State transitions ---

func rotate_clockwise() -> bool:
	var next_orientation: int = (_orientation + 1) % 4
	if can_place_at(_corner_cell, next_orientation):
		_orientation = next_orientation
		_last_valid_orientation = _orientation
		return true
	return false

func start_drag() -> void:
	_last_valid_corner_cell = _corner_cell
	_last_valid_orientation = _orientation
	_preview_corner_cell = _corner_cell
	_preview_valid = true

func update_preview(snapped_cell: Vector2i, placement_valid: bool) -> void:
	_preview_corner_cell = snapped_cell
	_preview_valid = placement_valid

func apply_drop() -> void:
	if _preview_valid and can_place_at(_preview_corner_cell, _orientation):
		_corner_cell = _preview_corner_cell
		_last_valid_corner_cell = _corner_cell
		_last_valid_orientation = _orientation
	else:
		_corner_cell = _last_valid_corner_cell
		_orientation = _last_valid_orientation
	commit_world_position()

func commit_world_position() -> void:
	_preview_corner_cell = _corner_cell
	_preview_valid = true

func commit_placement() -> void:
	_last_valid_corner_cell = _corner_cell
	_last_valid_orientation = _orientation
	_preview_corner_cell = _corner_cell
	_preview_valid = true
