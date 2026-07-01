extends SceneTree

const PoisonPuddleEffectScene := preload("res://scenes/spells/effects/PoisonPuddleEffect.tscn")
const LandmineEffectScene := preload("res://scenes/spells/effects/LandmineEffect.tscn")
const TornadoEffectScene := preload("res://scenes/spells/effects/TornadoEffect.tscn")

const PoisonPuddleConfig := preload("res://resources/spells/configs/poison_puddle.tres")
const LandmineConfig := preload("res://resources/spells/configs/landmine.tres")
const TornadoConfig := preload("res://resources/spells/configs/tornado.tres")

var _failed: bool = false


class DummyEnemy:
	extends CharacterBody2D

	var is_dead: bool = false
	var received_damage: Array[float] = []
	var _hurtbox: Hurtbox

	func _ready() -> void:
		_hurtbox = Hurtbox.new()
		_hurtbox.name = "Hurtbox"
		_hurtbox.collision_layer = 2
		_hurtbox.collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 24.0
		shape.shape = circle
		_hurtbox.add_child(shape)
		_hurtbox.set_script(preload("res://scripts/combat/Hurtbox.gd"))
		add_child(_hurtbox)

	func take_damage(amount: float) -> void:
		received_damage.append(amount)

	func apply_damage(amount: float, _source: Node = null) -> void:
		received_damage.append(amount)

	func total_damage() -> float:
		var total := 0.0
		for amount in received_damage:
			total += amount
		return total


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	await _test_poison_puddle_visual_restore(root)
	if _failed:
		return

	await _test_landmine_trigger_and_damage(root)
	if _failed:
		return

	await _test_tornado_capture_orbit_and_damage(root)
	if _failed:
		return

	print("[test_spell_effects_task_c_runtime] PASS")
	quit(0)


func _test_poison_puddle_visual_restore(root: Node2D) -> void:
	var effect := PoisonPuddleEffectScene.instantiate() as SpellEffect
	_assert_true(effect != null, "Poison puddle scene must instantiate")
	if _failed:
		return

	var config := PoisonPuddleConfig.duplicate() as SpellConfig
	_assert_true(config != null, "Poison puddle config must duplicate")
	if _failed:
		return
	config.duration = 0.12
	config.target_radius = 120.0

	var enemy := DummyEnemy.new()
	enemy.modulate = Color(0.8, 0.7, 0.6, 1.0)
	enemy.global_position = Vector2.ZERO
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	root.add_child(effect)
	await process_frame

	effect.initialize(config, Vector2.ZERO)
	await process_frame
	await process_frame

	effect._apply_poison_visual(enemy)
	await process_frame

	_assert_true(enemy.modulate.g > enemy.modulate.r, "Poison puddle must tint poisoned enemy green while active")
	if _failed:
		return

	effect._remove_all_poison_visuals()
	await process_frame
	await process_frame

	_assert_color_close(enemy.modulate, Color(0.8, 0.7, 0.6, 1.0), 0.03, "Poison puddle must restore enemy tint after expiry")

	if is_instance_valid(effect):
		effect.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	await process_frame


func _test_landmine_trigger_and_damage(root: Node2D) -> void:
	var effect := LandmineEffectScene.instantiate() as SpellEffect
	_assert_true(effect != null, "Landmine scene must instantiate")
	if _failed:
		return

	var config := LandmineConfig.duplicate() as SpellConfig
	_assert_true(config != null, "Landmine config must duplicate")
	if _failed:
		return
	config.damage = 90.0
	config.target_radius = 80.0

	var enemy := DummyEnemy.new()
	enemy.global_position = Vector2.ZERO
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	root.add_child(effect)
	await process_frame

	effect.initialize(config, Vector2.ZERO)
	await process_frame
	await process_frame

	var mine := effect as Node
	var mine_sprite := mine.get_node("MineSprite") as Sprite2D
	_assert_true(mine_sprite != null and mine_sprite.scale.x >= 0.89 and mine_sprite.scale.y >= 0.89, "Landmine visual must be doubled in size")
	if _failed:
		return

	effect._on_body_entered_trigger(enemy)
	_assert_true(effect._triggered, "Landmine must trigger when enemy enters its trigger path")
	if _failed:
		return

	await effect._trigger_explosion()
	await process_frame

	_assert_true(enemy.total_damage() >= 90.0, "Landmine explosion must damage triggering enemy")

	if is_instance_valid(enemy):
		enemy.queue_free()
	await process_frame


func _test_tornado_capture_orbit_and_damage(root: Node2D) -> void:
	var effect := TornadoEffectScene.instantiate() as SpellEffect
	_assert_true(effect != null, "Tornado scene must instantiate")
	if _failed:
		return

	var config := TornadoConfig.duplicate() as SpellConfig
	_assert_true(config != null, "Tornado config must duplicate")
	if _failed:
		return
	config.duration = 0.3
	config.target_radius = 120.0
	config.damage_per_second = 40.0

	var enemy := DummyEnemy.new()
	enemy.global_position = Vector2(24.0, 0.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)
	root.add_child(effect)
	await process_frame

	effect.initialize(config, Vector2.ZERO)
	await process_frame
	await physics_frame

	var before := enemy.global_position
	effect._capture_enemy(enemy)
	effect._update_captured_units(0.2)
	_assert_true(enemy.global_position.distance_to(before) > 1.0, "Tornado must move captured enemy in orbit")
	if _failed:
		return

	effect._apply_damage_tick(1.0)
	_assert_true(enemy.total_damage() >= 40.0, "Tornado must damage captured enemy on tick")

	if is_instance_valid(effect):
		effect.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	await process_frame


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _assert_color_close(actual: Color, expected: Color, tolerance: float, message: String) -> void:
	var matches: bool = abs(actual.r - expected.r) <= tolerance \
		and abs(actual.g - expected.g) <= tolerance \
		and abs(actual.b - expected.b) <= tolerance \
		and abs(actual.a - expected.a) <= tolerance
	if matches:
		return
	_fail("%s (expected %s, got %s)" % [message, expected, actual])


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_spell_effects_task_c_runtime] %s" % message)
	quit(1)
