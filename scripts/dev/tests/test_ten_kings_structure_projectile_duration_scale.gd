extends SceneTree

const ProjectileEffectScene = preload("res://scenes/dev/ten_kings/effects/TenKingsProjectileEffect.tscn")


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var root := Node2D.new()
	root.name = "Root"
	get_root().add_child(root)

	var default_arrow := ProjectileEffectScene.instantiate()
	root.add_child(default_arrow)
	await process_frame
	default_arrow.launch_arrow(Vector2.ZERO, Vector2(200.0, 0.0), 1400.0)

	var scaled_arrow := ProjectileEffectScene.instantiate()
	root.add_child(scaled_arrow)
	scaled_arrow.call("launch_arrow", Vector2.ZERO, Vector2(200.0, 0.0), 1400.0, Color.WHITE, 2.0)

	if not is_equal_approx(scaled_arrow._travel_duration, default_arrow._travel_duration * 2.0):
		print("  ERROR: Arrow travel duration scale did not double travel time")
		_fail(root)
		return
	print("  Arrow travel duration scale doubles travel time")

	var default_cannonball := ProjectileEffectScene.instantiate()
	root.add_child(default_cannonball)
	default_cannonball.launch_cannonball(Vector2.ZERO, Vector2(200.0, 0.0), 1250.0)

	var scaled_cannonball := ProjectileEffectScene.instantiate()
	root.add_child(scaled_cannonball)
	scaled_cannonball.call("launch_cannonball", Vector2.ZERO, Vector2(200.0, 0.0), 1250.0, Color(0.08, 0.08, 0.1, 1.0), 2.0)

	if not is_equal_approx(scaled_cannonball._travel_duration, default_cannonball._travel_duration * 2.0):
		print("  ERROR: Cannonball travel duration scale did not double travel time")
		_fail(root)
		return
	print("  Cannonball travel duration scale doubles travel time")

	root.queue_free()
	print("PASS: test_ten_kings_structure_projectile_duration_scale")
	quit(0)


func _fail(root: Node) -> void:
	if root != null and is_instance_valid(root):
		root.queue_free()
	print("FAIL: test_ten_kings_structure_projectile_duration_scale")
	quit(1)
