## Test: Fixed structures (Castle, Scout Tower) can attack without being arena units.
## They stay in fixed positions and provide fire support via a separate mechanism.
extends SceneTree


const BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	print("Running TenKingsBattleManager fixed structures fire support tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: Castle can attack without being an arena unit
	if _test_castle_can_attack_without_being_arena_unit():
		print("  PASS: test_castle_can_attack_without_being_arena_unit")
		passed += 1
	else:
		print("  FAIL: test_castle_can_attack_without_being_arena_unit")
		failed += 1

	# Test 2: Scout tower can attack without being an arena unit
	if _test_scout_tower_can_attack_without_being_arena_unit():
		print("  PASS: test_scout_tower_can_attack_without_being_arena_unit")
		passed += 1
	else:
		print("  FAIL: test_scout_tower_can_attack_without_being_arena_unit")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


func _test_castle_can_attack_without_being_arena_unit() -> bool:
	# The battle manager should have a mechanism for fixed structures to attack
	# even though they are not spawned as arena units in _player_units/_ai_units.
	#
	# New contract: Castle stays fixed, does NOT deploy tween into arena,
	# but still provides ranged fire support.
	#
	# This requires:
	# 1. A separate registry for fixed structures (e.g., _player_fixed_structures)
	# 2. Or a method like get_fixed_structure_attackers(side)
	# 3. Fixed structures should still have attack logic triggered
	var manager := BattleManager.new()

	# Check for fixed structure support mechanism
	var has_fixed_structure_registry: bool = (
		manager.has_method("get_fixed_structure_attackers") or
		manager.has_method("register_fixed_structure") or
		manager.get("_player_fixed_structures") != null or
		manager.get("_ai_fixed_structures") != null
	)

	manager.free()

	# This will FAIL because the mechanism doesn't exist yet.
	# Current implementation spawns castle as arena unit instead.
	return has_fixed_structure_registry


func _test_scout_tower_can_attack_without_being_arena_unit() -> bool:
	# Scout Tower should also be a fixed structure that can attack
	# without being in _player_units/_ai_units.
	#
	# Same requirements as castle:
	# - Not spawned into arena as a unit
	# - Still provides fire support
	# - Has a mechanism to target and attack enemy troops
	var manager := BattleManager.new()
	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Place castle and scout_tower
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	player.ensure_card_in_hand(CardLib.CARD_SCOUT_TOWER)
	player.play_card(CardLib.CARD_SCOUT_TOWER, Vector2i(1, 2))

	# AI places castle and soldier (target for scout tower)
	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	ai_player.ensure_card_in_hand(CardLib.CARD_SOLDIER)
	ai_player.play_card(CardLib.CARD_SOLDIER, Vector2i(1, 1))

	manager.start_battle(player, ai_player, {}, {})

	# Scout tower should NOT be in _player_units
	var player_units: Array = manager.get("_player_units")
	var scout_tower_in_arena: bool = false
	for unit: Node2D in player_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id == CardLib.CARD_SCOUT_TOWER:
			scout_tower_in_arena = true
			break

	# There should be a separate mechanism for fixed structure attacks
	var has_fixed_attack_mechanism: bool = (
		manager.has_method("get_fixed_structure_attackers") or
		manager.has_method("process_fixed_structure_attacks") or
		manager.get("_player_fixed_structures") != null
	)

	manager.cleanup()
	manager.free()

	# Test passes if:
	# 1. Scout tower is NOT in arena units
	# 2. There IS a mechanism for fixed structure attacks
	# Currently this will FAIL because scout tower IS in arena units
	# and there is no fixed structure mechanism.
	return not scout_tower_in_arena and has_fixed_attack_mechanism
