extends SceneTree

const FrailtyEffectScene := preload("res://scenes/spells/effects/FrailtyEffect.tscn")
const FrailtyConfig := preload("res://resources/spells/configs/frailty.tres")


class DummyEnemy:
	extends Node2D

	var damage_taken_multiplier: float = 1.0
	var is_dead: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var enemy := DummyEnemy.new()
	enemy.global_position = Vector2(8.0, -6.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var effect := FrailtyEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_frailty_effect] failed to instantiate FrailtyEffect")
		quit(1)
		return

	var frailty_anim := effect.get_node_or_null("FrailtyAnim") as AnimatedSprite2D
	if frailty_anim == null:
		push_error("[test_frailty_effect] Frailty scene must author FrailtyAnim directly")
		quit(1)
		return
	if frailty_anim.sprite_frames == null:
		push_error("[test_frailty_effect] FrailtyAnim must use scene-authored SpriteFrames")
		quit(1)
		return

	var cfg := FrailtyConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_frailty_effect] failed to duplicate frailty config")
		quit(1)
		return
	cfg.duration = 0.25
	cfg.target_radius = 90.0

	var target := Vector2(12.0, -4.0)
	root.add_child(effect)
	effect.initialize(cfg, target)

	await process_frame
	await process_frame

	if effect.global_position.distance_to(target) > 0.001:
		push_error("[test_frailty_effect] effect root must stay on targeted position during fall visual")
		quit(1)
		return

	await create_timer(0.7).timeout
	await process_frame

	if abs(enemy.damage_taken_multiplier - 1.3) > 0.001:
		push_error("[test_frailty_effect] nearby enemy must receive frailty multiplier 1.3, got %.3f" % enemy.damage_taken_multiplier)
		quit(1)
		return
	if enemy.get_node_or_null("FrailtyIcon") == null:
		push_error("[test_frailty_effect] expected FrailtyIcon while debuff is active")
		quit(1)
		return

	await create_timer(0.35).timeout
	await process_frame

	if abs(enemy.damage_taken_multiplier - 1.0) > 0.001:
		push_error("[test_frailty_effect] frailty multiplier must restore to 1.0, got %.3f" % enemy.damage_taken_multiplier)
		quit(1)
		return

	print("[test_frailty_effect] PASS")
	quit(0)
