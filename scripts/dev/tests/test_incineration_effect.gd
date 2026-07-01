extends SceneTree

const IncinerationConfig := preload("res://resources/spells/configs/incineration.tres")

var _failed: bool = false


class DummyEnemy:
	extends Node2D

	var is_dead: bool = false
	var received_damage: Array[float] = []

	func apply_damage(amount: float, _source: Node = null) -> void:
		received_damage.append(amount)

	func take_damage(amount: float) -> void:
		received_damage.append(amount)

	func total_damage() -> float:
		var total := 0.0
		for amount in received_damage:
			total += amount
		return total


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var cfg := IncinerationConfig.duplicate() as SpellConfig
	_assert_true(cfg != null, "Incineration config must duplicate")
	if _failed:
		return

	_assert_true(cfg.effect_scene != null, "Incineration config must reference an effect scene")
	if _failed:
		return

	cfg.damage = 150.0
	cfg.target_radius = 100.0
	cfg.duration = 0.2

	var near_enemy := DummyEnemy.new()
	near_enemy.global_position = Vector2(30.0, 0.0)
	near_enemy.add_to_group("enemy")
	root.add_child(near_enemy)

	var far_enemy := DummyEnemy.new()
	far_enemy.global_position = Vector2(240.0, 0.0)
	far_enemy.add_to_group("enemy")
	root.add_child(far_enemy)

	var effect := cfg.effect_scene.instantiate() as SpellEffect
	_assert_true(effect != null, "Incineration effect scene must instantiate")
	if _failed:
		return

	root.add_child(effect)
	effect.initialize(cfg, Vector2.ZERO)

	await process_frame
	await process_frame

	_assert_true(near_enemy.total_damage() >= 150.0, "Incineration must damage enemies inside its AoE")
	_assert_true(far_enemy.total_damage() == 0.0, "Incineration must not damage enemies outside its AoE")
	_assert_true(effect.get_child_count() > 0, "Incineration must spawn visual content when cast")
	if _failed:
		return

	await create_timer(0.35).timeout
	await process_frame

	_assert_true(not is_instance_valid(effect), "Incineration effect must clean itself up after visuals finish")
	if _failed:
		return

	print("[test_incineration_effect] PASS")
	quit(0)


func _assert_true(value: bool, message: String) -> void:
	if value:
		return
	_fail(message)


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_incineration_effect] %s" % message)
	quit(1)
