extends SceneTree

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error("[test_ten_kings_crowd_watchdog_reports_stalled_battle] %s" % message)
	_failed = true


func _run_test() -> void:
	await _test_watchdog_snapshot_exists_for_stalled_battle()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_watchdog_reports_stalled_battle] PASS")
	quit(0)


func _test_watchdog_snapshot_exists_for_stalled_battle() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var player := PlayerStateScript.new("Player", false)
	var ai_player := PlayerStateScript.new("AI", true)
	_assert_true(player.board.place_card(Vector2i(1, 2), CardLib.CARD_ARCHER), "player archer must be placeable")
	_assert_true(ai_player.board.place_card(Vector2i(3, 2), CardLib.CARD_PALADIN), "ai paladin must be placeable")

	var battle_manager := BattleManagerScript.new()
	battle_manager.use_crowd_mode = true
	root.add_child(battle_manager)

	var arena_geometry := ArenaGeometryServiceScript.new()
	arena_geometry.setup_from_dimensions(4000.0, 800.0, Vector2.ZERO)
	battle_manager.set_arena_geometry(arena_geometry)
	battle_manager.set_arena_anchors({
		"player_front": Vector2(-100.0, 0.0),
		"player_ranged": Vector2(-200.0, 0.0),
		"player_back": Vector2(-300.0, 0.0),
		"ai_front": Vector2(100.0, 0.0),
		"ai_ranged": Vector2(200.0, 0.0),
		"ai_back": Vector2(300.0, 0.0),
		"player_castle_contact": Vector2(-400.0, 0.0),
		"ai_castle_contact": Vector2(400.0, 0.0),
	})

	battle_manager.start_battle(player, ai_player)
	await process_frame

	_assert_true(battle_manager.has_method("get_debug_helper"), "battle manager must expose debug helper accessor")
	if not battle_manager.has_method("get_debug_helper"):
		root.queue_free()
		await process_frame
		return

	await create_timer(3.2).timeout
	await process_frame

	var debug_helper: Variant = battle_manager.call("get_debug_helper")
	_assert_true(debug_helper != null, "debug helper must exist after crowd battle start")
	if debug_helper == null:
		root.queue_free()
		await process_frame
		return

	var watchdog_snapshot: Variant = debug_helper.call("get_latest_watchdog_snapshot")
	_assert_true(watchdog_snapshot is Dictionary and not watchdog_snapshot.is_empty(), "stalled crowd battle must produce a watchdog snapshot")

	root.queue_free()
	await process_frame
