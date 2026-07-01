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
	push_error("[test_ten_kings_crowd_archer_vs_paladin_progress] %s" % message)
	_failed = true


func _run_test() -> void:
	await _test_archer_vs_paladin_produces_combat_progress()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_archer_vs_paladin_progress] PASS")
	quit(0)


func _test_archer_vs_paladin_produces_combat_progress() -> void:
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
	arena_geometry.setup_from_dimensions(2200.0, 700.0, Vector2.ZERO)
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
	var heartbeat: Variant = debug_helper.call("get_latest_heartbeat_snapshot") if debug_helper != null else null

	_assert_true(heartbeat is Dictionary and not heartbeat.is_empty(), "crowd battle must expose heartbeat snapshots")
	if not (heartbeat is Dictionary) or heartbeat.is_empty():
		root.queue_free()
		await process_frame
		return

	var attacks_in_window: int = int(heartbeat.get("attacks_in_window", 0))
	var player_avg_distance: float = float(heartbeat.get("player_avg_distance_to_target", INF))
	var enemy_avg_distance: float = float(heartbeat.get("enemy_avg_distance_to_target", INF))
	var player_attacking: int = int(heartbeat.get("player_attacking", 0))
	var enemy_attacking: int = int(heartbeat.get("enemy_attacking", 0))

	var made_progress: bool = attacks_in_window > 0 or player_attacking > 0 or enemy_attacking > 0 or player_avg_distance < 350.0 or enemy_avg_distance < 350.0
	_assert_true(made_progress, "archer vs paladin crowd battle must show combat progress within the time window")

	root.queue_free()
	await process_frame
