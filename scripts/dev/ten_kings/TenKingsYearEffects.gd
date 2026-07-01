## Static utility that processes Farm and Blacksmith yearly effects
## on a player's board in the 10 Kings prototype.
extends RefCounted

const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Applies all yearly effects to the board (Farms first, then Blacksmiths).
## Returns a summary dictionary with keys:
##   farms_applied, smiths_applied, units_added, dmg_bonus_added
static func apply_year_effects(board: RefCounted) -> Dictionary:
	var farm_result: Dictionary = _apply_farms(board)
	var smith_result: Dictionary = _apply_blacksmiths(board)
	return {
		"farms_applied": int(farm_result["count"]),
		"smiths_applied": int(smith_result["count"]),
		"units_added": int(farm_result["units_added"]),
		"dmg_bonus_added": float(smith_result["dmg_bonus_added"]),
	}


# ---------------------------------------------------------------------------
# Farm effect
# ---------------------------------------------------------------------------

## Each Farm adds bonus units to the FIRST adjacent troop it finds.
## Bonus: level 1 → +1, level 2 → +2, level 3 → +3 (cumulative each year).
static func _apply_farms(board: RefCounted) -> Dictionary:
	var count: int = 0
	var units_added: int = 0

	var occupied: Array = board.get_occupied_slots()
	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if slot_data == null:
			continue
		if slot_data.card_id != CardLib.CARD_FARM:
			continue

		# Determine bonus from farm level
		var stats: Dictionary = CardLib.get_stats_for_level(CardLib.CARD_FARM, slot_data.level)
		var bonus: int = int(stats.get("farm_bonus", 0))

		# Find first adjacent troop
		var neighbours: Array = board.get_adjacent_positions(pos)
		for adj_pos: Vector2i in neighbours:
			if board.get_slot_state(adj_pos) != BoardStateScript.SlotState.OCCUPIED:
				continue
			var adj_data: RefCounted = board.get_slot_data(adj_pos)
			if adj_data == null:
				continue
			if not CardLib.is_troop(adj_data.card_id):
				continue

			# Apply bonus to first troop found
			adj_data.extra_units += bonus
			units_added += bonus
			count += 1
			break

	return {"count": count, "units_added": units_added}


# ---------------------------------------------------------------------------
# Blacksmith effect
# ---------------------------------------------------------------------------

## Each Blacksmith adds cumulative DMG% to ALL adjacent occupied slots.
## Bonus: level 1 → +0.02, level 2 → +0.04, level 3 → +0.06 (cumulative).
static func _apply_blacksmiths(board: RefCounted) -> Dictionary:
	var count: int = 0
	var dmg_bonus_added: float = 0.0

	var occupied: Array = board.get_occupied_slots()
	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if slot_data == null:
			continue
		if slot_data.card_id != CardLib.CARD_BLACKSMITH:
			continue

		# Determine bonus from blacksmith level
		var stats: Dictionary = CardLib.get_stats_for_level(CardLib.CARD_BLACKSMITH, slot_data.level)
		var bonus: float = float(stats.get("smith_bonus", 0.0))

		# Apply to all adjacent occupied slots (troops AND buildings)
		var neighbours: Array = board.get_adjacent_positions(pos)
		var applied: bool = false
		for adj_pos: Vector2i in neighbours:
			if board.get_slot_state(adj_pos) != BoardStateScript.SlotState.OCCUPIED:
				continue
			var adj_data: RefCounted = board.get_slot_data(adj_pos)
			if adj_data == null:
				continue

			adj_data.smith_dmg_bonus += bonus
			dmg_bonus_added += bonus
			applied = true

		if applied:
			count += 1

	return {"count": count, "dmg_bonus_added": dmg_bonus_added}
