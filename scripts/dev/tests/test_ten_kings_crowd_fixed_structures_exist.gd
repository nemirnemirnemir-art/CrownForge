extends SceneTree
## Test: CrowdBuilder returns both soldiers and fixed structures properly.
## Fixed structures (castle, scout_tower) should be tracked separately from soldiers.

const CrowdBuilderScript = preload("res://scripts/dev/ten_kings/TenKingsCrowdBuilder.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const ArenaGeometryScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_crowd_fixed_structures_exist")
	else:
		print("FAIL: test_ten_kings_crowd_fixed_structures_exist")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Test 1: Build a board with castle, scout_tower, and troops
	var board := BoardStateScript.new()
	
	# Layer 0 (center) and Layer 1 (inner ring) are already EMPTY by default
	# Layer 0: (2,2)
	# Layer 1: (1,1), (2,1), (3,1), (1,2), (3,2), (1,3), (2,3), (3,3)
	
	# Place castle at center
	var castle_pos := Vector2i(2, 2)
	if not board.place_card(castle_pos, CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place castle")
		return false
	print("  Placed castle at %s" % str(castle_pos))
	
	# Place scout tower in layer 1
	var tower_pos := Vector2i(1, 2)
	if not board.place_card(tower_pos, CardLib.CARD_SCOUT_TOWER):
		print("  ERROR: Failed to place scout_tower")
		return false
	print("  Placed scout_tower at %s" % str(tower_pos))
	
	# Place soldier troop in layer 1
	var soldier_pos := Vector2i(3, 2)
	if not board.place_card(soldier_pos, CardLib.CARD_SOLDIER):
		print("  ERROR: Failed to place soldier")
		return false
	print("  Placed soldier at %s" % str(soldier_pos))
	
	# Setup arena geometry
	var arena_geometry := ArenaGeometryScript.new()
	arena_geometry.setup_from_viewport_rect(Rect2(0, 0, 800, 600), Vector2.ONE)
	
	# Expand stacks using CrowdBuilder
	var builder := CrowdBuilderScript.new()
	var result: Variant = builder.expand_stacks_to_soldiers(board, 0, arena_geometry)
	
	# Test 2: Result should be a Dictionary with soldiers and fixed_structures keys
	if not (result is Dictionary):
		print("  ERROR: expand_stacks_to_soldiers should return Dictionary, got %s" % typeof(result))
		return false
	print("  expand_stacks_to_soldiers returned Dictionary")
	
	var result_dict: Dictionary = result as Dictionary
	
	if not result_dict.has("soldiers"):
		print("  ERROR: Result missing 'soldiers' key")
		return false
	print("  Result has 'soldiers' key")
	
	if not result_dict.has("fixed_structures"):
		print("  ERROR: Result missing 'fixed_structures' key")
		return false
	print("  Result has 'fixed_structures' key")
	
	var soldiers: Array = result_dict["soldiers"]
	var fixed_structures: Array = result_dict["fixed_structures"]
	
	# Test 3: Should have some soldiers from the troop
	if soldiers.is_empty():
		print("  ERROR: No soldiers returned")
		return false
	print("  Got %d soldiers" % soldiers.size())
	
	# Test 4: Should have 2 fixed structures (castle + scout_tower)
	if fixed_structures.size() != 2:
		print("  ERROR: Expected 2 fixed structures, got %d" % fixed_structures.size())
		return false
	print("  Got %d fixed structures" % fixed_structures.size())
	
	# Test 5: Each fixed structure should have required fields
	for structure in fixed_structures:
		if not structure.has("card_id"):
			print("  ERROR: Fixed structure missing card_id")
			return false
		if not structure.has("source_slot"):
			print("  ERROR: Fixed structure missing source_slot")
			return false
		if not structure.has("side"):
			print("  ERROR: Fixed structure missing side")
			return false
		if not structure.has("position"):
			print("  ERROR: Fixed structure missing position")
			return false
		if not structure.has("attack_dmg"):
			print("  ERROR: Fixed structure missing attack_dmg")
			return false
		if not structure.has("attack_cd"):
			print("  ERROR: Fixed structure missing attack_cd")
			return false
		if not structure.has("attack_range"):
			print("  ERROR: Fixed structure missing attack_range")
			return false
		print("  Fixed structure '%s' has all required fields" % structure["card_id"])
	
	# Test 6: Verify source_slot is preserved
	var castle_found := false
	var tower_found := false
	for structure in fixed_structures:
		var card_id: StringName = structure["card_id"]
		var source_slot: Vector2i = structure["source_slot"]
		if card_id == CardLib.CARD_CASTLE:
			castle_found = true
			if source_slot != castle_pos:
				print("  ERROR: Castle source_slot %s != expected %s" % [source_slot, castle_pos])
				return false
		elif card_id == CardLib.CARD_SCOUT_TOWER:
			tower_found = true
			if source_slot != tower_pos:
				print("  ERROR: Scout tower source_slot %s != expected %s" % [source_slot, tower_pos])
				return false
	
	if not castle_found:
		print("  ERROR: Castle not found in fixed_structures")
		return false
	if not tower_found:
		print("  ERROR: Scout tower not found in fixed_structures")
		return false
	print("  All fixed structures have correct source_slot")
	
	return true
