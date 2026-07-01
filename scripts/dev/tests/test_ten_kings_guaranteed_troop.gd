## Test: Guaranteed troop spawning - players always have troop in hand at start,
## and End Turn is blocked if no troop is on board.
extends SceneTree


const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const BoardState = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const TurnFlow = preload("res://scripts/dev/ten_kings/TenKingsTurnFlow.gd")


func _init() -> void:
	print("Running TenKings guaranteed troop tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: has_troop_in_hand returns true when hand contains a troop
	if _test_has_troop_in_hand_with_troop():
		print("  PASS: test_has_troop_in_hand_with_troop")
		passed += 1
	else:
		print("  FAIL: test_has_troop_in_hand_with_troop")
		failed += 1

	# Test 2: has_troop_in_hand returns false when hand has no troops
	if _test_has_troop_in_hand_without_troop():
		print("  PASS: test_has_troop_in_hand_without_troop")
		passed += 1
	else:
		print("  FAIL: test_has_troop_in_hand_without_troop")
		failed += 1

	# Test 3: ensure_any_troop_in_hand pulls troop from deck when hand has none
	if _test_ensure_any_troop_in_hand_pulls_from_deck():
		print("  PASS: test_ensure_any_troop_in_hand_pulls_from_deck")
		passed += 1
	else:
		print("  FAIL: test_ensure_any_troop_in_hand_pulls_from_deck")
		failed += 1

	# Test 4: ensure_any_troop_in_hand returns true if troop already in hand
	if _test_ensure_any_troop_in_hand_already_has_troop():
		print("  PASS: test_ensure_any_troop_in_hand_already_has_troop")
		passed += 1
	else:
		print("  FAIL: test_ensure_any_troop_in_hand_already_has_troop")
		failed += 1

	# Test 5: ensure_any_troop_in_hand returns false if no troops in deck
	if _test_ensure_any_troop_in_hand_no_troops_available():
		print("  PASS: test_ensure_any_troop_in_hand_no_troops_available")
		passed += 1
	else:
		print("  FAIL: test_ensure_any_troop_in_hand_no_troops_available")
		failed += 1

	# Test 6: has_troop_on_board returns true when board has a troop
	if _test_has_troop_on_board_with_troop():
		print("  PASS: test_has_troop_on_board_with_troop")
		passed += 1
	else:
		print("  FAIL: test_has_troop_on_board_with_troop")
		failed += 1

	# Test 7: has_troop_on_board returns false when board has no troops
	if _test_has_troop_on_board_without_troop():
		print("  PASS: test_has_troop_on_board_without_troop")
		passed += 1
	else:
		print("  FAIL: test_has_troop_on_board_without_troop")
		failed += 1

	# Test 8: has_troop_on_board returns false for buildings only
	if _test_has_troop_on_board_with_buildings_only():
		print("  PASS: test_has_troop_on_board_with_buildings_only")
		passed += 1
	else:
		print("  FAIL: test_has_troop_on_board_with_buildings_only")
		failed += 1

	# Test 9: TurnFlow.setup() guarantees troop in player hand
	if _test_turnflow_setup_guarantees_player_troop():
		print("  PASS: test_turnflow_setup_guarantees_player_troop")
		passed += 1
	else:
		print("  FAIL: test_turnflow_setup_guarantees_player_troop")
		failed += 1

	# Test 10: TurnFlow.setup() guarantees troop in AI hand
	if _test_turnflow_setup_guarantees_ai_troop():
		print("  PASS: test_turnflow_setup_guarantees_ai_troop")
		passed += 1
	else:
		print("  FAIL: test_turnflow_setup_guarantees_ai_troop")
		failed += 1

	# Test 11: can_end_turn returns false when no troop on board
	if _test_can_end_turn_false_without_troop_on_board():
		print("  PASS: test_can_end_turn_false_without_troop_on_board")
		passed += 1
	else:
		print("  FAIL: test_can_end_turn_false_without_troop_on_board")
		failed += 1

	# Test 12: can_end_turn returns true when troop is on board
	if _test_can_end_turn_true_with_troop_on_board():
		print("  PASS: test_can_end_turn_true_with_troop_on_board")
		passed += 1
	else:
		print("  FAIL: test_can_end_turn_true_with_troop_on_board")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


# ---------------------------------------------------------------------------
# PlayerState.has_troop_in_hand() tests
# ---------------------------------------------------------------------------

func _test_has_troop_in_hand_with_troop() -> bool:
	var player := PlayerState.new("Player", false)
	player.hand.clear()
	player.hand.append(CardLib.CARD_SOLDIER)

	# This should return true - we have a troop (soldier) in hand
	return player.has_troop_in_hand()


func _test_has_troop_in_hand_without_troop() -> bool:
	var player := PlayerState.new("Player", false)
	player.hand.clear()
	player.hand.append(CardLib.CARD_CASTLE)
	player.hand.append(CardLib.CARD_FARM)

	# This should return false - no troops in hand
	return not player.has_troop_in_hand()


# ---------------------------------------------------------------------------
# PlayerState.ensure_any_troop_in_hand() tests
# ---------------------------------------------------------------------------

func _test_ensure_any_troop_in_hand_pulls_from_deck() -> bool:
	var player := PlayerState.new("Player", false)
	player.hand.clear()
	player.hand.append(CardLib.CARD_CASTLE)
	player.hand.append(CardLib.CARD_FARM)

	# Ensure deck has a troop
	player.deck.clear()
	player.deck.append(CardLib.CARD_ARCHER)
	player.deck.append(CardLib.CARD_BLACKSMITH)

	var original_hand_size: int = player.hand.size()
	var original_deck_size: int = player.deck.size()

	# This should pull archer from deck to hand
	var result: bool = player.ensure_any_troop_in_hand()

	if not result:
		return false
	if player.hand.size() != original_hand_size + 1:
		return false
	if player.deck.size() != original_deck_size - 1:
		return false
	if not player.has_troop_in_hand():
		return false

	return true


func _test_ensure_any_troop_in_hand_already_has_troop() -> bool:
	var player := PlayerState.new("Player", false)
	player.hand.clear()
	player.hand.append(CardLib.CARD_SOLDIER)
	player.hand.append(CardLib.CARD_CASTLE)

	var original_hand_size: int = player.hand.size()
	var original_deck_size: int = player.deck.size()

	# Should return true without modifying hand/deck
	var result: bool = player.ensure_any_troop_in_hand()

	if not result:
		return false
	if player.hand.size() != original_hand_size:
		return false
	if player.deck.size() != original_deck_size:
		return false

	return true


func _test_ensure_any_troop_in_hand_no_troops_available() -> bool:
	var player := PlayerState.new("Player", false)
	player.hand.clear()
	player.hand.append(CardLib.CARD_CASTLE)

	# Deck with no troops
	player.deck.clear()
	player.deck.append(CardLib.CARD_FARM)
	player.deck.append(CardLib.CARD_BLACKSMITH)

	# Should return false - no troops available
	var result: bool = player.ensure_any_troop_in_hand()

	return not result


# ---------------------------------------------------------------------------
# BoardState.has_troop_on_board() tests
# ---------------------------------------------------------------------------

func _test_has_troop_on_board_with_troop() -> bool:
	var board := BoardState.new()

	# Place a soldier on an empty slot
	board.place_card(Vector2i(1, 1), CardLib.CARD_SOLDIER)

	# Should return true - we have a troop on board
	return board.has_troop_on_board()


func _test_has_troop_on_board_without_troop() -> bool:
	var board := BoardState.new()

	# Empty board - no troops
	return not board.has_troop_on_board()


func _test_has_troop_on_board_with_buildings_only() -> bool:
	var board := BoardState.new()

	# Place only buildings
	board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE)
	board.place_card(Vector2i(1, 1), CardLib.CARD_FARM)

	# Should return false - buildings are not troops
	return not board.has_troop_on_board()


