## AI controller for the 10 Kings prototype.
## Makes decisions for the AI player using simple heuristics:
##   - Castle placement (center-biased)
##   - Card play priority (castle > troops > buildings > enchantments > tomes)
##   - Offer selection (troops > buildings > enchantments > tomes)
## All functions are static for stateless operation.
extends RefCounted


const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")

## Sentinel value returned when no valid position is found.
const INVALID_POS := Vector2i(-1, -1)

## Priority list for offer selection — higher index = lower priority.
const _OFFER_PRIORITY: Array[StringName] = [
	CardLib.CARD_SOLDIER,
	CardLib.CARD_PALADIN,
	CardLib.CARD_ARCHER,
	CardLib.CARD_FARM,
	CardLib.CARD_BLACKSMITH,
	CardLib.CARD_SCOUT_TOWER,
	CardLib.CARD_STEEL_COAT,
	CardLib.CARD_WILDCARD,
]


# ---------------------------------------------------------------------------
# 1. Castle Placement
# ---------------------------------------------------------------------------

## Called once at game start. Returns a valid empty slot for the castle.
## Heuristic: prefer center (2,2), then any random empty slot from layer 0/1.
static func decide_castle_placement(player: RefCounted) -> Vector2i:
	var board: RefCounted = player.board
	var center := Vector2i(2, 2)

	# Prefer center
	if board.get_slot_state(center) == BoardStateScript.SlotState.EMPTY:
		return center

	# Fallback: pick a random empty slot from layer 0 or 1
	var empty_slots: Array[Vector2i] = board.get_empty_slots()
	var candidates: Array[Vector2i] = []
	for pos: Vector2i in empty_slots:
		var layer: int = board.get_layer(pos)
		if layer <= 1:
			candidates.append(pos)

	if candidates.is_empty():
		# Desperate fallback: any empty slot at all
		if empty_slots.is_empty():
			push_warning("TenKingsAiController: no empty slots for castle placement!")
			return INVALID_POS
		return empty_slots[randi() % empty_slots.size()]

	return candidates[randi() % candidates.size()]


# ---------------------------------------------------------------------------
# 2. Play Cards Phase
# ---------------------------------------------------------------------------

## AI plays all cards it wants from hand in one turn.
## Returns an Array of { "card_id": StringName, "pos": Vector2i } for logging.
## Processes hand in priority order: castle > troops > buildings > steel coat > wildcard.
static func play_turn(player: RefCounted) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var board: RefCounted = player.board

	# We iterate multiple passes since playing cards changes board state.
	# Process in priority order, consuming one card per match found.

	# --- Pass 1: Castle ---
	_try_play_castle(player, board, actions)

	# --- Pass 2: Troops (soldier, paladin, archer) ---
	_try_play_troops(player, board, actions)

	# --- Pass 3: Buildings (farm, blacksmith, scout_tower) ---
	_try_play_buildings(player, board, actions)

	# --- Pass 4: Steel Coat ---
	_try_play_steel_coats(player, board, actions)

	# --- Pass 5: Wildcard ---
	_try_play_wildcards(player, board, actions)

	return actions


static func _try_play_castle(
	player: RefCounted,
	board: RefCounted,
	actions: Array[Dictionary],
) -> void:
	if not board.has_castle() and player.has_card_in_hand(CardLib.CARD_CASTLE):
		var pos: Vector2i = decide_castle_placement(player)
		if pos != INVALID_POS:
			if player.play_card(CardLib.CARD_CASTLE, pos):
				actions.append({"card_id": CardLib.CARD_CASTLE, "pos": pos})


static func _try_play_troops(
	player: RefCounted,
	board: RefCounted,
	actions: Array[Dictionary],
) -> void:
	var troop_ids: Array[StringName] = [
		CardLib.CARD_SOLDIER,
		CardLib.CARD_PALADIN,
		CardLib.CARD_ARCHER,
	]
	# Keep playing troop cards while we have them and can place them
	var changed: bool = true
	while changed:
		changed = false
		for card_id: StringName in troop_ids:
			if not player.has_card_in_hand(card_id):
				continue
			var pos: Vector2i = _find_best_troop_slot(board, card_id)
			if pos == INVALID_POS:
				continue
			if player.play_card(card_id, pos):
				actions.append({"card_id": card_id, "pos": pos})
				changed = true


