extends RefCounted
## Manages a 5×5 grid for one player's board in the 10 Kings prototype.
## Coordinates: Vector2i(0,0) top-left to Vector2i(4,4) bottom-right.
## Layer 0 = center (2,2), Layer 1 = inner ring (8 cells), Layer 2 = outer ring (16 cells).

const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

enum SlotState { LOCKED, EMPTY, OCCUPIED }

# ---------------------------------------------------------------------------
# Inner class
# ---------------------------------------------------------------------------

class SlotData:
	var state: int = SlotState.LOCKED  # int to avoid cross-class enum issues
	var card_id: StringName = &""
	var level: int = 0
	var extra_units: int = 0
	var smith_dmg_bonus: float = 0.0
	var steel_coat_stacks: int = 0
	var steel_coat_blocks_available: int = 0  # reset each battle

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const GRID_SIZE: int = 5

## Pre-computed layer assignments for every cell.
const _LAYER_MAP: Dictionary = {
	Vector2i(0, 0): 2, Vector2i(1, 0): 2, Vector2i(2, 0): 2, Vector2i(3, 0): 2, Vector2i(4, 0): 2,
	Vector2i(0, 1): 2, Vector2i(1, 1): 1, Vector2i(2, 1): 1, Vector2i(3, 1): 1, Vector2i(4, 1): 2,
	Vector2i(0, 2): 2, Vector2i(1, 2): 1, Vector2i(2, 2): 0, Vector2i(3, 2): 1, Vector2i(4, 2): 2,
	Vector2i(0, 3): 2, Vector2i(1, 3): 1, Vector2i(2, 3): 1, Vector2i(3, 3): 1, Vector2i(4, 3): 2,
	Vector2i(0, 4): 2, Vector2i(1, 4): 2, Vector2i(2, 4): 2, Vector2i(3, 4): 2, Vector2i(4, 4): 2,
}

## Special card IDs that have unique placement rules.
const WILDCARD_ID: StringName = &"wildcard"
const STEEL_COAT_ID: StringName = &"steel_coat"
const CASTLE_ID: StringName = &"castle"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## The grid: Vector2i -> SlotData
var _grid: Dictionary = {}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _init() -> void:
	for x: int in range(GRID_SIZE):
		for y: int in range(GRID_SIZE):
			var pos := Vector2i(x, y)
			var slot := SlotData.new()
			var layer: int = _LAYER_MAP[pos]
			if layer <= 1:
				slot.state = SlotState.EMPTY
			else:
				slot.state = SlotState.LOCKED
			_grid[pos] = slot

# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

func is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE


func get_slot_state(pos: Vector2i) -> SlotState:
	if not is_valid_pos(pos):
		return SlotState.LOCKED
	var slot: SlotData = _grid[pos]
	return slot.state


func get_slot_data(pos: Vector2i) -> SlotData:
	if not is_valid_pos(pos):
		return null
	return _grid[pos] as SlotData


func get_layer(pos: Vector2i) -> int:
	if not _LAYER_MAP.has(pos):
		return -1
	return int(_LAYER_MAP[pos])


func get_empty_slots() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.EMPTY:
			result.append(pos)
	return result


func get_occupied_slots() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.OCCUPIED:
			result.append(pos)
	return result


func get_locked_slots() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.LOCKED:
			result.append(pos)
	return result

# ---------------------------------------------------------------------------
# Adjacency
# ---------------------------------------------------------------------------

## Returns all valid 8-neighbour positions (including diagonals).
func get_adjacent_positions(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var neighbour := Vector2i(pos.x + dx, pos.y + dy)
			if is_valid_pos(neighbour):
				result.append(neighbour)
	return result

# ---------------------------------------------------------------------------
# Placement
# ---------------------------------------------------------------------------

func can_place_card(pos: Vector2i, card_id: StringName) -> bool:
	if not is_valid_pos(pos):
		return false

	var slot: SlotData = _grid[pos]

	# Steel Coat: slot must be OCCUPIED (stacks infinitely)
	if card_id == STEEL_COAT_ID:
		return slot.state == SlotState.OCCUPIED

	# Wildcard: slot must be OCCUPIED with level < 3
	if card_id == WILDCARD_ID:
		return slot.state == SlotState.OCCUPIED and slot.level < 3

	# Castle rule: forbid second castle on a different empty slot
	if card_id == CASTLE_ID and slot.state == SlotState.EMPTY:
		# Check if a castle already exists elsewhere
		for check_pos: Vector2i in _grid.keys():
			if check_pos != pos:
				var check_slot: SlotData = _grid[check_pos]
				if check_slot.state == SlotState.OCCUPIED and check_slot.card_id == CASTLE_ID:
					return false
		return true

	# New placement: slot must be EMPTY
	if slot.state == SlotState.EMPTY:
		return true

	# Upgrade: slot must be OCCUPIED with same card_id and level < 3
	if slot.state == SlotState.OCCUPIED and slot.card_id == card_id and slot.level < 3:
		return true

	return false


func place_card(pos: Vector2i, card_id: StringName) -> bool:
	if not can_place_card(pos, card_id):
		return false

	var slot: SlotData = _grid[pos]

	# Steel Coat: increment stacks, set blocks available
	if card_id == STEEL_COAT_ID:
		slot.steel_coat_stacks += 1
		slot.steel_coat_blocks_available += 1
		return true

	# Wildcard: upgrade existing card
	if card_id == WILDCARD_ID:
		slot.level = mini(slot.level + 1, 3)
		return true

	# New placement on EMPTY slot
	if slot.state == SlotState.EMPTY:
		slot.state = SlotState.OCCUPIED
		slot.card_id = card_id
		slot.level = 1
		slot.extra_units = 0
		slot.smith_dmg_bonus = 0.0
		slot.steel_coat_stacks = 0
		slot.steel_coat_blocks_available = 0
		return true

	# Upgrade: same card_id, level < 3
	slot.level = mini(slot.level + 1, 3)
	return true

# ---------------------------------------------------------------------------
# Layer unlock
# ---------------------------------------------------------------------------

## Unlocks one random LOCKED slot from layer 2.
## Returns the unlocked position, or Vector2i(-1, -1) if none remain.
func unlock_next_slot() -> Vector2i:
	var locked: Array[Vector2i] = []
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.LOCKED and get_layer(pos) == 2:
			locked.append(pos)

	if locked.is_empty():
		return Vector2i(-1, -1)

	var idx: int = randi() % locked.size()
	var chosen: Vector2i = locked[idx]
	var slot: SlotData = _grid[chosen]
	slot.state = SlotState.EMPTY
	return chosen

# ---------------------------------------------------------------------------
# Castle helpers
# ---------------------------------------------------------------------------

func has_castle() -> bool:
	return get_castle_pos() != Vector2i(-1, -1)


func get_castle_pos() -> Vector2i:
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.OCCUPIED and slot.card_id == CASTLE_ID:
			return pos
	return Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Battle helpers
# ---------------------------------------------------------------------------

## Reset block availability for all steel-coated slots before each battle.
## Does not reset stacks — just marks blocks as available again.
func reset_steel_coat_blocks() -> void:
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.steel_coat_stacks > 0:
			slot.steel_coat_blocks_available = slot.steel_coat_stacks


## Returns true if at least one occupied slot contains a troop card.
func has_troop_on_board() -> bool:
	for pos: Vector2i in _grid:
		var slot: SlotData = _grid[pos]
		if slot.state == SlotState.OCCUPIED and CardLib.is_troop(slot.card_id):
			return true
	return false
