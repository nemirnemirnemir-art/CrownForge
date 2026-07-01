## Expands board stacks into individual soldier entities for 1:1 visible battle.
## Converts card stacks (e.g., 9 soldiers) into individual soldier dictionaries
## with unique IDs, positions, and combat stats for crowd battle simulation.
extends RefCounted
class_name TenKingsCrowdBuilder


const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Cards that never participate in battle (support-only).
const _NON_COMBAT_CARDS: Array[StringName] = [
	&"farm", &"blacksmith", &"wildcard", &"steel_coat",
]

## Cards that are fixed structures (not expanded to soldiers, but tracked separately).
const _FIXED_STRUCTURE_CARDS: Array[StringName] = [
	&"castle", &"scout_tower",
]

## Base movement speed for soldiers (pixels per second).
const _BASE_SPEED: float = 80.0

## Base attack range for melee units.
const _MELEE_ATTACK_RANGE: float = 72.0

## Base attack range for ranged units.
const _RANGED_ATTACK_RANGE: float = 180.0

## Base attack cooldown (seconds between attacks).
const _BASE_ATTACK_COOLDOWN: float = 1.0
const _MIN_ATTACK_ENTRY_WINDUP: float = 0.18
const _MAX_ATTACK_ENTRY_WINDUP: float = 0.7


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Unique ID counter for soldiers within a single battle.
var _next_soldier_id: int = 0

## RNG for speed variance.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Expands all troop stacks on a player's board into individual soldier dictionaries.
## Returns Dictionary with keys:
##   "soldiers": Array of soldier dictionaries ready for 1:1 battle simulation.
##   "fixed_structures": Array of fixed structure dictionaries.
##
## Parameters:
##   player_board: TenKingsBoardState - the board to expand
##   side: int - 0 = player, 1 = enemy
##   arena_geometry: TenKingsArenaGeometryService - for spawn positioning
##
## Returns: Dictionary with keys:
##   "soldiers": Array of soldier dictionaries
##   "fixed_structures": Array of fixed structure dictionaries
func expand_stacks_to_soldiers(player_board: RefCounted, side: int, arena_geometry: RefCounted, slot_origins: Dictionary = {}) -> Dictionary:
	var soldiers: Array = []
	var fixed_structures: Array = []
	
	if player_board == null or arena_geometry == null:
		push_warning("TenKingsCrowdBuilder: player_board or arena_geometry is null")
		return {"soldiers": soldiers, "fixed_structures": fixed_structures}
	
	var occupied_slots: Array = player_board.call("get_occupied_slots")
	
	for slot_pos: Vector2i in occupied_slots:
		var slot_data: RefCounted = player_board.call("get_slot_data", slot_pos)
		if slot_data == null:
			continue
		
		var card_id: StringName = StringName(slot_data.get("card_id"))
		
		# Skip non-combat cards entirely
		if card_id in _NON_COMBAT_CARDS:
			continue
		
		# Fixed structures are tracked separately, not expanded to soldiers
		if card_id in _FIXED_STRUCTURE_CARDS:
			var structure := _build_fixed_structure(card_id, slot_data, slot_pos, side, arena_geometry, slot_origins)
			fixed_structures.append(structure)
			continue
		
		# Only troops get expanded to individual soldiers
		if not CardLib.is_troop(card_id):
			continue
		
		var new_soldiers := _expand_troop_stack(card_id, slot_data, slot_pos, side, arena_geometry, slot_origins)
		soldiers.append_array(new_soldiers)
	
	return {"soldiers": soldiers, "fixed_structures": fixed_structures}


## Resets the soldier ID counter. Call before starting a new battle.
func reset_id_counter() -> void:
	_next_soldier_id = 0


## Seeds the RNG for deterministic results (useful for testing/replays).
func seed_rng(seed_value: int) -> void:
	_rng.seed = seed_value


# ---------------------------------------------------------------------------
# Internal: Troop expansion
# ---------------------------------------------------------------------------

