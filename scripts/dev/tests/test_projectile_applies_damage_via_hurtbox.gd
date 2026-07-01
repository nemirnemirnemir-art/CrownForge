extends SceneTree

const ProjectileScene := preload("res://scenes/projectiles/Projectile.tscn")
const HurtboxScript := preload("res://scripts/combat/Hurtbox.gd")


class DummyEnemy:
	extends Node2D

	var damage_taken: int = 0

	func take_damage(amount: int) -> void:
		damage_taken += amount


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var enemy := DummyEnemy.new()
	enemy.name = "DummyEnemy"
	enemy.add_to_group("enemy")
	enemy.global_position = Vector2(120.0, 0.0)
	root.add_child(enemy)

	var hurtbox := HurtboxScript.new()
	hurtbox.name = "Hurtbox"
	enemy.add_child(hurtbox)

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120.0, 120.0)
	shape.shape = rect
	hurtbox.add_child(shape)

	var projectile := ProjectileScene.instantiate() as Area2D
	if projectile == null:
		push_error("[test_projectile_applies_damage_via_hurtbox] failed to instantiate Projectile")
		quit(1)
		return

	root.add_child(projectile)
	projectile.global_position = Vector2.ZERO
	projectile.call("setup", Vector2.RIGHT, 17.0, enemy, root)
	await process_frame

	projectile.call("_try_damage", hurtbox)
	await process_frame

	if enemy.damage_taken != 17:
		push_error("[test_projectile_applies_damage_via_hurtbox] expected 17 damage via hurtbox, got %d" % enemy.damage_taken)
		quit(1)
		return

	if is_instance_valid(projectile):
		push_error("[test_projectile_applies_damage_via_hurtbox] projectile must free itself after successful hit")
		quit(1)
		return

	print("[test_projectile_applies_damage_via_hurtbox] PASS")
	quit(0)
