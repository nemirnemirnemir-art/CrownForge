extends SceneTree

const MobWallTargetingFlowScript := preload("res://scripts/mob/modules/MobWallTargetingFlow.gd")


class FakeLaneAssault:
	extends RefCounted

	func get_wall_contact_point(_rect: Rect2, current_y: float, _bounds: Rect2) -> Vector2:
		return Vector2(100.0, current_y)

	func get_wall_approach_point(_rect: Rect2, current_y: float, stand_off: float, _bounds: Rect2) -> Vector2:
		return Vector2(100.0 + stand_off, current_y)

	func get_distance_to_wall(_rect: Rect2, _pos: Vector2) -> float:
		return 55.0


class FakeRuntimeBridge:
	extends RefCounted

	var singletons: Dictionary = {}

	func get_singleton(name: String):
		return singletons.get(name, null)


class FakeWall:
	extends Node2D

	func _ready() -> void:
		add_to_group("wall")

	func get_world_rect() -> Rect2:
		return Rect2(Vector2(80, 20), Vector2(20, 100))


class FakeMarkerService:
	extends RefCounted

	func get_wall_position() -> Vector2:
		return Vector2(90, 30)


class FakeMob:
	extends Node2D

	var _hurtbox := Area2D.new()
	var _lane_assault = FakeLaneAssault.new()
	var _runtime_bridge = FakeRuntimeBridge.new()
	var projectile_scene = null
	var movement = null

	func get_map_bounds() -> Rect2:
		return Rect2(0, 0, 400, 200)

	func get_assault_lane_y() -> float:
		return global_position.y


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MobWallTargetingFlowScript.new()
	if flow == null:
		push_error("[test_mob_wall_targeting_flow] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	get_root().add_child(mob)
	mob.global_position = Vector2(200, 60)
	mob.scale = Vector2.ONE
	var wall := FakeWall.new()
	get_root().add_child(wall)
	var marker_service := FakeMarkerService.new()
	mob._runtime_bridge.singletons = {"MapMarkerService": marker_service, "Wall": wall}
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(40, 20)
	mob._hurtbox.add_child(shape)
	await process_frame

	flow.setup(mob)
	if flow.get_wall_target_node() != wall:
		push_error("[test_mob_wall_targeting_flow] wall node lookup mismatch")
		quit(1)
		return
	if flow.get_wall_contact_position().distance_to(Vector2(100, 60)) > 0.01:
		push_error("[test_mob_wall_targeting_flow] wall contact mismatch")
		quit(1)
		return
	if absf(flow.get_distance_to_wall() - 55.0) > 0.01:
		push_error("[test_mob_wall_targeting_flow] wall distance mismatch")
		quit(1)
		return
	if not flow.has_method("get_wall_attack_range"):
		push_error("[test_mob_wall_targeting_flow] flow must own wall attack range helper")
		quit(1)
		return
	if absf(flow.get_wall_attack_range() - 170.0) > 0.01:
		push_error("[test_mob_wall_targeting_flow] melee wall range mismatch")
		quit(1)
		return
	var front_offset := flow.get_wall_front_offset_x()
	if absf(flow.get_wall_attack_stand_off() - (50.0 + front_offset)) > 0.01:
		push_error("[test_mob_wall_targeting_flow] default wall stand-off mismatch")
		quit(1)
		return
	flow.set_wall_attack_stop_distance(120.0)
	if absf(flow.get_wall_attack_trigger_distance() - (120.0 + front_offset)) > 0.01:
		push_error("[test_mob_wall_targeting_flow] override trigger distance mismatch")
		quit(1)
		return
	mob.projectile_scene = PackedScene.new()
	if absf(flow.get_wall_attack_range() - 320.0) > 0.01:
		push_error("[test_mob_wall_targeting_flow] ranged wall range mismatch")
		quit(1)
		return

	print("[test_mob_wall_targeting_flow] PASS")
	quit(0)
