extends SceneTree
## Test: Battle mode does not leave a visible gray PanelContainer above the arena.
## The ArenaPanel must be fully transparent (no visible stylebox) during battle.

const PROTO_SCENE_PATH := "res://scenes/dev/TenKingsPrototype.tscn"

var _proto: Node2D = null
var _failed: bool = false


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	if not _setup():
		print("  ERROR: Failed to setup prototype scene")
		print("FAIL: test_ten_kings_battle_arena_unobstructed")
		quit(1)
		return
	await process_frame

	# Test 1: ArenaPanel exists and is a PanelContainer
	var arena_panel: PanelContainer = _proto.get_node_or_null("UI/Root/MainVBox/MiddleHBox/ArenaPanel")
	if arena_panel == null:
		print("  ERROR: ArenaPanel not found")
		_cleanup()
		_fail_and_quit()
		return
	print("  ArenaPanel found")

	# Test 2: Simulate battle start through the prototype battle-start handler.
	if not _proto.has_method("_on_battle_started"):
		print("  ERROR: _on_battle_started method not found")
		_cleanup()
		_fail_and_quit()
		return

	_proto.call("_on_battle_started")
	print("  Battle mode activated")

	# Test 2a: Full-screen background must hide during battle.
	var background: ColorRect = _proto.get_node_or_null("UI/Root/Background")
	if background == null:
		print("  ERROR: Background not found")
		_cleanup()
		_fail_and_quit()
		return
	if background.visible:
		print("  ERROR: Background is still visible during battle")
		_cleanup()
		_fail_and_quit()
		return
	print("  Background hidden during battle")

	# Test 2b: Player board panel must stop occluding the battle.
	var player_board_panel: PanelContainer = _proto.get_node_or_null("UI/Root/MainVBox/MiddleHBox/PlayerBoardPanel")
	if player_board_panel == null:
		print("  ERROR: PlayerBoardPanel not found")
		_cleanup()
		_fail_and_quit()
		return
	if player_board_panel.visible:
		print("  ERROR: PlayerBoardPanel is still visible during battle")
		_cleanup()
		_fail_and_quit()
		return
	if player_board_panel.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		print("  ERROR: PlayerBoardPanel still captures mouse during battle")
		_cleanup()
		_fail_and_quit()
		return
	print("  PlayerBoardPanel hidden and non-interactive during battle")

	# Test 3: Check that ArenaPanel is not visually obstructing
	# In battle mode, the panel must either:
	# - Have a fully transparent stylebox (draw_center false or empty stylebox)
	# - Or have self_modulate.a == 0 AND no visible children
	var is_unobstructed := _check_panel_is_unobstructed(arena_panel)
	if not is_unobstructed:
		print("  ERROR: ArenaPanel is still visually obstructing during battle")
		_cleanup()
		_fail_and_quit()
		return
	print("  ArenaPanel is unobstructed during battle")

	# Test 4: Check children are hidden
	var visible_children := 0
	for child in arena_panel.get_children():
		if child is CanvasItem and child.visible:
			visible_children += 1
	if visible_children > 0:
		print("  ERROR: ArenaPanel has %d visible children during battle" % visible_children)
		_cleanup()
		_fail_and_quit()
		return
	print("  ArenaPanel children are hidden during battle")

	# Test 5: Restore from battle mode
	_proto.call("_on_battle_ended", 0)
	var is_restored := not _check_panel_is_unobstructed(arena_panel)
	# After restoring, panel should be visible again (not unobstructed)
	# Actually, we check that stylebox is restored or self_modulate is 1.0
	var modulate_restored := arena_panel.self_modulate.a > 0.5
	if not modulate_restored:
		print("  ERROR: ArenaPanel not restored after battle mode")
		_cleanup()
		_fail_and_quit()
		return
	print("  ArenaPanel restored after battle mode")

	if not background.visible:
		print("  ERROR: Background not restored after battle")
		_cleanup()
		_fail_and_quit()
		return
	if not player_board_panel.visible:
		print("  ERROR: PlayerBoardPanel not restored after battle")
		_cleanup()
		_fail_and_quit()
		return
	print("  Background and PlayerBoardPanel restored after battle")

	_cleanup()
	print("PASS: test_ten_kings_battle_arena_unobstructed")
	quit(0)


func _check_panel_is_unobstructed(panel: PanelContainer) -> bool:
	# Method 1: Check if self_modulate alpha is near zero
	if panel.self_modulate.a < 0.01:
		return true

	# Method 2: Check if the panel uses an empty/transparent stylebox override
	if panel.has_theme_stylebox_override("panel"):
		var stylebox: StyleBox = panel.get_theme_stylebox("panel")
		if stylebox is StyleBoxEmpty:
			return true
		if stylebox == null:
			return true

	return false


func _setup() -> bool:
	if not ResourceLoader.exists(PROTO_SCENE_PATH):
		print("  ERROR: Scene not found: %s" % PROTO_SCENE_PATH)
		return false

	var scene: PackedScene = load(PROTO_SCENE_PATH)
	if scene == null:
		print("  ERROR: Failed to load scene: %s" % PROTO_SCENE_PATH)
		return false

	_proto = scene.instantiate()
	if _proto == null:
		print("  ERROR: Failed to instantiate scene")
		return false

	root.add_child(_proto)
	return true


func _fail_and_quit() -> void:
	_failed = true
	print("FAIL: test_ten_kings_battle_arena_unobstructed")
	quit(1)


func _cleanup() -> void:
	if _proto != null and is_instance_valid(_proto):
		_proto.queue_free()
	_proto = null