# ---------------------------------------------------------------------------
# TurnFlow.setup() troop guarantee tests
# ---------------------------------------------------------------------------

func _test_turnflow_setup_guarantees_player_troop() -> bool:
	# Create players with decks that have NO troops in first 3 cards
	var player := PlayerState.new("Player", false)
	var ai := PlayerState.new("AI", true)

	# Clear default deck and set up deck with no troops at start
	player.deck.clear()
	player.deck.append(CardLib.CARD_CASTLE)
	player.deck.append(CardLib.CARD_FARM)
	player.deck.append(CardLib.CARD_BLACKSMITH)
	player.deck.append(CardLib.CARD_SOLDIER)  # Troop is 4th - won't be in initial hand
	player.deck.append(CardLib.CARD_ARCHER)
	player.hand.clear()

	ai.deck.clear()
	ai.deck.append(CardLib.CARD_CASTLE)
	ai.deck.append(CardLib.CARD_SOLDIER)
	ai.deck.append(CardLib.CARD_ARCHER)
	ai.hand.clear()

	var flow := TurnFlow.new()
	flow.setup(player, ai)

	# After setup, player MUST have a troop in hand
	return player.has_troop_in_hand()


func _test_turnflow_setup_guarantees_ai_troop() -> bool:
	# Create players where AI deck has no troops in first 3 cards
	var player := PlayerState.new("Player", false)
	var ai := PlayerState.new("AI", true)

	player.deck.clear()
	player.deck.append(CardLib.CARD_CASTLE)
	player.deck.append(CardLib.CARD_SOLDIER)
	player.deck.append(CardLib.CARD_ARCHER)
	player.hand.clear()

	ai.deck.clear()
	ai.deck.append(CardLib.CARD_CASTLE)
	ai.deck.append(CardLib.CARD_FARM)
	ai.deck.append(CardLib.CARD_BLACKSMITH)
	ai.deck.append(CardLib.CARD_PALADIN)  # Troop is 4th - won't be in initial hand
	ai.hand.clear()

	var flow := TurnFlow.new()
	flow.setup(player, ai)

	# After setup, AI MUST have a troop in hand
	return ai.has_troop_in_hand()


