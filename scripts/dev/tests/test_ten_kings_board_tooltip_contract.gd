## Test: TenKingsBoardTooltip contract
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run_tests()
	var exit_code: int = 0 if _failed == 0 else 1
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(exit_code)


func _run_tests() -> void:
	print("Running TenKingsBoardTooltip contract tests...")
	_test_tooltip_scene_exists()
	_test_tooltip_starts_hidden()
	_test_tooltip_can_show_for_slot()
	_test_tooltip_can_hide()
	_test_tooltip_payload_troop()
	_test_tooltip_payload_building()
	_test_tooltip_payload_castle()


func _test_tooltip_scene_exists() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_scene_exists", "Scene not found: %s" % scene_path)
		return
	
	var scene: PackedScene = load(scene_path)
	if scene == null:
		_fail("test_tooltip_scene_exists", "Failed to load scene")
		return
	
	var instance: Control = scene.instantiate()
	if instance == null:
		_fail("test_tooltip_scene_exists", "Failed to instantiate tooltip")
		return
	
	_pass("test_tooltip_scene_exists")
	instance.queue_free()


func _test_tooltip_starts_hidden() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_starts_hidden", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	# Tooltip should start hidden
	if instance.visible:
		_fail("test_tooltip_starts_hidden", "Tooltip should start hidden")
	else:
		_pass("test_tooltip_starts_hidden")
	
	instance.queue_free()


func _test_tooltip_can_show_for_slot() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_can_show_for_slot", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	# Check if show_for_slot method exists
	if not instance.has_method("show_for_slot"):
		_fail("test_tooltip_can_show_for_slot", "Missing method: show_for_slot")
		instance.queue_free()
		return
	
	# Call show_for_slot with test payload
	var details: Dictionary = {
		"display_name": "Test Card",
		"level": 2,
		"units": 6
	}
	instance.call("show_for_slot", details, Vector2(100, 100))
	
	if not instance.visible:
		_fail("test_tooltip_can_show_for_slot", "Tooltip should be visible after show_for_slot")
	else:
		_pass("test_tooltip_can_show_for_slot")
	
	instance.queue_free()


func _test_tooltip_can_hide() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_can_hide", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	if not instance.has_method("hide_tooltip"):
		_fail("test_tooltip_can_hide", "Missing method: hide_tooltip")
		instance.queue_free()
		return
	
	# Show then hide
	var details: Dictionary = {"display_name": "Test"}
	instance.call("show_for_slot", details, Vector2(100, 100))
	instance.call("hide_tooltip")
	
	if instance.visible:
		_fail("test_tooltip_can_hide", "Tooltip should be hidden after hide_tooltip")
	else:
		_pass("test_tooltip_can_hide")
	
	instance.queue_free()


func _test_tooltip_payload_troop() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_payload_troop", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	# Troop payload should include units, smith bonus, steel coat
	var details: Dictionary = {
		"display_name": "Paladin",
		"level": 2,
		"units": 6,
		"smith_bonus": 0.05,
		"steel_coat_stacks": 2
	}
	instance.call("show_for_slot", details, Vector2(100, 100))
	
	# Check that the tooltip displays key information
	var body_label: Label = instance.get_node_or_null("Margin/VBox/BodyLabel")
	if body_label == null:
		_fail("test_tooltip_payload_troop", "Missing BodyLabel node")
		instance.queue_free()
		return
	
	var body_text: String = body_label.text
	var has_units: bool = "Units" in body_text or "6" in body_text
	var has_level: bool = "Level" in body_text or "2" in body_text
	
	if not has_units:
		_fail("test_tooltip_payload_troop", "Tooltip should show units count")
	elif not has_level:
		_fail("test_tooltip_payload_troop", "Tooltip should show level")
	else:
		_pass("test_tooltip_payload_troop")
	
	instance.queue_free()


func _test_tooltip_payload_building() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_payload_building", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	# Building payload (e.g., Scout Tower)
	var details: Dictionary = {
		"display_name": "Scout Tower",
		"level": 1,
		"is_building": true
	}
	instance.call("show_for_slot", details, Vector2(100, 100))
	
	var title_label: Label = instance.get_node_or_null("Margin/VBox/TitleLabel")
	if title_label == null:
		_fail("test_tooltip_payload_building", "Missing TitleLabel node")
		instance.queue_free()
		return
	
	if "Scout Tower" not in title_label.text:
		_fail("test_tooltip_payload_building", "Tooltip should show building name")
	else:
		_pass("test_tooltip_payload_building")
	
	instance.queue_free()


func _test_tooltip_payload_castle() -> void:
	var scene_path := "res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn"
	if not ResourceLoader.exists(scene_path):
		_fail("test_tooltip_payload_castle", "Scene not found")
		return
	
	var instance: Control = load(scene_path).instantiate()
	
	# Castle payload should show HP
	var details: Dictionary = {
		"display_name": "Castle",
		"level": 1,
		"is_castle": true,
		"castle_hp": 100
	}
	instance.call("show_for_slot", details, Vector2(100, 100))
	
	var body_label: Label = instance.get_node_or_null("Margin/VBox/BodyLabel")
	if body_label == null:
		_fail("test_tooltip_payload_castle", "Missing BodyLabel node")
		instance.queue_free()
		return
	
	var body_text: String = body_label.text
	if "HP" not in body_text and "100" not in body_text:
		_fail("test_tooltip_payload_castle", "Castle tooltip should show HP")
	else:
		_pass("test_tooltip_payload_castle")
	
	instance.queue_free()


func _pass(test_name: String) -> void:
	print("  PASS: %s" % test_name)
	_passed += 1


func _fail(test_name: String, reason: String) -> void:
	print("  FAIL: %s - %s" % [test_name, reason])
	_failed += 1
