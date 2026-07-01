extends SceneTree

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const BoardStateScript = preload("res://scripts/dev/ten_kings/TenKingsBoardState.gd")
const ArenaGeometryScript = preload("res://scripts/dev/ten_kings/TenKingsArenaGeometryService.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed := false


class FakePlayer:
	extends RefCounted

	var board
	var castle_hp = 100

	func _init(p_board, p_castle_hp = 100):
		board = p_board
		castle_hp = p_castle_hp


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await _test_crowd_battle_waits_for_deploy_before_combat()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_phase2_battle_deploy] PASS")
	quit(0)


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_phase2_battle_deploy] %s" % message)
	_failed = true
	return false


func _test_crowd_battle_waits_for_deploy_before_combat() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var battle_manager = BattleManagerScript.new()
	root.add_child(battle_manager)
	battle_manager.use_crowd_mode = true

	var geometry = ArenaGeometryScript.new()
	geometry.setup_from_dimensions(800.0, 400.0)
	battle_manager.set_arena_geometry(geometry)

	var player_board = _build_board([
		[Vector2i(2, 2), CardLib.CARD_CASTLE],
		[Vector2i(1, 2), CardLib.CARD_SOLDIER],
		[Vector2i(2, 1), CardLib.CARD_ARCHER],
		[Vector2i(1, 1), CardLib.CARD_SCOUT_TOWER],
	])
	var ai_board = _build_board([
		[Vector2i(2, 2), CardLib.CARD_CASTLE],
		[Vector2i(3, 2), CardLib.CARD_SOLDIER],
		[Vector2i(2, 1), CardLib.CARD_ARCHER],
		[Vector2i(3, 1), CardLib.CARD_SCOUT_TOWER],
	])

	var player = FakePlayer.new(player_board)
	var ai_player = FakePlayer.new(ai_board)
	var player_origins = {
		Vector2i(2, 2): Vector2(-420.0, -20.0),
		Vector2i(1, 2): Vector2(-470.0, 30.0),
		Vector2i(2, 1): Vector2(-430.0, -90.0),
		Vector2i(1, 1): Vector2(-520.0, 80.0),
	}
	var ai_origins = {
		Vector2i(2, 2): Vector2(420.0, -20.0),
		Vector2i(3, 2): Vector2(470.0, 30.0),
		Vector2i(2, 1): Vector2(430.0, -90.0),
		Vector2i(3, 1): Vector2(520.0, 80.0),
	}

	battle_manager.start_battle(player, ai_player, player_origins, ai_origins)
	await process_frame

	_assert_true(not battle_manager._is_active, "crowd battle must stay inactive during deploy")
	_assert_true(battle_manager._crowd_runtime != null, "crowd runtime must be created")

	var player_soldiers: Array = battle_manager._crowd_runtime.player_soldiers
	var enemy_soldiers: Array = battle_manager._crowd_runtime.enemy_soldiers
	_assert_true(player_soldiers.size() > 0, "player crowd soldiers must exist")
	_assert_true(enemy_soldiers.size() > 0, "enemy crowd soldiers must exist")

	var player_soldier: Dictionary = _find_soldier_from_slot(player_soldiers, Vector2i(1, 2))
	var ai_soldier: Dictionary = _find_soldier_from_slot(enemy_soldiers, Vector2i(3, 2))
	if player_soldier:
		_assert_true(player_soldier["position"].distance_to(player_origins[Vector2i(1, 2)]) < 1.0, "player soldier must start at board-slot origin")
	if ai_soldier:
		_assert_true(ai_soldier["position"].distance_to(ai_origins[Vector2i(3, 2)]) < 1.0, "ai soldier must start at board-slot origin")

	var player_castle := _find_structure_from_slot(battle_manager._player_fixed_structures, Vector2i(2, 2))
	if player_castle:
		_assert_true(player_castle["position"].distance_to(player_origins[Vector2i(2, 2)]) < 1.0, "player castle must start at board-slot origin")

	await create_timer(3.2).timeout
	await process_frame

	_assert_true(battle_manager._is_active, "crowd battle must become active after deploy")
	if player_soldier:
		_assert_true(player_soldier["position"].distance_to(player_soldier["formation_position"]) < 1.0, "player soldier must end deploy at formation")
	if player_castle:
		_assert_true(player_castle["position"].distance_to(player_castle["formation_position"]) < 1.0, "player castle must end deploy at formation")

	root.queue_free()
	await process_frame


func _build_board(entries: Array) -> RefCounted:
	var board = BoardStateScript.new()
	for entry in entries:
		board.place_card(entry[0], entry[1])
	return board


func _find_soldier_from_slot(soldiers: Array, slot_pos: Vector2i) -> Dictionary:
	for soldier: Dictionary in soldiers:
		if soldier.get("source_slot", Vector2i(-1, -1)) == slot_pos:
			return soldier
	return {}


func _find_structure_from_slot(structures: Array, slot_pos: Vector2i) -> Dictionary:
	for structure: Dictionary in structures:
		if structure.get("source_slot", Vector2i(-1, -1)) == slot_pos:
			return structure
	return {}
