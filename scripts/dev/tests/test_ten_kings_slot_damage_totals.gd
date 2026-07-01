extends SceneTree
## Test: Per-slot battle damage totals are tracked and cleared correctly

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_slot_damage_totals")
	else:
		print("FAIL: test_ten_kings_slot_damage_totals")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Create a minimal proto scene to test damage totals tracking
	var proto_scene = load("res://scenes/dev/TenKingsPrototype.tscn")
	if proto_scene == null:
		print("  ERROR: TenKingsPrototype.tscn not found")
		return false
	
	var proto = proto_scene.instantiate()
	var root = Node.new()
	root.add_child(proto)
	proto.notification(Node.NOTIFICATION_READY)
	
	# Test 1: Verify battle manager exists and has damage total tracking
	if proto._battle_manager == null:
		print("  ERROR: Battle manager not initialized")
		return false
	print("  ✓ Battle manager initialized")
	
	# Test 2: Verify damage tracking dictionaries exist
	if not proto._battle_manager.has_method("get_slot_damage_total"):
		print("  ERROR: Battle manager missing get_slot_damage_total method")
		return false
	print("  ✓ Battle manager has get_slot_damage_total method")
	
	# Test 3: Damage totals should be 0 before any battle
	var player_total = proto._battle_manager.get_slot_damage_total(0, Vector2i(1, 1))
	var ai_total = proto._battle_manager.get_slot_damage_total(1, Vector2i(1, 1))
	if player_total != 0 or ai_total != 0:
		print("  ERROR: Damage totals not initialized to 0")
		print("    Player slot (1,1): ", player_total, ", AI slot (1,1): ", ai_total)
		return false
	print("  ✓ Damage totals initialized to 0")
	
	# Test 4: Manually increment damage for a slot
	proto._battle_manager.call("_record_slot_damage", 0, Vector2i(1, 1), 25)
	var updated_total = proto._battle_manager.get_slot_damage_total(0, Vector2i(1, 1))
	if updated_total != 25:
		print("  ERROR: Damage total not updated correctly")
		print("    Expected: 25, Got: ", updated_total)
		return false
	print("  ✓ Damage total updated correctly (25)")
	
	# Test 5: Increment again to test accumulation
	proto._battle_manager.call("_record_slot_damage", 0, Vector2i(1, 1), 15)
	updated_total = proto._battle_manager.get_slot_damage_total(0, Vector2i(1, 1))
	if updated_total != 40:
		print("  ERROR: Damage total not accumulated correctly")
		print("    Expected: 40, Got: ", updated_total)
		return false
	print("  ✓ Damage totals accumulated correctly (25 + 15 = 40)")
	
	# Test 6: Different slots should have separate totals
	proto._battle_manager.call("_record_slot_damage", 0, Vector2i(2, 2), 50)
	var slot_2_2_total = proto._battle_manager.get_slot_damage_total(0, Vector2i(2, 2))
	var slot_1_1_total = proto._battle_manager.get_slot_damage_total(0, Vector2i(1, 1))
	if slot_2_2_total != 50 or slot_1_1_total != 40:
		print("  ERROR: Different slots not tracked separately")
		print("    Slot (1,1): ", slot_1_1_total, " (expected 40), Slot (2,2): ", slot_2_2_total, " (expected 50)")
		return false
	print("  ✓ Different slots tracked separately")
	
	# Test 7: Clear totals (simulate next battle start)
	proto._battle_manager.call("_clear_damage_totals")
	var cleared_total_1_1 = proto._battle_manager.get_slot_damage_total(0, Vector2i(1, 1))
	var cleared_total_2_2 = proto._battle_manager.get_slot_damage_total(0, Vector2i(2, 2))
	if cleared_total_1_1 != 0 or cleared_total_2_2 != 0:
		print("  ERROR: Damage totals not cleared")
		print("    Slot (1,1): ", cleared_total_1_1, ", Slot (2,2): ", cleared_total_2_2)
		return false
	print("  ✓ Damage totals cleared correctly")
	
	root.queue_free()
	return true
