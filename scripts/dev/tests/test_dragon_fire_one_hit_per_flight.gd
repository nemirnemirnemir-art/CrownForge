extends SceneTree

const DragonScene := preload("res://scenes/mobs/Dragon.tscn")

class DummyTarget:
	extends Node2D

	var hits: Array[int] = []
	var is_dead: bool = false

	func take_damage(amount: int) -> void:
		hits.append(amount)

	func get_max_hp() -> float:
		return 100.0

func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)

func _run_test(root: Node2D) -> void:
	var dragon := DragonScene.instantiate()
	if dragon == null:
		push_error("[test_dragon_fire_one_hit_per_flight] failed to instantiate dragon")
		quit(1)
		return

	root.add_child(dragon)
	await process_frame
	await process_frame

	var target := DummyTarget.new()
	target.name = "DummyHero"
	target.global_position = dragon.global_position
	root.add_child(target)

	if not dragon.has_method("begin_flight_cycle"):
		push_error("[test_dragon_fire_one_hit_per_flight] Dragon missing begin_flight_cycle")
		quit(1)
		return

	if not bool(dragon.call("begin_flight_cycle")):
		push_error("[test_dragon_fire_one_hit_per_flight] begin_flight_cycle returned false")
		quit(1)
		return

	var flight_id := int(dragon.call("get_current_flight_id"))
	dragon.call("try_apply_flight_fire_hit", target, flight_id)
	dragon.call("try_apply_flight_fire_hit", target, flight_id)

	if target.hits.size() != 1:
		push_error("[test_dragon_fire_one_hit_per_flight] expected exactly one direct hit, got %d" % target.hits.size())
		quit(1)
		return
	if target.hits[0] != 50:
		push_error("[test_dragon_fire_one_hit_per_flight] direct hit must be 50, got %d" % target.hits[0])
		quit(1)
		return

	await create_timer(3.3).timeout

	if target.hits.size() != 4:
		push_error("[test_dragon_fire_one_hit_per_flight] expected 1 direct + 3 burn ticks, got %d" % target.hits.size())
		quit(1)
		return

	for i in range(1, 4):
		if target.hits[i] != 5:
			push_error("[test_dragon_fire_one_hit_per_flight] burn tick %d must be 5, got %d" % [i, target.hits[i]])
			quit(1)
			return

	print("[test_dragon_fire_one_hit_per_flight] PASS")
	quit(0)
