extends SceneTree
## Test: Structure projectile origins follow the correct policy

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const ArenaGeometryScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_structure_projectile_origins")
	else:
		print("FAIL: test_ten_kings_structure_projectile_origins")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Setup: Create a prototype to test origin helpers
	var proto_scene = load("res://scenes/dev/TenKingsPrototype.tscn")
	if proto_scene == null:
		print("  ERROR: TenKingsPrototype.tscn not found")
		return false
	
	var proto = proto_scene.instantiate()
	var root = Node.new()
	root.add_child(proto)
	proto.notification(Node.NOTIFICATION_READY)
	
	# Create states
	var player := PlayerStateScript.new("Player", false)
	var ai_player := PlayerStateScript.new("AI", true)
	
	# Place player castle and scout tower
	var player_board: RefCounted = player.board
	if not player_board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place player castle")
		return false
	print("  ✓ Placed player castle at (2, 2)")
	
	if not player_board.place_card(Vector2i(1, 2), &"scout_tower"):
		print("  ERROR: Failed to place scout tower")
		return false
	print("  ✓ Placed scout tower at (1, 2)")
	
	# Place AI structures
	var ai_board: RefCounted = ai_player.board
	if not ai_board.place_card(Vector2i(2, 2), CardLib.CARD_CASTLE):
		print("  ERROR: Failed to place AI castle")
		return false
	if not ai_board.place_card(Vector2i(1, 2), &"scout_tower"):
		print("  ERROR: Failed to place AI scout tower")
		return false
	print("  ✓ Placed AI structures")
	
	# Test origin helpers exist on prototype
	if not proto.has_method("get_fixed_shooter_origin"):
		print("  ERROR: TenKingsPrototype missing get_fixed_shooter_origin method")
		return false
	print("  ✓ TenKingsPrototype has get_fixed_shooter_origin method")
	
	# Test player castle origin (should use real board slot position)
	var player_castle_origin = proto.get_fixed_shooter_origin(0, CardLib.CARD_CASTLE)
	if player_castle_origin == Vector2.ZERO:
		print("  WARNING: Player castle origin is zero (expected real position)")
	else:
		print("  ✓ Player castle origin: ", player_castle_origin)
	
	# Test player scout tower origin
	var player_tower_origin = proto.get_fixed_shooter_origin(0, &"scout_tower")
	if player_tower_origin == Vector2.ZERO:
		print("  WARNING: Player scout tower origin is zero (expected real position)")
	else:
		print("  ✓ Player scout tower origin: ", player_tower_origin)
	
	# Test AI origins are offscreen right (should be different from player positions)
	var ai_castle_origin = proto.get_fixed_shooter_origin(1, CardLib.CARD_CASTLE)
	var ai_tower_origin = proto.get_fixed_shooter_origin(1, &"scout_tower")
	
	if ai_castle_origin.x <= 0:
		print("  ERROR: AI castle origin X coordinate should be positive (offscreen right)")
		return false
	print("  ✓ AI castle origin offscreen right: ", ai_castle_origin)
	
	if ai_tower_origin.x <= 0:
		print("  ERROR: AI scout tower origin X coordinate should be positive (offscreen right)")
		return false
	print("  ✓ AI scout tower origin offscreen right: ", ai_tower_origin)
	
	# Test that AI origins have reasonable Y coordinates (vertically centered)
	if ai_castle_origin.y < -500 or ai_castle_origin.y > 500:
		print("  ERROR: AI castle Y seems out of bounds: ", ai_castle_origin.y)
		return false
	print("  ✓ AI castle Y in valid range")
	
	root.queue_free()
	return true

