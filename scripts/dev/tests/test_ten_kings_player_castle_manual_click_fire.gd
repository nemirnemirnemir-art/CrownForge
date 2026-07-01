extends SceneTree
## Test: Manual castle fire respects cooldown and converts clicks to ground fire commands.
## Holding mouse should request shots repeatedly, but manager enforces cooldown.

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const ArenaGeometryScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_player_castle_manual_click_fire")
	else:
		print("FAIL: test_ten_kings_player_castle_manual_click_fire")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Setup: Create a battle with a player castle
	var manager := BattleManagerScript.new()
	var player := PlayerStateScript.new("Player", false)
	var ai_player := PlayerStateScript.new("AI", true)
	
	# Place castle on player board
	var board: RefCounted = player.board
	var castle_pos := Vector2i(2, 2)
	if not board.place_card(castle_pos, CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place player castle")
		return false
	print("  Placed player castle")
	
	# Place castle on AI board
	var ai_board: RefCounted = ai_player.board
	if not ai_board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place AI castle")
		return false
	print("  Placed AI castle")
	
	# Place a troop on player board for battle to start
	if not board.place_card(Vector2i(1, 2), CardLib.CARD_SOLDIER):
		print("  ERROR: Failed to place player soldier")
		return false
	print("  Placed player soldier")
	
	# Place a troop on AI board
	if not ai_board.place_card(Vector2i(1, 2), CardLib.CARD_SOLDIER):
		print("  ERROR: Failed to place AI soldier")
		return false
	print("  Placed AI soldier")
	
	# Setup arena geometry
	var arena_geometry := ArenaGeometryScript.new()
	arena_geometry.setup_from_viewport_rect(Rect2(0, 0, 800, 600), Vector2.ONE)
	manager.set_arena_geometry(arena_geometry)
	
	# Test 1: request_manual_castle_fire fails when mode is "auto" (default)
	manager.player_castle_fire_mode = "auto"
	var fire_result := manager.request_manual_castle_fire(Vector2(400, 300))
	if fire_result:
		print("  ERROR: request_manual_castle_fire should fail in 'auto' mode")
		return false
	print("  request_manual_castle_fire correctly fails in 'auto' mode")
	
	# Test 2: request_manual_castle_fire fails when battle is not active
	manager.player_castle_fire_mode = "manual"
	fire_result = manager.request_manual_castle_fire(Vector2(400, 300))
	if fire_result:
		print("  ERROR: request_manual_castle_fire should fail when battle not active")
		return false
	print("  request_manual_castle_fire correctly fails when battle not active")
	
	# Start the battle to make it active
	manager.start_battle(player, ai_player)
	
	# Test 3: request_manual_castle_fire succeeds when mode is "manual" and battle is active
	fire_result = manager.request_manual_castle_fire(Vector2(400, 300))
	if not fire_result:
		print("  ERROR: request_manual_castle_fire should succeed in 'manual' mode during battle")
		return false
	print("  request_manual_castle_fire succeeds in 'manual' mode during battle")
	
	# Test 4: Immediate second fire request should fail (cooldown not ready)
	fire_result = manager.request_manual_castle_fire(Vector2(400, 300))
	if fire_result:
		print("  ERROR: Immediate second fire should fail (cooldown)")
		return false
	print("  Immediate second fire correctly blocked by cooldown")
	
	# Test 5: BattleManager should have get_player_castle_cooldown_remaining() method
	if not manager.has_method("get_player_castle_cooldown_remaining"):
		print("  ERROR: BattleManager missing get_player_castle_cooldown_remaining() method")
		return false
	print("  BattleManager has get_player_castle_cooldown_remaining() method")
	
	# Test 6: Cooldown should be > 0 after firing
	var cooldown_remaining: float = manager.get_player_castle_cooldown_remaining()
	if cooldown_remaining <= 0.0:
		print("  ERROR: Cooldown should be > 0 after firing, got %f" % cooldown_remaining)
		return false
	print("  Cooldown remaining after fire: %f" % cooldown_remaining)
	
	# Test 7: BattleManager should have is_player_castle_cooldown_ready() method
	if not manager.has_method("is_player_castle_cooldown_ready"):
		print("  ERROR: BattleManager missing is_player_castle_cooldown_ready() method")
		return false
	print("  BattleManager has is_player_castle_cooldown_ready() method")
	
	# Test 8: is_player_castle_cooldown_ready() should return false when cooldown is active
	if manager.is_player_castle_cooldown_ready():
		print("  ERROR: is_player_castle_cooldown_ready() should return false during cooldown")
		return false
	print("  is_player_castle_cooldown_ready() correctly returns false during cooldown")
	
	# Cleanup
	manager.cleanup()
	
	return true
