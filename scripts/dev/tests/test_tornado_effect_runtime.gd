extends SceneTree

const TornadoEffectScene := preload("res://scenes/spells/effects/TornadoEffect.tscn")

var _failed: bool = false


class FakeEnemy:
	extends CharacterBody2D

	var is_dead: bool = false
	var hurtbox: Area2D

	func _ready() -> void:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		add_child(hurtbox)


func _init() -> void:
	call_deferred("_run_test")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_tornado_effect_runtime] %s" % message)
	quit(1)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		_fail(message)


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	var effect = TornadoEffectScene.instantiate()
	root.add_child(effect)
	effect.global_position = Vector2(20.0, 20.0)

	var enemy := FakeEnemy.new()
	enemy.add_to_group("enemy")
	enemy.global_position = Vector2(24.0, 20.0)
	root.add_child(enemy)
	await process_frame
	await physics_frame

	effect._capture_enemy(enemy)
	effect._update_captured_units(0.1)
	if _failed:
		return
	_assert_true(enemy.global_position.distance_to(effect.global_position) > 1.0, "Tornado runtime must move captured enemy through orbit helper path")

	print("[test_tornado_effect_runtime] PASS")
	quit(0)
