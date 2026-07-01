extends SceneTree
## Test: Board forbids placing a second castle while allowing upgrades and other placements

const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_no_second_castle")
	else:
		print("FAIL: test_ten_kings_no_second_castle")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Create a fresh board
	var board = BoardStateScript.new()
	
	# Test 1: Place first castle on (2, 2)
	if not board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place first castle at (2, 2)")
		return false
	print("  ✓ Placed first castle at (2, 2)")
	
	# Test 2: Attempt to place second castle on different slot - should FAIL
	if board.place_card(Vector2i(3, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Board allowed placement of second castle on different slot")
		return false
	print("  ✓ Correctly rejected second castle on different slot")
	
	# Test 3: Place non-castle card - should SUCCEED
	# Use layer 1 slots that are available: (1,1), (3,3), etc.
	if not board.place_card(Vector2i(1, 1), CardLib.CARD_SCOUT_TOWER):
		print("  ERROR: Failed to place non-castle card")
		return false
	print("  ✓ Successfully placed scout tower (non-castle card)")
	
	# Test 4: Place another non-castle card - should SUCCEED
	if not board.place_card(Vector2i(3, 3), CardLib.CARD_FARM):
		print("  ERROR: Failed to place second non-castle card")
		return false
	print("  ✓ Successfully placed farm (another non-castle card)")
	
	# Test 5: Attempt castle upgrade on existing castle slot - should SUCCEED
	# (assuming upgrade rules allow it; we test what we can place, not upgrade logic)
	if not board.can_place_card(Vector2i(2, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Castle upgrade validation failed - can_place_card returned false")
		return false
	print("  ✓ Castle upgrades allowed on existing castle slot")
	
	return true

