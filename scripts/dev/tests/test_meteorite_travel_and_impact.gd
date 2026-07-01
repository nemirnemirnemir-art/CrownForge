extends SceneTree

const MeteoriteConfig := preload("res://resources/spells/configs/meteorite.tres")


class DummyEnemy:
	extends Node2D

	var total_damage: float = 0.0

	func take_damage(amount: float) -> void:
		total_damage += float(amount)


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var enemy := DummyEnemy.new()
	enemy.name = "DummyEnemy"
	enemy.global_position = Vector2(420.0, 240.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var cfg := MeteoriteConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_meteorite_travel_and_impact] failed to duplicate meteorite config")
		quit(1)
		return

	if cfg.effect_scene == null:
		push_error("[test_meteorite_travel_and_impact] meteorite config has no effect_scene")
		quit(1)
		return

	var effect := cfg.effect_scene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_meteorite_travel_and_impact] failed to instantiate spell effect from meteorite config")
		quit(1)
		return
	cfg.target_radius = 80.0
	cfg.damage = 120.0

	root.add_child(effect)
	effect.initialize(cfg, enemy.global_position)

	await process_frame
	await process_frame

	var flight_sprite := effect.get_node_or_null("FlightSprite") as Sprite2D
	if flight_sprite == null:
		push_error("[test_meteorite_travel_and_impact] FlightSprite is missing")
		quit(1)
		return

	var start_pos := effect.global_position
	if start_pos.x >= enemy.global_position.x - 1.0:
		push_error("[test_meteorite_travel_and_impact] meteorite must spawn from left side off-screen, start_x=%.2f target_x=%.2f" % [start_pos.x, enemy.global_position.x])
		quit(1)
		return
	if start_pos.y >= enemy.global_position.y - 1.0:
		push_error("[test_meteorite_travel_and_impact] meteorite must spawn above target, start_y=%.2f target_y=%.2f" % [start_pos.y, enemy.global_position.y])
		quit(1)
		return

	if absf(flight_sprite.rotation) > 0.001:
		push_error("[test_meteorite_travel_and_impact] meteorite rotation must stay 0, got %.4f at spawn" % flight_sprite.rotation)
		quit(1)
		return

	await create_timer(1.00).timeout
	var mid_pos := effect.global_position
	if mid_pos.x <= start_pos.x + 5.0:
		push_error("[test_meteorite_travel_and_impact] meteorite must move left-to-right diagonally, start_x=%.2f mid_x=%.2f" % [start_pos.x, mid_pos.x])
		quit(1)
		return
	if mid_pos.y <= start_pos.y + 5.0:
		push_error("[test_meteorite_travel_and_impact] meteorite must move downward diagonally, start_y=%.2f mid_y=%.2f" % [start_pos.y, mid_pos.y])
		quit(1)
		return

	if absf(flight_sprite.rotation) > 0.001:
		push_error("[test_meteorite_travel_and_impact] meteorite rotation must stay 0 during flight, got %.4f" % flight_sprite.rotation)
		quit(1)
		return

	await create_timer(1.40).timeout
	if enemy.total_damage > 0.001:
		push_error("[test_meteorite_travel_and_impact] meteorite must not deal damage before 3.0s travel, got %.2f" % enemy.total_damage)
		quit(1)
		return

	await create_timer(1.00).timeout
	if enemy.total_damage <= 0.001:
		push_error("[test_meteorite_travel_and_impact] meteorite must deal damage after impact")
		quit(1)
		return

	await create_timer(0.80).timeout
	if is_instance_valid(effect):
		push_error("[test_meteorite_travel_and_impact] effect must cleanup after impact animation")
		quit(1)
		return

	print("[test_meteorite_travel_and_impact] PASS")
	quit(0)
