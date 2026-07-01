extends SceneTree

const SpellDamageApplicatorScript := preload("res://scripts/effects/shared/SpellDamageApplicator.gd")
const SpellBoundsEnforcerScript := preload("res://scripts/effects/shared/SpellBoundsEnforcer.gd")
const SpellVisualLifecycleScript := preload("res://scripts/effects/shared/SpellVisualLifecycle.gd")
const GroundfireEffectScene := preload("res://scenes/spells/effects/GroundfireEffect.tscn")
const InfernalUnitScene := preload("res://scenes/spells/effects/InfernalUnit.tscn")

var _failed: bool = false


class FakeHurtbox:
	extends Node

	var hits: Array = []

	func apply_hit(amount: float, source: Node, attack_id: int) -> void:
		hits.append({
			"amount": amount,
			"source": source,
			"attack_id": attack_id,
		})


class FakeTarget:
	extends Node2D

	var apply_hit_calls: Array = []
	var apply_damage_calls: Array = []
	var take_damage_calls: Array = []

	func apply_hit(amount: float, source: Node, attack_id: int) -> void:
		apply_hit_calls.append([amount, source, attack_id])

	func apply_damage(amount: float, source: Node = null) -> void:
		apply_damage_calls.append([amount, source])

	func take_damage(amount: float) -> void:
		take_damage_calls.append(amount)


class FakeSpellConfig:
	extends SpellConfig


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_spell_damage_applicator] %s" % message)
	quit(1)


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_fail("%s (expected: %s, got: %s)" % [message, expected, actual])


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var applicator: RefCounted = SpellDamageApplicatorScript.new()
	var bounds_enforcer: RefCounted = SpellBoundsEnforcerScript.new()
	var visual_lifecycle: RefCounted = SpellVisualLifecycleScript.new()
	_test_damage_method_order(applicator)
	if _failed:
		return
	_test_bounds_enforcer_smoke(bounds_enforcer)
	if _failed:
		return
	await _test_visual_lifecycle_smoke(root, visual_lifecycle)
	if _failed:
		return
	await _test_groundfire_visual_lifetime_smoke(root)
	if _failed:
		return
	await _test_groundfire_damage_smoke(root)
	if _failed:
		return
	await _test_infernal_attack_smoke(root)
	if _failed:
		return
	await _test_infernal_despawn_visual_lifetime_smoke(root)
	if _failed:
		return
	print("[test_spell_damage_applicator] PASS")
	quit(0)


func _test_damage_method_order(applicator: RefCounted) -> void:
	var source := Node2D.new()

	var hurtbox_target := FakeTarget.new()
	var hurtbox := FakeHurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox_target.add_child(hurtbox)
	_assert_true(applicator.apply_damage(hurtbox_target, 12.5, source, 77), "Damage applicator should report success for Hurtbox.apply_hit path")
	_assert_equal(hurtbox.hits.size(), 1, "Hurtbox.apply_hit should be preferred when present")
	_assert_equal(hurtbox.hits[0]["amount"], 12.5, "Hurtbox.apply_hit should receive the exact damage amount")
	_assert_equal(hurtbox_target.apply_hit_calls.size(), 0, "Direct apply_hit should not run when Hurtbox.apply_hit handled the damage")

	var direct_hit_target := FakeTarget.new()
	_assert_true(applicator.apply_damage(direct_hit_target, 8.0, source, 91), "Damage applicator should use target.apply_hit when no Hurtbox is present")
	_assert_equal(direct_hit_target.apply_hit_calls.size(), 1, "Target.apply_hit should receive damage when Hurtbox is absent")
	_assert_equal(direct_hit_target.take_damage_calls.size(), 0, "take_damage should not run when apply_hit handled the damage")

	var apply_damage_target := FakeTarget.new()
	apply_damage_target.take_damage_calls.clear()
	apply_damage_target.apply_hit_calls.clear()
	apply_damage_target.set_script(null)

	var apply_damage_only := Node2D.new()
	apply_damage_only.set_script(GDScript.new())

	var damage_script := GDScript.new()
	damage_script.source_code = "extends Node2D\nvar apply_damage_calls := []\nfunc apply_damage(amount: float, source: Node = null) -> void:\n\tapply_damage_calls.append([amount, source])\n"
	var compile_error := damage_script.reload()
	if compile_error != OK:
		_fail("Inline apply_damage test double failed to compile")
		return
	apply_damage_only.set_script(damage_script)
	_assert_true(applicator.apply_damage(apply_damage_only, 5.0, source, 12, true), "Damage applicator should support apply_damage-first call sites")
	_assert_equal(apply_damage_only.apply_damage_calls.size(), 1, "apply_damage-first mode should call apply_damage")

	var take_damage_script := GDScript.new()
	take_damage_script.source_code = "extends Node2D\nvar take_damage_calls := []\nfunc take_damage(amount: float) -> void:\n\ttake_damage_calls.append(amount)\n"
	compile_error = take_damage_script.reload()
	if compile_error != OK:
		_fail("Inline take_damage test double failed to compile")
		return
	var take_damage_only := Node2D.new()
	take_damage_only.set_script(take_damage_script)
	_assert_true(applicator.apply_damage(take_damage_only, 3.0, source, 33), "Damage applicator should fall back to take_damage")
	_assert_equal(take_damage_only.take_damage_calls, [3.0], "take_damage fallback should receive the exact damage amount")


