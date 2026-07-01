extends SceneTree

const MobScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")


class FakeWall:
	extends Node2D

	func _ready() -> void:
		add_to_group("wall")

	func get_world_rect() -> Rect2:
		return Rect2(Vector2(400.0, 100.0), Vector2(80.0, 400.0))


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := Node2D.new()
	get_root().add_child(root)

	var wall := FakeWall.new()
	root.add_child(wall)

	var mob := MobScene.instantiate() as Mob
	if mob == null:
		push_error("[test_mob_exposes_max_health_proxy] failed to instantiate GoblinSwordsman")
		quit(1)
		return
	root.add_child(mob)

	await process_frame

	var raw_max_health = mob.get("max_health")
	if typeof(raw_max_health) != TYPE_FLOAT and typeof(raw_max_health) != TYPE_INT:
		push_error("[test_mob_exposes_max_health_proxy] Mob must expose numeric max_health, got %s" % [raw_max_health])
		quit(1)
		return
	var max_health_value: float = raw_max_health
	if max_health_value <= 0.0:
		push_error("[test_mob_exposes_max_health_proxy] Mob must expose positive max_health, got %.3f" % max_health_value)
		quit(1)
		return

	if absf(max_health_value - mob.health.max_health) > 0.01:
		push_error("[test_mob_exposes_max_health_proxy] max_health proxy %.3f must match health component %.3f" % [max_health_value, mob.health.max_health])
		quit(1)
		return

	print("[test_mob_exposes_max_health_proxy] PASS")
	quit(0)
