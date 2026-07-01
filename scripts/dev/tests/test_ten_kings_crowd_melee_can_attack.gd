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
	push_error("[test_ten_kings_crowd_melee_can_attack] %s" % message)
	_failed = true


func _run_test() -> void:
	await _test_paladins_reach_attacking_state_against_archers()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_melee_can_attack] PASS")
	quit(0)


func _test_paladins_reach_attacking_state_against_archers() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var player := PlayerStateScript.new("Player", false)
	var ai_player := PlayerStateScript.new("AI", true)
	_assert_true(player.board.place_card(Vector2i(1, 2), CardLib.CARD_ARCHER), "player archer must be placeable")
	_assert_true(ai_player.board.place_card(Vector2i(3, 2), CardLib.CARD_PALADIN), "ai paladin must be placeable")
	_assert_true(ai_player.board.place_card(Vector2i(3, 2), CardLib.CARD_PALADIN), "ai paladin level 2 must be placeable")
	_assert_true(ai_player.board.place_card(Vector2i(3, 2), CardLib.CARD_PALADIN), "ai paladin level 3 must be placeable")

	var battle_manager := BattleManagerScript.new()
	battle_manager.use_crowd_mode = true
	root.add_child(battle_manager)

	var arena_geometry := ArenaGeometryServiceScript.new()
	arena_geometry.setup_from_dimensions(920.0, 520.0, Vector2.ZERO)
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
	await create_timer(4.0).timeout
	await process_frame

	var debug_helper: Variant = battle_manager.call("get_debug_helper")
	var heartbeat: Dictionary = debug_helper.call("get_latest_heartbeat_snapshot")
	var enemy_attacking: int = int(heartbeat.get("enemy_attacking", 0))
	var enemy_attacks_in_window: int = int(heartbeat.get("enemy_attacks_in_window", 0))
	var enemy_avg_distance: float = float(heartbeat.get("enemy_avg_distance_to_target", INF))

	_assert_true(enemy_attacking > 0 or enemy_attacks_in_window > 0, "melee side must enter attacking state or land attacks against ranged targets")
	_assert_true(enemy_avg_distance < 80.0, "melee side must close to real contact distance before the snapshot")

	root.queue_free()
	await process_frame