static func _try_play_buildings(
	player: RefCounted,
	board: RefCounted,
	actions: Array[Dictionary],
) -> void:
	var building_ids: Array[StringName] = [
		CardLib.CARD_FARM,
		CardLib.CARD_BLACKSMITH,
		CardLib.CARD_SCOUT_TOWER,
	]
	var changed: bool = true
	while changed:
		changed = false
		for card_id: StringName in building_ids:
			if not player.has_card_in_hand(card_id):
				continue
			# Try upgrade first (same card_id on existing slot)
			var upgrade_pos: Vector2i = _find_upgrade_slot(board, card_id)
			if upgrade_pos != INVALID_POS:
				if player.play_card(card_id, upgrade_pos):
					actions.append({"card_id": card_id, "pos": upgrade_pos})
					changed = true
					continue
			# Otherwise place on best empty slot
			var pos: Vector2i = _find_best_building_slot(board)
			if pos == INVALID_POS:
				continue
			if player.play_card(card_id, pos):
				actions.append({"card_id": card_id, "pos": pos})
				changed = true


static func _try_play_steel_coats(
	player: RefCounted,
	board: RefCounted,
	actions: Array[Dictionary],
) -> void:
	while player.has_card_in_hand(CardLib.CARD_STEEL_COAT):
		var pos: Vector2i = _find_best_steel_coat_target(board)
		if pos == INVALID_POS:
			break
		if not player.play_card(CardLib.CARD_STEEL_COAT, pos):
			break
		actions.append({"card_id": CardLib.CARD_STEEL_COAT, "pos": pos})


static func _try_play_wildcards(
	player: RefCounted,
	board: RefCounted,
	actions: Array[Dictionary],
) -> void:
	while player.has_card_in_hand(CardLib.CARD_WILDCARD):
		# Prefer upgrading lvl 2 troops to lvl 3; fallback to lvl 1 troops
		var pos: Vector2i = _find_best_upgrade_target(board, 2)
		if pos == INVALID_POS:
			pos = _find_best_upgrade_target(board, 1)
		if pos == INVALID_POS:
			break
		if not player.play_card(CardLib.CARD_WILDCARD, pos):
			break
		actions.append({"card_id": CardLib.CARD_WILDCARD, "pos": pos})


# ---------------------------------------------------------------------------
# 3. Offer Selection
# ---------------------------------------------------------------------------

## Given 3 offered cards, pick the best one using a priority list.
## Heuristic: troops > buildings > enchantments > tomes.
static func choose_offer(player: RefCounted, offer: Array[StringName]) -> StringName:
	if offer.is_empty():
		push_warning("TenKingsAiController: empty offer!")
		return &""

	# Build a set of what we already have plenty of (3+ copies in hand)
	var hand_counts: Dictionary = {}  # StringName -> int
	for card_id: StringName in player.hand:
		if not hand_counts.has(card_id):
			hand_counts[card_id] = 0
		hand_counts[card_id] = int(hand_counts[card_id]) + 1

	# First pass: pick highest-priority card we don't already have 3+ of
	for priority_id: StringName in _OFFER_PRIORITY:
		if offer.has(priority_id):
			var count: int = int(hand_counts.get(priority_id, 0))
			if count < 3:
				return priority_id

	# Second pass: just pick highest priority available regardless of count
	for priority_id: StringName in _OFFER_PRIORITY:
		if offer.has(priority_id):
			return priority_id

	# Fallback: pick the first thing in the offer (handles castle in offer)
	return offer[0]


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Find the best slot to place a troop card.
## Priority: upgrade existing same-type slot (prefer higher level) > empty near castle > any empty.
static func _find_best_troop_slot(board: RefCounted, card_id: StringName) -> Vector2i:
	# 1. Try upgrade: find same card_id occupied slots with level < 3
	var best_upgrade := INVALID_POS
	var best_upgrade_level: int = 0
	var occupied: Array[Vector2i] = board.get_occupied_slots()
	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if slot_data.card_id == card_id and slot_data.level < 3:
			if slot_data.level > best_upgrade_level:
				best_upgrade_level = slot_data.level
				best_upgrade = pos
	if best_upgrade != INVALID_POS:
		return best_upgrade

	# 2. Place on empty slot near castle
	var castle_pos: Vector2i = board.get_castle_pos()
	if castle_pos != INVALID_POS:
		var adjacent: Array[Vector2i] = board.get_adjacent_positions(castle_pos)
		# Shuffle to add variety
		var shuffled: Array[Vector2i] = adjacent.duplicate()
		_shuffle_positions(shuffled)
		for pos: Vector2i in shuffled:
			if board.can_place_card(pos, card_id) and board.get_slot_state(pos) == BoardStateScript.SlotState.EMPTY:
				return pos

	# 3. Fallback: any empty slot
	var empty: Array[Vector2i] = board.get_empty_slots()
	if empty.is_empty():
		return INVALID_POS
	return empty[randi() % empty.size()]


