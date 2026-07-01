extends SceneTree

const FreezeConfig := preload("res://resources/spells/configs/freeze.tres")

var _failed: bool = false


class DummyEnemy:
	extends Node2D

	var speed_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0
	var is_dead: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var enemy := DummyEnemy.new()
	enemy.global_position = Vector2.ZERO
	enemy.modulate = Color(0.85, 0.8, 0.75, 1.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var far_enemy := DummyEnemy.new()
	far_enemy.global_position = Vector2(500.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	var cfg := FreezeConfig.duplicate() as SpellConfig
	_assert_true(cfg != null, "Freeze config must duplicate")
	if _failed:
		return

	_assert_true(cfg.effect_scene != null, "Freeze config must reference an effect scene")
	if _failed:
		return

	cfg.target_radius = 140.0

	var effect := cfg.effect_scene.instantiate() as SpellEffect
	_assert_true(effect != null, "Freeze effect scene must instantiate")
	if _failed:
		return

	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)

	await process_frame
	await process_frame

	_assert_true(enemy.process_mode == Node.PROCESS_MODE_DISABLED, "Freeze must fully disable enemy processing during the 1 second freeze window")
	_assert_true(far_enemy.process_mode != Node.PROCESS_MODE_DISABLED, "Freeze must not affect enemies outside radius")
	if _failed:
		return

	await create_timer(1.1).timeout
	await process_frame

	_assert_true(enemy.process_mode != Node.PROCESS_MODE_DISABLED, "Freeze must restore processing after the full-freeze window ends")
	_assert_close(enemy.speed_multiplier, 0.75, 0.02, "Freeze must leave a 25 percent slow after thaw")
	_assert_close(enemy.attack_speed_multiplier, 0.75, 0.02, "Freeze must slow attack speed during thaw phase")
	_assert_true(enemy.modulate.b > enemy.modulate.r, "Freeze must tint affected enemies blue during thaw phase")
	if _failed:
		return

	await create_timer(8.2).timeout
	await process_frame

	_assert_close(enemy.speed_multiplier, 1.0, 0.02, "Freeze must restore move speed after slow expires")
	_assert_close(enemy.attack_speed_multiplier, 1.0, 0.02, "Freeze must restore attack speed after slow expires")
	_assert_color_close(enemy.modulate, Color(0.85, 0.8, 0.75, 1.0), 0.03, "Freeze must restore original enemy tint after expiry")
	if _failed:
		return

	print("[test_freeze_effect] PASS")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _assert_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) <= tolerance:
		return
	_fail("%s (expected %.3f, got %.3f)" % [message, expected, actual])


func _assert_color_close(actual: Color, expected: Color, tolerance: float, message: String) -> void:
	var ok := absf(actual.r - expected.r) <= tolerance \
		and absf(actual.g - expected.g) <= tolerance \
		and absf(actual.b - expected.b) <= tolerance \
		and absf(actual.a - expected.a) <= tolerance
	if ok:
		return
	_fail("%s (expected %s, got %s)" % [message, expected, actual])


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_freeze_effect] %s" % message)
	quit(1)
