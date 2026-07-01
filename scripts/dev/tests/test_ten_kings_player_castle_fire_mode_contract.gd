extends SceneTree
## Test: Player castle has two firing modes (auto/manual) with auto as default.
## AI castle is always automatic (no mode control exposed).

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")


func _init() -> void:
	var result := _run_tests()
	if result:
		print("PASS: test_ten_kings_player_castle_fire_mode_contract")
	else:
		print("FAIL: test_ten_kings_player_castle_fire_mode_contract")
	quit(0 if result else 1)


func _run_tests() -> bool:
	# Create battle manager instance
	var manager := BattleManagerScript.new()
	
	# Test 1: BattleManager should have player_castle_fire_mode property
	if not "player_castle_fire_mode" in manager:
		print("  ERROR: BattleManager missing player_castle_fire_mode property")
		return false
	print("  BattleManager has player_castle_fire_mode property")
	
	# Test 2: Default fire mode should be "auto"
	var default_mode: String = manager.player_castle_fire_mode
	if default_mode != "auto":
		print("  ERROR: Default fire mode should be 'auto', got '%s'" % default_mode)
		return false
	print("  Default fire mode is 'auto'")
	
	# Test 3: Fire mode can be set to "manual"
	manager.player_castle_fire_mode = "manual"
	var manual_mode: String = manager.player_castle_fire_mode
	if manual_mode != "manual":
		print("  ERROR: Fire mode should be settable to 'manual', got '%s'" % manual_mode)
		return false
	print("  Fire mode can be set to 'manual'")
	
	# Test 4: Fire mode can be set back to "auto"
	manager.player_castle_fire_mode = "auto"
	var auto_mode: String = manager.player_castle_fire_mode
	if auto_mode != "auto":
		print("  ERROR: Fire mode should be settable back to 'auto', got '%s'" % auto_mode)
		return false
	print("  Fire mode can be set back to 'auto'")
	
	# Test 5: BattleManager should have is_player_castle_auto_fire() method
	if not manager.has_method("is_player_castle_auto_fire"):
		print("  ERROR: BattleManager missing is_player_castle_auto_fire() method")
		return false
	print("  BattleManager has is_player_castle_auto_fire() method")
	
	# Test 6: is_player_castle_auto_fire() should return true when mode is "auto"
	manager.player_castle_fire_mode = "auto"
	if not manager.is_player_castle_auto_fire():
		print("  ERROR: is_player_castle_auto_fire() should return true for 'auto' mode")
		return false
	print("  is_player_castle_auto_fire() returns true for 'auto' mode")
	
	# Test 7: is_player_castle_auto_fire() should return false when mode is "manual"
	manager.player_castle_fire_mode = "manual"
	if manager.is_player_castle_auto_fire():
		print("  ERROR: is_player_castle_auto_fire() should return false for 'manual' mode")
		return false
	print("  is_player_castle_auto_fire() returns false for 'manual' mode")
	
	# Test 8: BattleManager should have request_manual_castle_fire(target_pos) method
	if not manager.has_method("request_manual_castle_fire"):
		print("  ERROR: BattleManager missing request_manual_castle_fire() method")
		return false
	print("  BattleManager has request_manual_castle_fire() method")
	
	# Test 9: AI castle has no fire mode control (implicit - always auto)
	# The AI castle doesn't expose a mode property; it's always automatic.
	# We verify there's no "ai_castle_fire_mode" property.
	if "ai_castle_fire_mode" in manager:
		print("  ERROR: AI castle should not have fire mode control (always auto)")
		return false
	print("  AI castle has no fire mode control (always automatic)")
	
	return true
