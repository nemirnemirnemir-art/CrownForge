extends SceneTree

const ProjectileSpawnHelperScript := preload("res://scripts/combat/ProjectileSpawnHelper.gd")
const ArrowProjectileScene := preload("res://scenes/projectiles/ArrowProjectile.tscn")


class FakeOwner:
	extends Node2D


class FakeTarget:
	extends Node2D


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var owner := FakeOwner.new()
	owner.add_to_group("hero")
	owner.global_position = Vector2(100, 100)
	root.add_child(owner)

	var target := FakeTarget.new()
	target.add_to_group("enemy")
	target.global_position = Vector2(220, 100)
	root.add_child(target)

	var projectile := ProjectileSpawnHelperScript.spawn(ArrowProjectileScene, owner, target, 15.0, 345.0, 123.0)
	if projectile == null:
		push_error("[test_projectile_spawn_helper] helper must spawn projectile")
		quit(1)
		return
	if String(projectile.scene_file_path) != "res://scenes/projectiles/ArrowProjectile.tscn":
		push_error("[test_projectile_spawn_helper] helper must spawn requested projectile scene")
		quit(1)
		return
	if absf(float(projectile.speed) - 345.0) > 0.01:
		push_error("[test_projectile_spawn_helper] helper must apply projectile speed override")
		quit(1)
		return
	if absf(float(projectile.spin_speed_deg) - 123.0) > 0.01:
		push_error("[test_projectile_spawn_helper] helper must apply projectile spin override")
		quit(1)
		return
	if projectile.get_parent() != root:
		push_error("[test_projectile_spawn_helper] projectile must be attached to owner parent")
		quit(1)
		return

	print("[test_projectile_spawn_helper] PASS")
	quit(0)
