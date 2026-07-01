extends SceneTree

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const PlayerStateScript = preload("res://scripts/dev/ten_kings/TenKingsPlayerState.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")
const ArenaGeometryServiceScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_crowd_battle_does_not_end_early] %s" % message)
	_failed = true
	return false


func _run_test() -> void:
	await _test_crowd_battle_ignores_legacy_end_check()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_crowd_battle_does_not_end_early] PASS")
	quit(0)


func _test_crowd_battle_ignores_legacy_end_check() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var player := PlayerStateScript.new("Player", false)
	var ai_player := PlayerStateScript.new("AI", true)

	_assert_true(player.board.place_card(Vector2i(1, 2), CardLib.CARD_SOLDIER), "player soldier must be placeable")
	_assert_true(ai_player.board.place_card(Vector2i(3, 2), CardLib.CARD_SOLDIER), "ai soldier must be placeable")

	var battle_manager := BattleManagerScript.new()
	battle_manager.use_crowd_mode = true
	root.add_child(battle_manager)

	var arena_geometry := ArenaGeometryServiceScript.new()
	arena_geometry.setup_from_dimensions(5000.0, 800.0, Vector2.ZERO)
	battle_manager.set_arena_geometry(arena_geometry)
	battle_manager.set_arena_anchors({
		"player_front": Vector2(-100.0, 0.0),
		"ai_front": Vector2(100.0, 0.0),
		"player_castle_contact": Vector2(-400.0, 0.0),
		"ai_castle_contact": Vector2(400.0, 0.0),
	})

	var ended: Array[int] = []
	battle_manager.battle_ended.connect(func(winner_side: int) -> void:
		ended.append(winner_side)
	)

	battle_manager.start_battle(player, ai_player)
	await process_frame

	_assert_true(battle_manager.get_node_or_null("BattleUnits/CrowdRuntime") != null, "crowd runtime must be created in crowd mode")
	_assert_true(ended.is_empty(), "crowd battle must not end immediately on start")

	await create_timer(2.2).timeout
	await process_frame

	_assert_true(ended.is_empty(), "crowd battle must not end after legacy chase timeout while soldiers are still approaching")

	root.queue_free()
	await process_frame
