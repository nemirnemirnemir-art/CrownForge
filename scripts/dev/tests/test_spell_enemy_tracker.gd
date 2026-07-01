extends SceneTree

const SpellEnemyTrackerScript := preload("res://scripts/effects/shared/SpellEnemyTracker.gd")
const InfernalUnitScene := preload("res://scenes/spells/effects/InfernalUnit.tscn")

var _failed: bool = false


class FakeEnemy:
	extends Node2D

	var is_dead: bool = false


class FakeHurtbox:
	extends Area2D


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_spell_enemy_tracker] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var tracker: RefCounted = SpellEnemyTrackerScript.new()
	_test_collider_resolution_and_dead_filtering(root, tracker)
	if _failed:
		return
	_test_radius_collection_and_dedupe(root, tracker)
	if _failed:
		return
	root.queue_free()
	await process_frame
	await process_frame
	var infernal_root := Node2D.new()
	get_root().add_child(infernal_root)
	await _test_infernal_target_selection_smoke(infernal_root)
	if _failed:
		return
	print("[test_spell_enemy_tracker] PASS")
	quit(0)


func _test_collider_resolution_and_dead_filtering(root: Node2D, tracker: RefCounted) -> void:
	var alive_enemy := FakeEnemy.new()
	alive_enemy.add_to_group("enemy")
	root.add_child(alive_enemy)

	var hurtbox := FakeHurtbox.new()
	hurtbox.name = "Hurtbox"
	alive_enemy.add_child(hurtbox)

	var dead_enemy := FakeEnemy.new()
	dead_enemy.is_dead = true
	dead_enemy.add_to_group("mobs")
	root.add_child(dead_enemy)

	var resolved_from_hurtbox: Variant = tracker.resolve_enemy_from_collider(hurtbox)
	_assert_equal(resolved_from_hurtbox, alive_enemy, "Hurtbox collider should resolve to its enemy parent")

	var resolved_alive: Variant = tracker.resolve_enemy_from_collider(alive_enemy)
	_assert_equal(resolved_alive, alive_enemy, "Direct enemy collider should resolve unchanged")

	var resolved_dead_filtered: Variant = tracker.resolve_enemy_from_collider(dead_enemy, true)
	_assert_equal(resolved_dead_filtered, null, "Dead enemies should be filtered when alive-only lookup is requested")

	var resolved_dead_allowed: Variant = tracker.resolve_enemy_from_collider(dead_enemy, false)
	_assert_equal(resolved_dead_allowed, dead_enemy, "Dead enemies should remain resolvable when alive filtering is disabled")


func _test_radius_collection_and_dedupe(root: Node2D, tracker: RefCounted) -> void:
	var nearby_enemy := FakeEnemy.new()
	nearby_enemy.global_position = Vector2(25.0, 0.0)
	nearby_enemy.add_to_group("enemy")
	nearby_enemy.add_to_group("mobs")
	root.add_child(nearby_enemy)

	var dead_enemy := FakeEnemy.new()
	dead_enemy.global_position = Vector2(30.0, 0.0)
	dead_enemy.is_dead = true
	dead_enemy.add_to_group("enemies")
	root.add_child(dead_enemy)

	var far_enemy := FakeEnemy.new()
	far_enemy.global_position = Vector2(200.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	var collected: Array[Node2D] = tracker.collect_tree_enemies_in_radius(get_root(), Vector2.ZERO, 60.0)
	_assert_equal(collected.size(), 1, "Radius collection should dedupe groups and skip dead or far enemies")
	_assert_equal(collected[0], nearby_enemy, "Radius collection should keep the alive nearby enemy")


func _test_infernal_target_selection_smoke(root: Node2D) -> void:
	var infernal := InfernalUnitScene.instantiate()
	root.add_child(infernal)
	infernal.global_position = Vector2.ZERO
	infernal.setup(5.0)

	var near_enemy := FakeEnemy.new()
	near_enemy.global_position = Vector2(60.0, 0.0)
	near_enemy.add_to_group("enemy")
	root.add_child(near_enemy)

	var dead_closer_enemy := FakeEnemy.new()
	dead_closer_enemy.global_position = Vector2(30.0, 0.0)
	dead_closer_enemy.is_dead = true
	dead_closer_enemy.add_to_group("enemy")
	root.add_child(dead_closer_enemy)

	var far_enemy := FakeEnemy.new()
	far_enemy.global_position = Vector2(420.0, 0.0)
	far_enemy.add_to_group("mobs")
	root.add_child(far_enemy)

	await process_frame
	await physics_frame

	infernal._find_target()
	_assert_equal(infernal._current_target, near_enemy, "Infernal target selection should prefer the nearest alive enemy inside detection range")

	near_enemy.is_dead = true
	infernal._find_target()
	_assert_equal(infernal._current_target, far_enemy, "Infernal target selection should fall back to the closest alive enemy when none are in range")
