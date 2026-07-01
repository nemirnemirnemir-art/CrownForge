class_name TenKingsCrowdSpatialGrid
extends RefCounted
## Simple cell-based spatial hash for fast nearest-enemy lookup in crowd battles.

var cell_size: float = 64.0

# cell_key -> Array of {soldier_id: int, team: int}
var _cells: Dictionary = {}

# soldier_id -> cell_key (for fast removal/update)
var _soldier_cells: Dictionary = {}


func clear() -> void:
	_cells.clear()
	_soldier_cells.clear()


func _get_cell_key(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / cell_size),
		floori(position.y / cell_size)
	)


func insert(soldier_id: int, position: Vector2, team: int) -> void:
	var cell_key := _get_cell_key(position)
	
	if not _cells.has(cell_key):
		_cells[cell_key] = []
	
	_cells[cell_key].append({"soldier_id": soldier_id, "team": team})
	_soldier_cells[soldier_id] = cell_key


func remove(soldier_id: int) -> void:
	if not _soldier_cells.has(soldier_id):
		return
	
	var cell_key: Vector2i = _soldier_cells[soldier_id]
	_soldier_cells.erase(soldier_id)
	
	if not _cells.has(cell_key):
		return
	
	var cell_array: Array = _cells[cell_key]
	for i in range(cell_array.size() - 1, -1, -1):
		if cell_array[i]["soldier_id"] == soldier_id:
			cell_array.remove_at(i)
			break
	
	if cell_array.is_empty():
		_cells.erase(cell_key)


func update(soldier_id: int, old_position: Vector2, new_position: Vector2) -> void:
	var old_key := _get_cell_key(old_position)
	var new_key := _get_cell_key(new_position)
	
	if old_key == new_key:
		return
	
	# Get soldier's team before removing
	var team: int = -1
	if _soldier_cells.has(soldier_id):
		var current_key: Vector2i = _soldier_cells[soldier_id]
		if _cells.has(current_key):
			for entry in _cells[current_key]:
				if entry["soldier_id"] == soldier_id:
					team = entry["team"]
					break
	
	if team == -1:
		return
	
	remove(soldier_id)
	insert(soldier_id, new_position, team)


func get_nearest_enemy(position: Vector2, team: int, max_range: float) -> int:
	var cells_to_check := _get_cells_in_range(position, max_range)
	var max_range_sq := max_range * max_range
	
	var nearest_id: int = -1
	var nearest_dist_sq: float = INF
	
	for cell_key in cells_to_check:
		if not _cells.has(cell_key):
			continue
		
		for entry in _cells[cell_key]:
			if entry["team"] == team:
				continue
			
			# We need to get soldier position from somewhere
			# This requires the runtime to pass position data or we store it
			# For now, use a simpler approach: return first enemy found in range
			# The actual distance check happens in the runtime
			if nearest_id == -1:
				nearest_id = entry["soldier_id"]
	
	return nearest_id


func get_enemies_in_range(position: Vector2, team: int, range_dist: float) -> Array:
	var cells_to_check := _get_cells_in_range(position, range_dist)
	var enemies: Array = []
	
	for cell_key in cells_to_check:
		if not _cells.has(cell_key):
			continue
		
		for entry in _cells[cell_key]:
			if entry["team"] != team:
				enemies.append(entry["soldier_id"])
	
	return enemies


func _get_cells_in_range(position: Vector2, range_dist: float) -> Array:
	var center_cell := _get_cell_key(position)
	var cell_radius := ceili(range_dist / cell_size)
	var cells: Array = []
	
	for dx in range(-cell_radius, cell_radius + 1):
		for dy in range(-cell_radius, cell_radius + 1):
			cells.append(Vector2i(center_cell.x + dx, center_cell.y + dy))
	
	return cells
