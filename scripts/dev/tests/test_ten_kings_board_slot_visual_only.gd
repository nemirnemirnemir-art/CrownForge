## Test: TenKingsBoardSlotUI should be visual-only (no inline text details)
extends SceneTree

const BoardSlotUIScript = preload("res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	var exit_code: int = 0 if _failed == 0 else 1
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(exit_code)


func _run_tests() -> void:
	print("Running TenKingsBoardSlotUI visual-only contract tests...")
	_test_empty_slot_has_no_text()
	_test_occupied_troop_slot_has_no_detail_text()
	_test_occupied_building_slot_has_no_detail_text()
	_test_pack_grid_visible_for_troops()
	_test_hover_signals_exist()


func _test_empty_slot_has_no_text() -> void:
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(0, 0))
	slot.update_display(BoardSlotUIScript.STATE_EMPTY, null, 0, "", 0)
	
	var label: Label = slot._info_label
	var has_text: bool = label != null and label.text.length() > 0
	
	if has_text:
		_fail("test_empty_slot_has_no_text", "Empty slot should have no text, got: '%s'" % label.text)
	else:
		_pass("test_empty_slot_has_no_text")
	
	slot.queue_free()


func _test_occupied_troop_slot_has_no_detail_text() -> void:
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(1, 1))
	
	# Simulate occupied troop slot with level, units, smith bonus, steel coat
	# OLD behavior: would show "Lv.2\nx6\n+5% dmg\nBlock 1"
	# NEW behavior: should show nothing or minimal visual-only state
	slot.update_display(BoardSlotUIScript.STATE_OCCUPIED, null, 2, "x6\n+5% dmg\nBlock 1", 6)
	
	var label: Label = slot._info_label
	var text: String = label.text if label != null else ""
	
	# Check for forbidden inline detail patterns
	var has_forbidden_text: bool = false
	var forbidden_patterns: Array[String] = ["Lv.", "xN", "x6", "% dmg", "Block"]
	for pattern: String in forbidden_patterns:
		if pattern in text:
			has_forbidden_text = true
			break
	
	if has_forbidden_text:
		_fail("test_occupied_troop_slot_has_no_detail_text", "Troop slot should not show detail text, got: '%s'" % text)
	else:
		_pass("test_occupied_troop_slot_has_no_detail_text")
	
	slot.queue_free()


func _test_occupied_building_slot_has_no_detail_text() -> void:
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(2, 2))
	
	# Simulate occupied building slot (castle, tower, etc.)
	slot.update_display(BoardSlotUIScript.STATE_OCCUPIED, null, 1, "HP 100", 0)
	
	var label: Label = slot._info_label
	var text: String = label.text if label != null else ""
	
	# Building slots should also not show inline detail text
	var has_forbidden_text: bool = "HP" in text or "Lv." in text
	
	if has_forbidden_text:
		_fail("test_occupied_building_slot_has_no_detail_text", "Building slot should not show detail text, got: '%s'" % text)
	else:
		_pass("test_occupied_building_slot_has_no_detail_text")
	
	slot.queue_free()


func _test_pack_grid_visible_for_troops() -> void:
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(3, 3))
	
	# Occupied troop slot with pack icons
	slot.update_display(BoardSlotUIScript.STATE_OCCUPIED, null, 2, "", 6)
	
	var pack_grid: GridContainer = slot._pack_grid
	# Pack grid should still be visible for troops (visual representation)
	# Note: visibility depends on having a texture, but the grid should exist
	var grid_exists: bool = pack_grid != null
	
	if not grid_exists:
		_fail("test_pack_grid_visible_for_troops", "Pack grid should exist for troop slot")
	else:
		_pass("test_pack_grid_visible_for_troops")
	
	slot.queue_free()


func _test_hover_signals_exist() -> void:
	var slot = BoardSlotUIScript.new()
	slot.setup(Vector2i(4, 4))
	
	# Check if hover signals are defined
	var has_hover_started: bool = slot.has_signal("slot_hover_started")
	var has_hover_ended: bool = slot.has_signal("slot_hover_ended")
	
	if not has_hover_started:
		_fail("test_hover_signals_exist", "Missing signal: slot_hover_started")
	elif not has_hover_ended:
		_fail("test_hover_signals_exist", "Missing signal: slot_hover_ended")
	else:
		_pass("test_hover_signals_exist")
	
	slot.queue_free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