func _expand_troop_stack(card_id: StringName, slot_data: RefCounted, slot_pos: Vector2i, side: int, arena_geometry: RefCounted, slot_origins: Dictionary) -> Array:
	var soldiers: Array = []
	
	var level: int = int(slot_data.get("level"))
	var extra_units: int = int(slot_data.get("extra_units"))
	var smith_dmg_bonus: float = float(slot_data.get("smith_dmg_bonus"))
	
	var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)
	if stats.is_empty():
		push_warning("TenKingsCrowdBuilder: No stats for card '%s' level %d" % [str(card_id), level])
		return soldiers
	
	# Get unit count from stats
	var base_units: int = int(stats.get("units", 1))
	var total_units: int = base_units + extra_units
	
	# Get spawn positions from arena geometry
	var role: String = "ranged" if CardLib.is_ranged(card_id) else "melee"
	var assignments: Array = arena_geometry.call("build_formation_assignments", total_units, side, role)
	var arena_rect: Rect2 = arena_geometry.call("get_arena_rect")
	
	# Extract combat stats
	var hp: float = float(stats.get("hp", 10.0))
	var dmg: float = float(stats.get("dmg", 1.0))
	var hps: float = float(stats.get("hps", 1.0))  # Hits per second
	var is_ranged: bool = CardLib.is_ranged(card_id)
	var attack_range: float = _RANGED_ATTACK_RANGE if is_ranged else _MELEE_ATTACK_RANGE
	var attack_cooldown: float = 1.0 / hps if hps > 0.0 else _BASE_ATTACK_COOLDOWN
	
	for i in range(total_units):
		var formation_pos := Vector2.ZERO
		var assignment: Dictionary = {}
		if i < assignments.size():
			assignment = assignments[i]
			formation_pos = assignment.get("position", Vector2.ZERO)
		var deploy_origin: Vector2 = slot_origins.get(slot_pos, formation_pos)
		
		var soldier := _create_soldier_dict(
			card_id,
			side,
			deploy_origin,
			hp,
			dmg,
			attack_range,
			attack_cooldown,
			is_ranged,
			slot_pos,
			smith_dmg_bonus,
			arena_rect.size.x,
			assignment,
			formation_pos,
			deploy_origin
		)
		soldiers.append(soldier)
	
	return soldiers


func _create_soldier_dict(
	unit_type: StringName,
	team: int,
	position: Vector2,
	hp: float,
	attack_dmg: float,
	attack_range: float,
	attack_cooldown: float,
	is_ranged: bool,
	source_slot: Vector2i,
	smith_dmg_bonus: float,
	arena_width: float,
	formation_assignment: Dictionary,
	formation_position: Vector2,
	deploy_origin: Vector2
) -> Dictionary:
	var soldier_id: int = _next_soldier_id
	_next_soldier_id += 1
	
	# Apply speed variance (0.9 to 1.1)
	var speed_variance: float = _rng.randf_range(0.9, 1.1)
	var speed: float = _BASE_SPEED * speed_variance
	var attack_entry_windup: float = clampf(attack_cooldown * _rng.randf_range(0.18, 0.4), _MIN_ATTACK_ENTRY_WINDUP, _MAX_ATTACK_ENTRY_WINDUP)
	
	return {
		"id": soldier_id,
		"unit_type": unit_type,
		"team": team,
		"position": position,
		"velocity": Vector2.ZERO,
		"state": "deploying",
		"target_id": -1,
		"hp": hp,
		"max_hp": hp,
		"attack_dmg": attack_dmg,
		"attack_range": attack_range,
		"attack_cooldown": attack_cooldown,
		"current_cooldown": 0.0,
		"attack_entry_windup": attack_entry_windup,
		"search_range": maxf(arena_width, 900.0),
		"speed": speed,
		"is_ranged": is_ranged,
		"source_slot": source_slot,
		"deploy_origin": deploy_origin,
		"formation_position": formation_position,
		"smith_dmg_bonus": smith_dmg_bonus,
		"formation_slot_index": int(formation_assignment.get("slot_index", -1)),
		"formation_depth_row": int(formation_assignment.get("depth_row", -1)),
		"formation_bucket_index": int(formation_assignment.get("bucket_index", -1)),
		"formation_bucket_size": int(formation_assignment.get("bucket_size", 1)),
		"formation_bucket_local_index": int(formation_assignment.get("bucket_local_index", 0)),
	}


# ---------------------------------------------------------------------------
# Internal: Fixed structure building
# ---------------------------------------------------------------------------

func _build_fixed_structure(card_id: StringName, slot_data: RefCounted, slot_pos: Vector2i, side: int, arena_geometry: RefCounted, slot_origins: Dictionary) -> Dictionary:
	var level: int = int(slot_data.get("level"))
	var stats: Dictionary = CardLib.get_stats_for_level(card_id, level)
	
	var attack_dmg: float = float(stats.get("dmg", 10.0))
	var hps: float = float(stats.get("hps", 1.0))
	var attack_cd: float = 1.0 / hps if hps > 0.0 else 1.0
	var attack_range: float = float(stats.get("attack_range", 400.0))
	
	# Get position from arena geometry
	var formation_position := Vector2.ZERO
	if card_id == CardLib.CARD_CASTLE:
		formation_position = arena_geometry.call("get_castle_contact_position", side)
	else:
		# Scout tower uses building formation position
		formation_position = Vector2(
			arena_geometry.call("get_formation_x", side, "building"),
			0.0
		)
	var deploy_origin: Vector2 = slot_origins.get(slot_pos, formation_position)
	
	return {
		"card_id": card_id,
		"position": deploy_origin,
		"deploy_origin": deploy_origin,
		"formation_position": formation_position,
		"level": level,
		"attack_dmg": attack_dmg,
		"attack_cd": attack_cd,
		"attack_range": attack_range,
		"cooldown_timer": 0.0,
		"side": side,
		"source_slot": slot_pos,
	}
