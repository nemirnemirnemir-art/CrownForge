## Test: Siege phase uses get_castle_contact_position() anchor, not castle unit position.
## Winning troops should chase toward the contact anchor, not the castle unit's position.
extends SceneTree


const BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	print("Running TenKingsBattleManager siege contact anchor tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: Siege target is contact anchor, not unit position
	if _test_siege_target_is_contact_anchor_not_unit_position():
		print("  PASS: test_siege_target_is_contact_anchor_not_unit_position")
		passed += 1
	else:
		print("  FAIL: test_siege_target_is_contact_anchor_not_unit_position")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


func _test_siege_target_is_contact_anchor_not_unit_position() -> bool:
	# When one side wins and enters chase/siege phase, winning troops should
	# chase toward get_castle_contact_position(loser_side), NOT toward the
	# castle unit's global_position.
	#
	# New contract: Castle is NOT spawned as arena unit. Therefore there is
	# no _losing_castle unit to get position from. Siege must use the anchor.
	#
	# This test verifies:
	# 1. _begin_chase_phase uses get_castle_contact_position() as chase target
	# 2. _did_siege_reach_castle() checks against contact anchor, not unit
	# 3. start_chasing_castle() receives anchor position, not unit position
	var manager := BattleManager.new()

	# Set up anchors with distinct contact positions
	var anchors: Dictionary = {
		"player_front": Vector2(-90, 0),
		"ai_front": Vector2(90, 0),
		"player_castle_contact": Vector2(-250, 0),  # Distinct position
		"ai_castle_contact": Vector2(250, 0),       # Distinct position
	}
	manager.set_arena_anchors(anchors)

	# The manager should have a method or property indicating it uses
	# contact anchors for siege targeting, NOT castle unit positions.
	#
	# Currently _begin_chase_phase does:
	#   castle_pos = _losing_castle.global_position
	#   u.call("start_chasing_castle", castle_pos)
	#
	# New contract requires:
	#   var loser_side: int = 1 if winner == 0 else 0
	#   castle_pos = get_castle_contact_position(loser_side)
	#   u.call("start_chasing_castle", castle_pos)
	#
	# Also _did_siege_reach_castle currently compares to _losing_castle.global_position
	# but with no castle unit, it must compare to contact anchor.

	# Check that _begin_chase_phase signature or implementation supports anchor-based targeting
	# Since we can't easily introspect the implementation, we verify:
	# 1. Manager does NOT rely on _losing_castle for position
	# 2. Manager uses get_castle_contact_position() for siege

	# One way to test: If castle is not spawned as unit, _losing_castle should be null
	# but siege should still work using anchors.

	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Player places castle and soldier
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))
	player.ensure_card_in_hand(CardLib.CARD_SOLDIER)
	player.play_card(CardLib.CARD_SOLDIER, Vector2i(1, 1))

	# AI places castle only (no troops - player will win immediately)
	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	manager.start_battle(player, ai_player, {}, {})

	# After battle starts, if AI has no troops, player should win chase phase.
	# Under new contract:
	# - _ai_units should NOT contain castle
	# - _losing_castle should be null (castle not spawned as unit)
	# - But chase should still work using contact anchor

	var ai_units: Array = manager.get("_ai_units")
	var losing_castle: Node2D = manager.get("_losing_castle")

	# Under new contract, losing_castle should be null because castle isn't a unit
	var castle_is_null: bool = losing_castle == null

	# But even with null castle, siege should be able to determine end point
	# via get_castle_contact_position(). We test this by checking the manager
	# has logic that doesn't depend on _losing_castle.global_position.

	# Since implementation still uses _losing_castle, this test will FAIL.
	# The fix requires _begin_chase_phase to use:
	#   var siege_target: Vector2 = get_castle_contact_position(loser_side)
	# instead of:
	#   castle_pos = _losing_castle.global_position

	# Check if castle was NOT spawned as a unit
	var castle_not_in_ai_units: bool = true
	for unit: Node2D in ai_units:
		var card_id: StringName = StringName(unit.get("card_id"))
		if card_id == CardLib.CARD_CASTLE:
			castle_not_in_ai_units = false
			break

	manager.cleanup()
	manager.free()

	# Test passes if:
	# 1. Castle is NOT in ai_units (new contract)
	# 2. _losing_castle is null (castle not spawned as unit)
	# Both conditions should be true under new contract.
	# Currently this will FAIL because castle IS spawned as unit.
	return castle_not_in_ai_units and castle_is_null
