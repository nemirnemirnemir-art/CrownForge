extends SceneTree

const RootsEffectScene := preload("res://scenes/spells/effects/RootsEffect.tscn")
const RootsConfig := preload("res://resources/spells/configs/roots.tres")


class DummyEnemy:
	extends CharacterBody2D

	var is_dead: bool = false
	var damage_events: Array[float] = []

	func take_damage(amount: float) -> void:
		damage_events.append(amount)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var near_enemy := DummyEnemy.new()
	near_enemy.global_position = Vector2(16.0, 0.0)
	near_enemy.add_to_group("enemy")
	root.add_child(near_enemy)

	var far_enemy := DummyEnemy.new()
	far_enemy.global_position = Vector2(220.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	var effect := RootsEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_roots_effect] failed to instantiate RootsEffect")
		quit(1)
		return

	var roots_anim := effect.get_node_or_null("RootsAnim") as AnimatedSprite2D
	if roots_anim == null:
		push_error("[test_roots_effect] Roots scene must author RootsAnim directly")
		quit(1)
		return
	if roots_anim.sprite_frames == null:
		push_error("[test_roots_effect] RootsAnim must use scene-authored SpriteFrames")
		quit(1)
		return

	var cfg := RootsConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_roots_effect] failed to duplicate roots config")
		quit(1)
		return
	cfg.target_radius = 90.0

	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)

	await process_frame
	await process_frame
	await physics_frame

	if near_enemy.damage_events.is_empty():
		push_error("[test_roots_effect] nearby enemy must receive immediate roots impact")
		quit(1)
		return
	if abs(near_enemy.damage_events[0] - 60.0) > 0.001:
		push_error("[test_roots_effect] roots impact must deal 60 damage, got %.3f" % near_enemy.damage_events[0])
		quit(1)
		return
	if near_enemy.velocity.length() <= 0.001:
		push_error("[test_roots_effect] roots must push nearby enemy away from center")
		quit(1)
		return
	if not far_enemy.damage_events.is_empty():
		push_error("[test_roots_effect] far enemy must stay unaffected")
		quit(1)
		return

	await create_timer(4.2).timeout

	if near_enemy.damage_events.size() != 5:
		push_error("[test_roots_effect] expected 1 impact + 4 poison ticks, got %d events" % near_enemy.damage_events.size())
		quit(1)
		return

	var total_damage := 0.0
	for event_damage in near_enemy.damage_events:
		total_damage += event_damage
	if abs(total_damage - 116.0) > 0.001:
		push_error("[test_roots_effect] expected total damage 116.0, got %.3f" % total_damage)
		quit(1)
		return

	print("[test_roots_effect] PASS")
	quit(0)
