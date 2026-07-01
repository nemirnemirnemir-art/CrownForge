extends SceneTree

const ImmortalityEffectScene := preload("res://scenes/spells/effects/ImmortalityEffect.tscn")
const ImmortalityConfig := preload("res://resources/spells/configs/immortality.tres")


class DummyHero:
	extends Node2D

	var is_invincible: bool = false

	func _deferred_reflow_hack() -> void:
		pass


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var hero := DummyHero.new()
	hero.global_position = Vector2.ZERO
	hero.add_to_group("hero")
	root.add_child(hero)

	await process_frame
	await process_frame

	var leave_effect := _instantiate_effect(root, 1.0)
	if leave_effect == null:
		return

	leave_effect._track_hero_enter(hero)

	await process_frame
	await process_frame

	if not hero.is_invincible:
		push_error("[test_immortality_effect] expected hero to become invincible while inside immortality area")
		quit(1)
		return

	if _find_child_by_name(hero, "ImmortalityIcon") == null:
		push_error("[test_immortality_effect] expected ImmortalityIcon while hero stays in area")
		quit(1)
		return

	var floor_vfx := _find_child_by_name(hero, "ImmortalityFloorVfx")
	if floor_vfx == null:
		push_error("[test_immortality_effect] expected ImmortalityFloorVfx while hero stays in area")
		quit(1)
		return
	if not (floor_vfx is AnimatedSprite2D):
		push_error("[test_immortality_effect] expected ImmortalityFloorVfx to be AnimatedSprite2D")
		quit(1)
		return

	leave_effect._track_hero_exit(hero)

	await process_frame
	await process_frame

	if hero.is_invincible:
		push_error("[test_immortality_effect] hero invincibility must be removed after leaving area")
		quit(1)
		return
	if _find_child_by_name(hero, "ImmortalityIcon") != null:
		push_error("[test_immortality_effect] ImmortalityIcon must be removed after leaving area")
		quit(1)
		return
	if _find_child_by_name(hero, "ImmortalityFloorVfx") != null:
		push_error("[test_immortality_effect] ImmortalityFloorVfx must be removed after leaving area")
		quit(1)
		return

	leave_effect.queue_free()
	await process_frame
	await process_frame

	var timed_hero := DummyHero.new()
	timed_hero.global_position = Vector2(20.0, 0.0)
	timed_hero.add_to_group("hero")
	root.add_child(timed_hero)

	await process_frame

	var timed_effect := _instantiate_effect(root, 0.12)
	if timed_effect == null:
		return

	timed_effect._track_hero_enter(timed_hero)

	await process_frame
	await create_timer(0.3).timeout
	await process_frame
	await process_frame

	if timed_hero.is_invincible:
		push_error("[test_immortality_effect] hero invincibility must be removed when effect duration ends")
		quit(1)
		return
	if _find_child_by_name(timed_hero, "ImmortalityIcon") != null:
		push_error("[test_immortality_effect] ImmortalityIcon must be removed when effect duration ends")
		quit(1)
		return
	if _find_child_by_name(timed_hero, "ImmortalityFloorVfx") != null:
		push_error("[test_immortality_effect] ImmortalityFloorVfx must be removed when effect duration ends")
		quit(1)
		return
	if is_instance_valid(timed_effect):
		push_error("[test_immortality_effect] effect node should free itself after duration")
		quit(1)
		return

	print("[test_immortality_effect] PASS")
	quit(0)


func _instantiate_effect(root: Node2D, duration: float) -> SpellEffect:
	var effect := ImmortalityEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_immortality_effect] failed to instantiate ImmortalityEffect")
		quit(1)
		return null

	var cfg := ImmortalityConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_immortality_effect] failed to duplicate immortality config")
		quit(1)
		return null

	cfg.duration = duration
	cfg.target_radius = 150.0
	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)
	return effect


func _find_child_by_name(node: Node, child_name: String) -> Node:
	for child in node.get_children():
		if child.name == child_name:
			return child
	return null
