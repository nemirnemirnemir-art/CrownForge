extends SceneTree

const BattleManagerScript = preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const UnitScript = preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed = false


func _init():
	call_deferred("_run_test")


func _assert_true(condition, message):
	if condition:
		return true
	push_error("[test_ten_kings_phase2_attack_effects] %s" % message)
	_failed = true
	return false


func _run_test():
	await _test_attack_signal_emits_attacker_and_target()
	await _test_battle_manager_spawns_only_ranged_attack_effects()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_phase2_attack_effects] PASS")
	quit(0)


func _test_attack_signal_emits_attacker_and_target():
	var root = Node2D.new()
	get_root().add_child(root)

	var archer = UnitScript.new()
	var target = UnitScript.new()
	root.add_child(archer)
	root.add_child(target)
	archer.setup(CardLib.CARD_ARCHER, 1, 0, 0, 0.0, 0)
	target.setup(CardLib.CARD_SOLDIER, 1, 1, 0, 0.0, 0)
	archer.set_target(target)

	var emitted = []
	archer.attack_performed.connect(func(attacker, defender): emitted.append([attacker, defender]))
	archer.call("_perform_attack")

	_assert_true(emitted.size() == 1, "performing an attack must emit one attack_performed event")
	if emitted.size() == 1:
		_assert_true(emitted[0][0] == archer, "attack_performed must pass the attacker reference")
		_assert_true(emitted[0][1] == target, "attack_performed must pass the target reference")

	root.queue_free()
	await process_frame


func _test_battle_manager_spawns_only_ranged_attack_effects():
	var root = Node2D.new()
	get_root().add_child(root)

	var battle_manager = BattleManagerScript.new()
	root.add_child(battle_manager)
	battle_manager._battle_container = Node2D.new()
	battle_manager.add_child(battle_manager._battle_container)

	var target = UnitScript.new()
	battle_manager._battle_container.add_child(target)
	target.setup(CardLib.CARD_SOLDIER, 1, 1, 0, 0.0, 0)
	target.global_position = Vector2(120.0, 0.0)

	var archer = _make_attacker(battle_manager, CardLib.CARD_ARCHER, Vector2.ZERO)
	var tower = _make_attacker(battle_manager, CardLib.CARD_SCOUT_TOWER, Vector2(0.0, 30.0))
	var castle = _make_attacker(battle_manager, CardLib.CARD_CASTLE, Vector2(0.0, -30.0))
	var soldier = _make_attacker(battle_manager, CardLib.CARD_SOLDIER, Vector2(0.0, 60.0))

	archer.attack_performed.emit(archer, target)
	tower.attack_performed.emit(tower, target)
	castle.attack_performed.emit(castle, target)
	soldier.attack_performed.emit(soldier, target)
	await process_frame

	var effects = battle_manager._battle_container.get_node_or_null("BattleEffects")
	_assert_true(effects != null, "battle manager must create a dedicated attack effect container")
	if effects != null:
		_assert_true(effects.get_child_count() == 3, "archer, tower, and castle attacks must spawn effects while melee stays effect-free")

	await create_timer(0.35).timeout
	if effects != null and is_instance_valid(effects):
		_assert_true(effects.get_child_count() == 0, "prototype attack effects must clean themselves up after a short lifetime")

	root.queue_free()
	await process_frame


func _make_attacker(battle_manager, card_id, world_pos):
	var unit = UnitScript.new()
	battle_manager._battle_container.add_child(unit)
	unit.setup(card_id, 1, 0, 0, 0.0, 0)
	unit.global_position = world_pos
	battle_manager._connect_unit_signals(unit)
	return unit
