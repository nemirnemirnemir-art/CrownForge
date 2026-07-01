## Test: Battle lane readability - units deploy from slots, formation inside corridor, chase to castle.
extends SceneTree


const BattleManager = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerState = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	print("Running TenKingsBattleManager lane readability tests...")
	var passed: int = 0
	var failed: int = 0

	# Test 1: Units deploy from board-slot origins
	if _test_units_deploy_from_slot_origins():
		print("  PASS: test_units_deploy_from_slot_origins")
		passed += 1
	else:
		print("  FAIL: test_units_deploy_from_slot_origins")
		failed += 1

	# Test 2: Formation targets end up inside corridor
	if _test_formation_targets_inside_corridor():
		print("  PASS: test_formation_targets_inside_corridor")
		passed += 1
	else:
		print("  FAIL: test_formation_targets_inside_corridor")
		failed += 1

	# Test 3: Battle manager can use anchor positions for formation
	if _test_manager_uses_anchors_for_formation():
		print("  PASS: test_manager_uses_anchors_for_formation")
		passed += 1
	else:
		print("  FAIL: test_manager_uses_anchors_for_formation")
		failed += 1

	# Test 4: Castle contact anchors are used for siege targeting
	if _test_siege_uses_castle_contact_anchors():
		print("  PASS: test_siege_uses_castle_contact_anchors")
		passed += 1
	else:
		print("  FAIL: test_siege_uses_castle_contact_anchors")
		failed += 1

	print("")
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(failed)


func _test_units_deploy_from_slot_origins() -> bool:
	# This test verifies that start_battle can spawn units from boards.
	# We place units on layer-0/layer-1 slots which are unlocked by default.
	var manager := BattleManager.new()
	var player := PlayerState.new("Player", false)
	var ai_player := PlayerState.new("AI", true)

	# Place castle at center (layer 0 = always unlocked)
	player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	# Place soldier on layer 1 slot (1,1) which is unlocked by default
	player.ensure_card_in_hand(CardLib.CARD_SOLDIER)
	var soldier_placed: bool = player.play_card(CardLib.CARD_SOLDIER, Vector2i(1, 1))

	# AI places castle
	ai_player.ensure_card_in_hand(CardLib.CARD_CASTLE)
	ai_player.play_card(CardLib.CARD_CASTLE, Vector2i(2, 2))

	# Define slot origins
	var player_origins: Dictionary = {
		Vector2i(1, 1): Vector2(-200, -100),
		Vector2i(2, 2): Vector2(-200, 0),
	}
	var ai_origins: Dictionary = {
		Vector2i(2, 2): Vector2(200, 0),
	}

	manager.start_battle(player, ai_player, player_origins, ai_origins)

	# Verify units were spawned
	var player_units: Array = manager.get_surviving_units(0)
	var has_soldier: bool = false
	for unit: Node2D in player_units:
		var pos: Vector2i = unit.get_meta("board_pos", Vector2i(-1, -1))
		if pos == Vector2i(1, 1):
			has_soldier = true
			break

	manager.cleanup()
	manager.free()
	return soldier_placed and has_soldier


func _test_formation_targets_inside_corridor() -> bool:
	# Formation targets should be inside the corridor (roughly between -90 and +90 x)
	var manager := BattleManager.new()

	# Set anchors that define the corridor
	var anchors: Dictionary = {
		"player_front": Vector2(-90, 0),
		"player_ranged": Vector2(-140, 0),
		"player_back": Vector2(-190, 0),
		"ai_front": Vector2(90, 0),
		"ai_ranged": Vector2(140, 0),
		"ai_back": Vector2(190, 0),
		"player_castle_contact": Vector2(-220, 0),
		"ai_castle_contact": Vector2(220, 0),
	}
	manager.set_arena_anchors(anchors)

	# Battle manager should have a method to get formation anchor for a unit type
	var has_method: bool = manager.has_method("get_formation_x_for_unit_type")
	manager.free()
	return has_method


func _test_manager_uses_anchors_for_formation() -> bool:
	# Battle manager should use anchor-derived positions for formation
	var manager := BattleManager.new()

	var anchors: Dictionary = {
		"player_front": Vector2(-90, 0),
		"player_ranged": Vector2(-140, 0),
		"player_back": Vector2(-190, 0),
		"ai_front": Vector2(90, 0),
		"ai_ranged": Vector2(140, 0),
		"ai_back": Vector2(190, 0),
		"player_castle_contact": Vector2(-220, 0),
		"ai_castle_contact": Vector2(220, 0),
	}
	manager.set_arena_anchors(anchors)

	# Check that melee formation x for player is near player_front anchor
	if not manager.has_method("get_formation_x_for_unit_type"):
		manager.free()
		return false

	var melee_x: float = manager.get_formation_x_for_unit_type(0, false, false)  # side=0, not ranged, not building
	var ranged_x: float = manager.get_formation_x_for_unit_type(0, true, false)  # side=0, ranged
	var building_x: float = manager.get_formation_x_for_unit_type(0, false, true)  # side=0, building

	# Player side should have negative x (left of center)
	# Melee should be closest to center, ranged further, building furthest
	var valid_melee: bool = melee_x < 0 and melee_x > -100
	var valid_ranged: bool = ranged_x < melee_x
	var valid_building: bool = building_x < ranged_x

	manager.free()
	return valid_melee and valid_ranged and valid_building


func _test_siege_uses_castle_contact_anchors() -> bool:
	# Battle manager should have castle contact anchors for siege finish zone
	var manager := BattleManager.new()

	var anchors: Dictionary = {
		"player_front": Vector2(-90, 0),
		"ai_front": Vector2(90, 0),
		"player_castle_contact": Vector2(-220, 0),
		"ai_castle_contact": Vector2(220, 0),
	}
	manager.set_arena_anchors(anchors)

	# Manager should be able to get castle contact position for a side
	var has_method: bool = manager.has_method("get_castle_contact_position")
	if not has_method:
		manager.free()
		return false

	var player_contact: Vector2 = manager.get_castle_contact_position(0)
	var ai_contact: Vector2 = manager.get_castle_contact_position(1)

	# Player castle contact should match anchor
	var valid: bool = player_contact.x == -220.0 and ai_contact.x == 220.0
	manager.free()
	return valid
