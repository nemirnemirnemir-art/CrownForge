extends SceneTree

const QuicksandEffectScene := preload("res://scenes/spells/effects/QuicksandEffect.tscn")
const QuicksandConfig := preload("res://resources/spells/configs/quicksand.tres")


class DummyEnemy:
	extends Node2D

	var speed_multiplier: float = 1.0
	var is_dead: bool = false


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var enemy := DummyEnemy.new()
	enemy.global_position = Vector2(0.0, 0.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var far_enemy := DummyEnemy.new()
	far_enemy.global_position = Vector2(240.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	await process_frame
	await process_frame

	var effect := QuicksandEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_quicksand_effect] failed to instantiate QuicksandEffect")
		quit(1)
		return

	var cfg := QuicksandConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_quicksand_effect] failed to duplicate quicksand config")
		quit(1)
		return
	cfg.duration = 0.5
	cfg.target_radius = 150.0

	var before_speed := enemy.speed_multiplier
	if abs(before_speed - 1.0) > 0.001:
		push_error("[test_quicksand_effect] expected baseline speed_multiplier to be 1.0")
		quit(1)
		return

	root.add_child(effect)
	effect.initialize(cfg, Vector2(0.0, 0.0))

	await process_frame
	await process_frame
	await physics_frame
	await create_timer(0.1).timeout

	await process_frame
	await process_frame

	var debuffed_speed := enemy.speed_multiplier
	if abs(debuffed_speed - 0.5) > 0.001:
		push_error("[test_quicksand_effect] expected speed_multiplier=0.5, got %.3f" % debuffed_speed)
		quit(1)
		return
	if abs(far_enemy.speed_multiplier - 1.0) > 0.001:
		push_error("[test_quicksand_effect] far enemy must remain unaffected")
		quit(1)
		return

	var icon_found := false
	for child in enemy.get_children():
		if child.name == "QuicksandIcon":
			icon_found = true
			break
	if not icon_found:
		push_error("[test_quicksand_effect] expected QuicksandIcon child on enemy during effect")
		quit(1)
		return

	await create_timer(0.55).timeout

	var restored_speed := enemy.speed_multiplier
	if abs(restored_speed - 1.0) > 0.001:
		push_error("[test_quicksand_effect] speed_multiplier must reset to 1.0, got %.3f" % restored_speed)
		quit(1)
		return
	if enemy.get_node_or_null("QuicksandIcon") != null:
		push_error("[test_quicksand_effect] QuicksandIcon must be removed after effect expires")
		quit(1)
		return

	print("[test_quicksand_effect] PASS (DummyEnemy)")

	# --- Real Mob proxy test ---
	await _run_real_mob_test(root)


func _run_real_mob_test(root: Node2D) -> void:
	var mob_scene := preload("res://scenes/mobs/GoblinBandit.tscn")
	var mob := mob_scene.instantiate()
	mob.global_position = Vector2(0.0, 0.0)
	if not mob.is_in_group("enemy"):
		mob.add_to_group("enemy")
	root.add_child(mob)

	await process_frame
	await process_frame

	# Verify proxy returns real value (not null)
	var proxy_val: Variant = mob.get("speed_multiplier")
	if proxy_val == null:
		push_error("[test_quicksand_real_mob] speed_multiplier proxy returned null")
		quit(1)
		return
	if abs(float(proxy_val) - 1.0) > 0.001:
		push_error("[test_quicksand_real_mob] expected baseline speed_multiplier=1.0, got %.3f" % float(proxy_val))
		quit(1)
		return

	var atk_proxy: Variant = mob.get("attack_speed_multiplier")
	if atk_proxy == null:
		push_error("[test_quicksand_real_mob] attack_speed_multiplier proxy returned null")
		quit(1)
		return

	# Apply quicksand debuff on the real mob
	var effect2 := QuicksandEffectScene.instantiate() as SpellEffect
	if effect2 == null:
		push_error("[test_quicksand_real_mob] failed to instantiate QuicksandEffect")
		quit(1)
		return

	var cfg2 := QuicksandConfig.duplicate() as SpellConfig
	if cfg2 == null:
		push_error("[test_quicksand_real_mob] failed to duplicate quicksand config")
		quit(1)
		return
	cfg2.duration = 0.5
	cfg2.target_radius = 150.0

	root.add_child(effect2)
	effect2.initialize(cfg2, Vector2(0.0, 0.0))

	await process_frame
	await process_frame
	await physics_frame
	await create_timer(0.1).timeout
	await process_frame
	await process_frame

	var debuffed: float = mob.speed_multiplier
	if abs(debuffed - 0.5) > 0.001:
		push_error("[test_quicksand_real_mob] expected speed_multiplier=0.5, got %.3f" % debuffed)
		quit(1)
		return

	# Wait for effect to expire, then check restoration
	await create_timer(0.55).timeout

	var restored: float = mob.speed_multiplier
	if abs(restored - 1.0) > 0.001:
		push_error("[test_quicksand_real_mob] speed_multiplier must restore to 1.0, got %.3f" % restored)
		quit(1)
		return

	mob.queue_free()
	print("[test_quicksand_real_mob] PASS (real Mob proxy)")
	quit(0)