## Find the best empty slot for a building — the one adjacent to the most troops.
static func _find_best_building_slot(board: RefCounted) -> Vector2i:
	var empty: Array[Vector2i] = board.get_empty_slots()
	if empty.is_empty():
		return INVALID_POS

	var best_pos := INVALID_POS
	var best_score: int = -1

	for pos: Vector2i in empty:
		var score: int = _count_adjacent_troops(board, pos)
		if score > best_score:
			best_score = score
			best_pos = pos

	# If no slot is adjacent to any troop, just pick a random empty slot
	if best_pos == INVALID_POS or best_score == 0:
		return empty[randi() % empty.size()]

	return best_pos


## Find an occupied slot with the same card_id and level < 3 for upgrading.
static func _find_upgrade_slot(board: RefCounted, card_id: StringName) -> Vector2i:
	var best_pos := INVALID_POS
	var best_level: int = 0
	var occupied: Array[Vector2i] = board.get_occupied_slots()
	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if slot_data.card_id == card_id and slot_data.level < 3:
			if slot_data.level > best_level:
				best_level = slot_data.level
				best_pos = pos
	return best_pos


## Find the best occupied slot for a wildcard upgrade.
## Prefers troop slots at the given target_level, then any occupied slot at that level.
static func _find_best_upgrade_target(board: RefCounted, target_level: int) -> Vector2i:
	var best_troop := INVALID_POS
	var best_other := INVALID_POS
	var occupied: Array[Vector2i] = board.get_occupied_slots()

	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if slot_data.level != target_level:
			continue
		# Wildcard requires level < 3
		if slot_data.level >= 3:
			continue
		if CardLib.is_troop(slot_data.card_id):
			best_troop = pos
		elif best_other == INVALID_POS:
			best_other = pos

	if best_troop != INVALID_POS:
		return best_troop
	return best_other


## Find the best troop slot to apply Steel Coat to.
## Prefers the troop with the most units (from card stats at its current level).
static func _find_best_steel_coat_target(board: RefCounted) -> Vector2i:
	var best_pos := INVALID_POS
	var best_units: int = 0
	var occupied: Array[Vector2i] = board.get_occupied_slots()

	for pos: Vector2i in occupied:
		var slot_data: RefCounted = board.get_slot_data(pos)
		if not CardLib.is_troop(slot_data.card_id):
			continue
		var stats: Dictionary = CardLib.get_stats_for_level(slot_data.card_id, slot_data.level)
		var units: int = int(stats.get("units", 0)) + slot_data.extra_units
		if units > best_units:
			best_units = units
			best_pos = pos

	# Fallback: if no troops, apply to any occupied slot (buildings, etc.)
	if best_pos == INVALID_POS and not occupied.is_empty():
		return occupied[randi() % occupied.size()]

	return best_pos


## Count how many adjacent slots contain troops.
static func _count_adjacent_troops(board: RefCounted, pos: Vector2i) -> int:
	var count: int = 0
	var adjacent: Array[Vector2i] = board.get_adjacent_positions(pos)
	for adj: Vector2i in adjacent:
		if board.get_slot_state(adj) != BoardStateScript.SlotState.OCCUPIED:
			continue
		var slot_data: RefCounted = board.get_slot_data(adj)
		if CardLib.is_troop(slot_data.card_id):
			count += 1
	return count


## Shuffle an array of Vector2i in-place using Fisher-Yates.
static func _shuffle_positions(arr: Array[Vector2i]) -> void:
	var n: int = arr.size()
	for i: int in range(n - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
