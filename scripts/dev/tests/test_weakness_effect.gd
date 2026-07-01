extends SceneTree

const WeaknessEffectScene := preload("res://scenes/spells/effects/WeaknessEffect.tscn")
const WeaknessConfig := preload("res://resources/spells/configs/weakness.tres")


class DummyEnemy:
	extends Node2D

	var speed_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0
	var is_dead: bool = false


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var enemy := DummyEnemy.new()
	enemy.name = "EnemyNear"
	enemy.global_position = Vector2(20.0, 0.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var far_enemy := DummyEnemy.new()
	far_enemy.name = "EnemyFar"
	far_enemy.global_position = Vector2(220.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	await process_frame
	await process_frame

	var effect := WeaknessEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_weakness_effect] failed to instantiate WeaknessEffect")
		quit(1)
		return

	var cfg := WeaknessConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_weakness_effect] failed to duplicate weakness config")
		quit(1)
		return
	cfg.duration = 0.2
	cfg.target_radius = 90.0

	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)

	await process_frame
	await physics_frame
	await physics_frame
	await process_frame

	if abs(enemy.speed_multiplier - 0.7) > 0.001:
		push_error("[test_weakness_effect] expected nearby enemy speed_multiplier=0.7, got %.3f" % enemy.speed_multiplier)
		quit(1)
		return
	if abs(enemy.attack_speed_multiplier - 0.7) > 0.001:
		push_error("[test_weakness_effect] expected nearby enemy attack_speed_multiplier=0.7, got %.3f" % enemy.attack_speed_multiplier)
		quit(1)
		return
	if abs(far_enemy.speed_multiplier - 1.0) > 0.001 or abs(far_enemy.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_weakness_effect] far enemy must remain unchanged")
		quit(1)
		return
	if enemy.get_node_or_null("WeaknessIcon") == null:
		push_error("[test_weakness_effect] expected WeaknessIcon during active debuff")
		quit(1)
		return

	enemy.global_position = Vector2(500.0, 0.0)
	await create_timer(0.05).timeout
	if abs(enemy.speed_multiplier - 0.7) > 0.001 or abs(enemy.attack_speed_multiplier - 0.7) > 0.001:
		push_error("[test_weakness_effect] debuff must keep snapshot-on-cast semantics after leaving radius")
		quit(1)
		return

	await create_timer(0.25).timeout
	await process_frame

	if abs(enemy.speed_multiplier - 1.0) > 0.001:
		push_error("[test_weakness_effect] speed_multiplier must restore to 1.0, got %.3f" % enemy.speed_multiplier)
		quit(1)
		return
	if abs(enemy.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_weakness_effect] attack_speed_multiplier must restore to 1.0, got %.3f" % enemy.attack_speed_multiplier)
		quit(1)
		return
	if enemy.get_node_or_null("WeaknessIcon") != null:
		push_error("[test_weakness_effect] WeaknessIcon must be removed after debuff ends")
		quit(1)
		return

	print("[test_weakness_effect] PASS")
	quit(0)
