extends SceneTree

const BattleManagerScript := preload("res://scripts/dev/ten_kings/TenKingsBattleManager.gd")
const UnitScript := preload("res://scripts/dev/ten_kings/TenKingsUnit.gd")
const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_ten_kings_scene_driven_projectiles] %s" % message)
	_failed = true
	return false


func _run_test() -> void:
	await _test_ranged_attacks_use_scene_driven_projectiles()
	await _test_fixed_structures_use_projectiles_on_their_real_path()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_scene_driven_projectiles] PASS")
	quit(0)


func _test_ranged_attacks_use_scene_driven_projectiles() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var battle_manager := BattleManagerScript.new()
	root.add_child(battle_manager)
	battle_manager._battle_container = Node2D.new()
	battle_manager.add_child(battle_manager._battle_container)

	var target := UnitScript.new()
	battle_manager._battle_container.add_child(target)
	target.setup(CardLib.CARD_SOLDIER, 1, 1, 0, 0.0, 0)
	target.global_position = Vector2(120.0, 0.0)

	var archer := _make_attacker(battle_manager, CardLib.CARD_ARCHER, Vector2.ZERO)
	var tower := _make_attacker(battle_manager, CardLib.CARD_SCOUT_TOWER, Vector2(0.0, 32.0))
	var castle := _make_attacker(battle_manager, CardLib.CARD_CASTLE, Vector2(0.0, -32.0))

	battle_manager._spawn_attack_effect(archer, target)
	var archer_effect := battle_manager._ensure_effect_container().get_child(battle_manager._ensure_effect_container().get_child_count() - 1)
	_assert_projectile_contract(archer_effect, &"arrow", true, false, "archer", true)

	battle_manager._spawn_attack_effect(tower, target)
	var tower_effect := battle_manager._ensure_effect_container().get_child(battle_manager._ensure_effect_container().get_child_count() - 1)
	_assert_projectile_contract(tower_effect, &"arrow", true, false, "scout tower", true)

	battle_manager._spawn_attack_effect(castle, target)
	var castle_effect := battle_manager._ensure_effect_container().get_child(battle_manager._ensure_effect_container().get_child_count() - 1)
	_assert_projectile_contract(castle_effect, &"cannonball", false, true, "castle", false)

	root.queue_free()
	await process_frame


func _test_fixed_structures_use_projectiles_on_their_real_path() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var battle_manager := BattleManagerScript.new()
	root.add_child(battle_manager)
	battle_manager._battle_container = Node2D.new()
	battle_manager.add_child(battle_manager._battle_container)

	var target := UnitScript.new()
	battle_manager._battle_container.add_child(target)
	target.setup(CardLib.CARD_SOLDIER, 1, 1, 0, 0.0, 0)
	target.global_position = Vector2(180.0, 0.0)

	var tower_structure := {
		"card_id": CardLib.CARD_SCOUT_TOWER,
		"position": Vector2(-140.0, 10.0),
	}
	var castle_structure := {
		"card_id": CardLib.CARD_CASTLE,
		"position": Vector2(-190.0, -10.0),
	}

	battle_manager._spawn_fixed_structure_attack_effect(tower_structure, target)
	var tower_effect := battle_manager._ensure_effect_container().get_child(battle_manager._ensure_effect_container().get_child_count() - 1)
	_assert_projectile_contract(tower_effect, &"arrow", true, false, "scout tower fixed structure", true)

	battle_manager._spawn_fixed_structure_attack_effect(castle_structure, target)
	var castle_effect := battle_manager._ensure_effect_container().get_child(battle_manager._ensure_effect_container().get_child_count() - 1)
	_assert_projectile_contract(castle_effect, &"cannonball", false, true, "castle fixed structure", false)

	root.queue_free()
	await process_frame


func _assert_projectile_contract(effect: Node, expected_kind: StringName, expect_sprite: bool, expect_body: bool, source_name: String, expect_arrow_texture: bool) -> void:
	if not _assert_true(effect != null, "%s attack must spawn an effect node" % source_name):
		return
	if not _assert_true(effect.has_method("get_projectile_kind"), "%s effect must expose projectile kind" % source_name):
		return

	var projectile_kind: Variant = effect.call("get_projectile_kind")
	_assert_true(projectile_kind == expected_kind, "%s effect must report %s projectile kind" % [source_name, expected_kind])

	var projectile_sprite := effect.get_node_or_null("ProjectileSprite") as Sprite2D
	var projectile_body := effect.get_node_or_null("ProjectileBody") as Polygon2D
	_assert_true(projectile_sprite != null, "%s effect must include ProjectileSprite node" % source_name)
	_assert_true(projectile_body != null, "%s effect must include ProjectileBody node" % source_name)
	if projectile_sprite != null:
		_assert_true(projectile_sprite.visible == expect_sprite, "%s effect sprite visibility must match contract" % source_name)
		if expect_arrow_texture:
			_assert_true(projectile_sprite.texture != null, "%s arrow projectile must keep a texture" % source_name)
			if projectile_sprite.texture != null:
				_assert_true(projectile_sprite.texture.resource_path.ends_with("Arrow.png"), "%s must use Arrow.png" % source_name)
	if projectile_body != null:
		_assert_true(projectile_body.visible == expect_body, "%s effect body visibility must match contract" % source_name)
		if expect_body:
			_assert_true(projectile_body.color.r < 0.15 and projectile_body.color.g < 0.15 and projectile_body.color.b < 0.15, "%s cannonball must stay black" % source_name)


func _make_attacker(battle_manager: Node2D, card_id: StringName, world_pos: Vector2) -> Node2D:
	var unit := UnitScript.new()
	battle_manager._battle_container.add_child(unit)
	unit.setup(card_id, 1, 0, 0, 0.0, 0)
	unit.global_position = world_pos
	battle_manager._connect_unit_signals(unit)
	return unit
