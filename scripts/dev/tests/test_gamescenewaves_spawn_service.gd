extends SceneTree

const WaveSpawnServiceScript := preload("res://scripts/game_scene/modules/WaveSpawnService.gd")
const GoblinSwordsmanScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")


class FakeSingletonHost:
	extends Node2D

	var map_marker_service: Node = null
	var battle_core: Node = null

	func get_singleton(name: String) -> Node:
		match name:
			"MapMarkerService":
				return map_marker_service
			"BattleCore":
				return battle_core
			_:
				return null


class FakeMarkerService:
	extends Node

	func get_random_spawn_position(_jitter: float) -> Vector2:
		return Vector2(900.0, 240.0)

	func get_bridge_position() -> Vector2:
		return Vector2(700.0, 240.0)

	func get_portal_position() -> Vector2:
		return Vector2(1000.0, 240.0)


class FakeBattleCore:
	extends Node

	var registered: Array[Node] = []

	func register_mob(mob: Node) -> void:
		registered.append(mob)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := FakeSingletonHost.new()
	get_root().add_child(root)

	var mob_pivot := Node2D.new()
	root.add_child(mob_pivot)

	var marker_service := FakeMarkerService.new()
	root.add_child(marker_service)
	root.map_marker_service = marker_service

	var battle_core := FakeBattleCore.new()
	root.add_child(battle_core)
	root.battle_core = battle_core

	var service = WaveSpawnServiceScript.new()
	service.initialize(
		mob_pivot,
		Rect2(0.0, -400.0, 1400.0, 1400.0),
		80.0,
		func(name: String) -> Node: return root.get_singleton(name)
	)

	var spawned: Mob = service.spawn_mob_scene(GoblinSwordsmanScene, false)
	if spawned == null:
		push_error("[test_gamescenewaves_spawn_service] expected spawned mob")
		quit(1)
		return
	if absf(spawned.get_assault_lane_y() - 240.0) > 0.01:
		push_error("[test_gamescenewaves_spawn_service] lane y not propagated")
		quit(1)
		return
	if absf(spawned.get_wall_attack_stand_off() - (80.0 + spawned.get_wall_front_offset_x())) > 0.01:
		push_error("[test_gamescenewaves_spawn_service] wall stop override not propagated")
		quit(1)
		return
	if battle_core.registered.size() != 1:
		push_error("[test_gamescenewaves_spawn_service] battle core did not register mob")
		quit(1)
		return

	print("[test_gamescenewaves_spawn_service] PASS")
	quit(0)
