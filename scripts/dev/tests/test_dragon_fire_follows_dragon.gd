extends SceneTree

const DragonScene := preload("res://scenes/mobs/Dragon.tscn")

func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)

func _run_test(root: Node2D) -> void:
	var dragon := DragonScene.instantiate()
	if dragon == null:
		push_error("[test_dragon_fire_follows_dragon] failed to instantiate dragon")
		quit(1)
		return

	root.add_child(dragon)
	await process_frame
	await process_frame

	if not dragon.has_method("begin_flight_cycle"):
		push_error("[test_dragon_fire_follows_dragon] dragon missing begin_flight_cycle")
		quit(1)
		return
	if not bool(dragon.call("begin_flight_cycle")):
		push_error("[test_dragon_fire_follows_dragon] begin_flight_cycle returned false")
		quit(1)
		return

	if not dragon.has_method("start_continuous_flight_fire"):
		push_error("[test_dragon_fire_follows_dragon] dragon missing start_continuous_flight_fire")
		quit(1)
		return

	dragon.call("start_continuous_flight_fire")
	await process_frame

	var fire := dragon.get_node_or_null("FireFromDragon") as Node2D
	if fire == null:
		push_error("[test_dragon_fire_follows_dragon] FireFromDragon must be child of dragon")
		quit(1)
		return
	if fire.get_parent() != dragon:
		push_error("[test_dragon_fire_follows_dragon] FireFromDragon must be parented to dragon")
		quit(1)
		return

	var local_before: Vector2 = fire.position
	var move_delta := Vector2(-120.0, 0.0)
	dragon.global_position += move_delta
	await process_frame

	if fire.position.distance_to(local_before) > 0.01:
		push_error("[test_dragon_fire_follows_dragon] fire local offset changed unexpectedly")
		quit(1)
		return
	var expected_fire_pos: Vector2 = dragon.to_global(local_before)
	if fire.global_position.distance_to(expected_fire_pos) > 0.1:
		push_error("[test_dragon_fire_follows_dragon] fire must follow dragon transform")
		quit(1)
		return

	if not dragon.has_method("stop_continuous_flight_fire"):
		push_error("[test_dragon_fire_follows_dragon] dragon missing stop_continuous_flight_fire")
		quit(1)
		return

	dragon.call("stop_continuous_flight_fire")
	await process_frame

	if dragon.get_node_or_null("FireFromDragon") != null:
		push_error("[test_dragon_fire_follows_dragon] fire node must be removed after stop")
		quit(1)
		return

	print("[test_dragon_fire_follows_dragon] PASS")
	quit(0)
