extends SceneTree

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const UnitScript = preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_phase2_siege_resolution] %s" % message)
	_failed = true
	return false


func _run_test() -> void:
	await _test_siege_phase_targets_castle_and_waits_for_castle_contact()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_phase2_siege_resolution] PASS")
	quit(0)


func _test_siege_phase_targets_castle_and_waits_for_castle_contact() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var battle_manager := BattleManagerScript.new()
	root.add_child(battle_manager)
	battle_manager._battle_container = Node2D.new()
	battle_manager.add_child(battle_manager._battle_container)

	var attacker := _make_unit(battle_manager, CardLib.CARD_SOLDIER, 0, Vector2(0.0, 0.0))
	var castle := _make_unit(battle_manager, CardLib.CARD_CASTLE, 1, Vector2(60.0, 0.0))
	var tower := _make_unit(battle_manager, CardLib.CARD_SCOUT_TOWER, 1, Vector2(120.0, 0.0))

	castle.start_advancing()
	tower.start_advancing()

	battle_manager._player_units = [attacker]
	battle_manager._ai_units = [castle, tower]
	battle_manager._is_active = true

	var ended: Array = []
	battle_manager.battle_ended.connect(func(winner_side: int) -> void:
		ended.append(winner_side)
	)

	battle_manager._begin_chase_phase(0)
	await process_frame

	_assert_true(ended.is_empty(), "locking field victory must not end the battle immediately")
	_assert_true(attacker.get_state() == UnitScript.UnitState.CHASING_CASTLE, "winning troops must enter castle chase state")
	_assert_true(attacker.get_target() == castle, "winning troops must commit to the losing castle during siege")

	var frame_budget: int = 120
	while ended.is_empty() and frame_budget > 0:
		await process_frame
		frame_budget -= 1

	_assert_true(ended.size() == 1, "battle must end once a surviving attacker reaches the castle area")
	_assert_true(tower.get_target() == attacker, "defender towers must keep a valid siege target during the chase window")

	root.queue_free()
	await process_frame


func _make_unit(battle_manager: Node2D, card_id: StringName, side: int, world_pos: Vector2) -> Node2D:
	var unit := UnitScript.new()
	battle_manager._battle_container.add_child(unit)
	unit.setup(card_id, 1, side, 0, 0.0, 0)
	unit.global_position = world_pos
	return unit