func _test_bounds_enforcer_smoke(bounds_enforcer: RefCounted) -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(200.0, 200.0))
	var result: Dictionary = bounds_enforcer.move_within_rect(Vector2(195.0, 100.0), Vector2(20.0, 0.0), 1.0, 10.0, 0.0, rect, Callable())
	_assert_equal(result["position"], Vector2(190.0, 100.0), "Bounds enforcer must clamp position inside rect")
	_assert_true(result["velocity"].x < 0.0, "Bounds enforcer must bounce velocity on right wall")


func _test_visual_lifecycle_smoke(root: Node2D, visual_lifecycle: RefCounted) -> void:
	var node := Node2D.new()
	root.add_child(node)
	var tween: Tween = visual_lifecycle.fade_out_nodes(root, [node], 0.01)
	await tween.finished
	_assert_true(node.modulate.a < 0.01, "Visual lifecycle helper must fade node alpha to zero")


func _test_groundfire_damage_smoke(root: Node2D) -> void:
	var effect := GroundfireEffectScene.instantiate()
	root.add_child(effect)
	effect.damage_multiplier = 2.0
	var cfg := FakeSpellConfig.new()
	cfg.damage_per_second = 15.0
	effect.config = cfg

	var target := FakeTarget.new()
	var hurtbox := FakeHurtbox.new()
	hurtbox.name = "Hurtbox"
	target.add_child(hurtbox)
	root.add_child(target)

	effect._deal_dot_damage(target, 5)
	_assert_equal(hurtbox.hits.size(), 1, "Groundfire should still route DoT through Hurtbox.apply_hit when available")
	_assert_equal(hurtbox.hits[0]["amount"], 30.0, "Groundfire should preserve effect-side damage multiplier application")


func _test_groundfire_visual_lifetime_smoke(root: Node2D) -> void:
	var effect = GroundfireEffectScene.instantiate()
	root.add_child(effect)
	effect.fire_anim = AnimatedSprite2D.new()
	effect.add_child(effect.fire_anim)
	var ring := AnimatedSprite2D.new()
	effect.add_child(ring)
	var rings: Array[AnimatedSprite2D] = [ring]
	effect._ring_fires = rings
	effect._fade_zone_visuals()
	await create_timer(0.5).timeout
	_assert_true(effect.fire_anim.modulate.a < 0.05, "Groundfire fade helper must preserve near-zero alpha by 0.4s timing")
	_assert_true(ring.modulate.a < 0.05, "Groundfire ring fade timing must remain aligned with helper extraction")


func _test_infernal_attack_smoke(root: Node2D) -> void:
	var infernal := InfernalUnitScene.instantiate()
	root.add_child(infernal)
	infernal.global_position = Vector2.ZERO
	infernal.setup(5.0)
	infernal._attack_timer = 0.0

	var target_script := GDScript.new()
	target_script.source_code = "extends Node2D\nvar calls := []\nvar is_dead := false\nfunc apply_damage(amount: float, source: Node = null) -> void:\n\tcalls.append([amount, source])\n"
	var compile_error := target_script.reload()
	if compile_error != OK:
		_fail("Inline infernal target test double failed to compile")
		return

	var target := Node2D.new()
	target.set_script(target_script)
	root.add_child(target)
	infernal._current_target = target

	infernal._try_attack()
	_assert_equal(target.calls.size(), 1, "Infernal attacks should still use apply_damage-first behavior through the shared applicator")
	_assert_equal(target.calls[0][0], 25.0, "Infernal attack damage should remain unchanged after extraction")


func _test_infernal_despawn_visual_lifetime_smoke(root: Node2D) -> void:
	var infernal = InfernalUnitScene.instantiate()
	root.add_child(infernal)
	infernal._despawn()
	await create_timer(0.4).timeout
	_assert_true(not is_instance_valid(infernal) or infernal.modulate.a < 0.05, "Infernal despawn fade timing must remain within extracted 0.35s lifecycle")
