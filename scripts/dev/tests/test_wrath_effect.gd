extends SceneTree

const WrathEffectScene := preload("res://scenes/spells/effects/WrathEffect.tscn")
const WrathConfig := preload("res://resources/spells/configs/wrath.tres")


class DummyHero:
	extends Node2D

	var speed_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var hero := DummyHero.new()
	hero.name = "HeroNear"
	hero.global_position = Vector2(24.0, 0.0)
	hero.add_to_group("hero")
	root.add_child(hero)

	var far_hero := DummyHero.new()
	far_hero.name = "HeroFar"
	far_hero.global_position = Vector2(240.0, 0.0)
	far_hero.add_to_group("hero")
	root.add_child(far_hero)

	await process_frame
	await process_frame

	var effect := WrathEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_wrath_effect] failed to instantiate WrathEffect")
		quit(1)
		return

	var cfg := WrathConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_wrath_effect] failed to duplicate wrath config")
		quit(1)
		return
	cfg.duration = 0.2
	cfg.target_radius = 100.0

	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)

	await process_frame
	await physics_frame
	await physics_frame
	await process_frame

	if abs(hero.speed_multiplier - 1.3) > 0.001:
		push_error("[test_wrath_effect] expected nearby hero speed_multiplier=1.3, got %.3f" % hero.speed_multiplier)
		quit(1)
		return
	if abs(hero.attack_speed_multiplier - 1.3) > 0.001:
		push_error("[test_wrath_effect] expected nearby hero attack_speed_multiplier=1.3, got %.3f" % hero.attack_speed_multiplier)
		quit(1)
		return
	if abs(far_hero.speed_multiplier - 1.0) > 0.001 or abs(far_hero.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_wrath_effect] far hero must remain unchanged")
		quit(1)
		return
	if hero.get_node_or_null("WrathIcon") == null:
		push_error("[test_wrath_effect] expected WrathIcon during active buff")
		quit(1)
		return

	hero.global_position = Vector2(500.0, 0.0)
	await create_timer(0.05).timeout
	if abs(hero.speed_multiplier - 1.3) > 0.001 or abs(hero.attack_speed_multiplier - 1.3) > 0.001:
		push_error("[test_wrath_effect] buff must keep snapshot-on-cast semantics after leaving radius")
		quit(1)
		return

	await create_timer(0.25).timeout
	await process_frame

	if abs(hero.speed_multiplier - 1.0) > 0.001:
		push_error("[test_wrath_effect] speed_multiplier must restore to 1.0, got %.3f" % hero.speed_multiplier)
		quit(1)
		return
	if abs(hero.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_wrath_effect] attack_speed_multiplier must restore to 1.0, got %.3f" % hero.attack_speed_multiplier)
		quit(1)
		return
	if hero.get_node_or_null("WrathIcon") != null:
		push_error("[test_wrath_effect] WrathIcon must be removed after buff ends")
		quit(1)
		return

	print("[test_wrath_effect] PASS")
	quit(0)
