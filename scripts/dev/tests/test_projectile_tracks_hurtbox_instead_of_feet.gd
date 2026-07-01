extends SceneTree

const ProjectileScene := preload("res://scenes/projectiles/Projectile.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var target := Node2D.new()
	target.position = Vector2(100.0, 100.0)
	root.add_child(target)

	target.add_to_group("enemy")

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.position = Vector2(0.0, -100.0)
	target.add_child(hurtbox)

	var hurtbox_shape := CollisionShape2D.new()
	hurtbox_shape.name = "CollisionShape2D"
	hurtbox_shape.position = Vector2.ZERO
	hurtbox.add_child(hurtbox_shape)

	var projectile := ProjectileScene.instantiate() as Area2D
	if projectile == null:
		push_error("[test_projectile_tracks_hurtbox_instead_of_feet] failed to instantiate Projectile")
		quit(1)
		return

	root.add_child(projectile)
	projectile.global_position = Vector2.ZERO
	projectile.call("setup", Vector2.RIGHT, 10.0, target, null)
	await process_frame

	projectile.call("_process", 0.1)

	if projectile.global_position.x < 35.0:
		push_error("[test_projectile_tracks_hurtbox_instead_of_feet] projectile did not move toward hurtbox X as expected: %s" % [projectile.global_position])
		quit(1)
		return

	if absf(projectile.global_position.y) > 5.0:
		push_error("[test_projectile_tracks_hurtbox_instead_of_feet] projectile drifted toward target feet instead of hurtbox: %s" % [projectile.global_position])
		quit(1)
		return

	print("[test_projectile_tracks_hurtbox_instead_of_feet] PASS")
	quit(0)
