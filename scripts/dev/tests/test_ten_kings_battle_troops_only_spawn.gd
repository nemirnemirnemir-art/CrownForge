## Test: Only troops (Soldier, Archer, Paladin) spawn into BattleLayer arena.
## Castle and Scout Tower are fixed structures, Farm/Blacksmith are support-only.
extends SceneTree


const BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

## Troop card IDs that SHOULD spawn in arena.
const TROOP_CARDS: Array[StringName] = [
	CardLib.CARD_SOLDIER,
	CardLib.CARD_ARCHER,
	CardLib.CARD_PALADIN,
]


func _init() -> void:
	print("Running TenKingsBattleManager troops-only spawn tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: Only troop cards appear in _player_units and _ai_units
	if _test_only_troops_spawn_in_arena():
		print("  PASS: test_only_troops_spawn_in_arena")
		passed += 1
	else:
		print("  FAIL: test_only_troops_spawn_in_arena")
		failed += 1

	# Test 2: Castle card_id not found in spawned arena units
	if _test_castle_not_in_arena_units():
		print("  PASS: test_castle_not_in_arena_units")
		passed += 1
	else:
		print("  FAIL: test_castle_not_in_arena_units")
		failed += 1

	# Test 3: Scout tower card_id not found in spawned arena units
	if _test_scout_tower_not_in_arena_units():
		print("  PASS: test_scout_tower_not_in_arena_units")
		passed += 1
	else:
		print("  FAIL: test_scout_tower_not_in_arena_units")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


func _test_only_troops_spawn_in_arena() -> bool:
	# After battle start, _player_units and _ai_units should contain ONLY troop cards.
	# Castle and Scout Tower should NOT appear in these arrays.
	var manager := BattleManager.new()
	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Player places: castle, soldier, archer, scout_tower
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	player.ensure_card_in_hand(CardLib.CARD_SOLDIER)
	player.play_card(CardLib.CARD_SOLDIER, Vector2i(1, 1))

	player.ensure_card_in_hand(CardLib.CARD_ARCHER)
	player.play_card(CardLib.CARD_ARCHER, Vector2i(1, 2))

	player.ensure_card_in_hand(CardLib.CARD_SCOUT_TOWER)
	player.play_card(CardLib.CARD_SCOUT_TOWER, Vector2i(1, 3))

	# AI places: castle, paladin
	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	ai_player.ensure_card_in_hand(CardLib.CARD_PALADIN)
	ai_player.play_card(CardLib.CARD_PALADIN, Vector2i(1, 1))

	manager.start_battle(player, ai_player, {}, {})

	# Check _player_units contains only troops (no castle, no scout_tower)
	var player_units: Array = manager.get("_player_units")
	var ai_units: Array = manager.get("_ai_units")

	var all_player_are_troops: bool = true
	for unit: Node2D in player_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id not in TROOP_CARDS:
			all_player_are_troops = false
			break

	var all_ai_are_troops: bool = true
	for unit: Node2D in ai_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id not in TROOP_CARDS:
			all_ai_are_troops = false
			break

	manager.cleanup()
	manager.free()

	# This test expects to FAIL with current implementation because castle/scout_tower
	# are spawned into arena units. The new contract says they should NOT be.
	return all_player_are_troops and all_ai_are_troops


func _test_castle_not_in_arena_units() -> bool:
	# Castle card_id should NOT be found in spawned _player_units or _ai_units.
	var manager := BattleManager.new()
	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Both players place castle
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	manager.start_battle(player, ai_player, {}, {})

	var player_units: Array = manager.get("_player_units")
	var ai_units: Array = manager.get("_ai_units")

	var castle_found_in_player: bool = false
	for unit: Node2D in player_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id == CardLib.CARD_CASTLE:
			castle_found_in_player = true
			break

	var castle_found_in_ai: bool = false
	for unit: Node2D in ai_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id == CardLib.CARD_CASTLE:
			castle_found_in_ai = true
			break

	manager.cleanup()
	manager.free()

	# Test passes if castle is NOT found in either array.
	# This will FAIL with current implementation.
	return not castle_found_in_player and not castle_found_in_ai


func _test_scout_tower_not_in_arena_units() -> bool:
	# Scout tower card_id should NOT be found in spawned _player_units or _ai_units.
	var manager := BattleManager.new()
	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Player places castle and scout_tower
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	player.ensure_card_in_hand(CardLib.CARD_SCOUT_TOWER)
	player.play_card(CardLib.CARD_SCOUT_TOWER, Vector2i(1, 2))

	# AI places castle
	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	manager.start_battle(player, ai_player, {}, {})

	var player_units: Array = manager.get("_player_units")

	var scout_tower_found: bool = false
	for unit: Node2D in player_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id == CardLib.CARD_SCOUT_TOWER:
			scout_tower_found = true
			break

	manager.cleanup()
	manager.free()

	# Test passes if scout_tower is NOT found in arena units.
	# This will FAIL with current implementation.
	return not scout_tower_found