# ---------------------------------------------------------------------------
# TurnFlow.can_end_turn() tests
# ---------------------------------------------------------------------------

func _test_can_end_turn_false_without_troop_on_board() -> bool:
	var player := PlayerState.new("Player", false)
	var ai := PlayerState.new("AI", true)

	# Setup with troops in hand
	player.deck.clear()
	player.deck.append(CardLib.CARD_CASTLE)
	player.deck.append(CardLib.CARD_SOLDIER)
	player.deck.append(CardLib.CARD_ARCHER)
	player.hand.clear()

	ai.deck.clear()
	ai.deck.append(CardLib.CARD_CASTLE)
	ai.deck.append(CardLib.CARD_SOLDIER)
	ai.deck.append(CardLib.CARD_ARCHER)
	ai.hand.clear()

	var flow := TurnFlow.new()
	flow.setup(player, ai)

	# Place castle via TurnFlow to advance to PREP phase
	flow.player_place_castle(Vector2i(2, 2))

	# Verify we're in PREP phase now (AI castle is auto-placed in setup)
	if flow.get_phase() != TurnFlow.Phase.PREP:
		return false

	# No troop on board yet - should return false
	return not flow.can_end_turn()


func _test_can_end_turn_true_with_troop_on_board() -> bool:
	var player := PlayerState.new("Player", false)
	var ai := PlayerState.new("AI", true)

	# Setup with troops in hand
	player.deck.clear()
	player.deck.append(CardLib.CARD_CASTLE)
	player.deck.append(CardLib.CARD_SOLDIER)
	player.deck.append(CardLib.CARD_ARCHER)
	player.hand.clear()

	ai.deck.clear()
	ai.deck.append(CardLib.CARD_CASTLE)
	ai.deck.append(CardLib.CARD_SOLDIER)
	ai.deck.append(CardLib.CARD_ARCHER)
	ai.hand.clear()

	var flow := TurnFlow.new()
	flow.setup(player, ai)

	# Place castle via TurnFlow to advance to PREP phase
	flow.player_place_castle(Vector2i(2, 2))

	# Place soldier via TurnFlow
	flow.player_play_card(CardLib.CARD_SOLDIER, Vector2i(1, 1))

	# Should return true - troop is on board
	return flow.can_end_turn()
