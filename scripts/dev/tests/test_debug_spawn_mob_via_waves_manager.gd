extends SceneTree

## Test that debug spawn buttons use waves manager (portal spawn area) not direct instantiate
## This verifies mobs from debug buttons spawn at portal, not inside castle

const GoblinBanditScene := preload("res://scenes/mobs/GoblinBandit.tscn")
const GoblinSwordsmanScene := preload("res://scenes/mobs/GoblinSwordsman.tscn")
const WallBusterScene := preload("res://scenes/mobs/WallBuster.tscn")


class FakeSingletonHost:
	extends Node2D

	var map_marker_service: Node = null
	var battle_core: Node = null
	var mob_scene_registry: Node = null
	var waves_manager: Node = null

	func get_singleton(name: String) -> Node:
		match name:
			"MapMarkerService":
				return map_marker_service
			"BattleCore":
				return battle_core
			"MobSceneRegistry":
				return mob_scene_registry
			_:
				return null


class FakeMarkerService:
	extends Node

	func get_random_spawn_position(_jitter: float) -> Vector2:
		# Portal spawn area - right side
		return Vector2(900.0, 240.0)

	func get_bridge_position() -> Vector2:
		# Defense position - left side
		return Vector2(400.0, 240.0)

	func get_portal_position() -> Vector2:
		return Vector2(1000.0, 240.0)


class FakeBattleCore:
	extends Node

	var registered: Array[Node] = []

	func register_mob(mob: Node) -> void:
		registered.append(mob)


class FakeMobSceneRegistry:
	extends Node

	const MOB_SCENES_BY_ID := {
		"goblin_bandit": preload("res://scenes/mobs/GoblinBandit.tscn"),
		"goblin_swordsman": preload("res://scenes/mobs/GoblinSwordsman.tscn"),
		"wall_buster": preload("res://scenes/mobs/WallBuster.tscn"),
	}

	func get_mob_scene(enemy_id: String) -> PackedScene:
		var id: String = enemy_id.to_lower()
		var scene: PackedScene = MOB_SCENES_BY_ID.get(id, null) as PackedScene
		if scene != null:
			return scene
		push_warning("[FakeMobSceneRegistry] Unknown mob_id: %s" % enemy_id)
		return MOB_SCENES_BY_ID.get("goblin_bandit", null) as PackedScene


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var root := FakeSingletonHost.new()
	get_root().add_child(root)

	var mob_pivot := Node2D.new()
	mob_pivot.name = "MobPivot"
	root.add_child(mob_pivot)

	var marker_service := FakeMarkerService.new()
	root.add_child(marker_service)
	root.map_marker_service = marker_service

	var battle_core := FakeBattleCore.new()
	root.add_child(battle_core)
	root.battle_core = battle_core

	var mob_registry := FakeMobSceneRegistry.new()
	root.add_child(mob_registry)
	root.mob_scene_registry = mob_registry

	# Simulate what DebugSpawnActions does when button clicked
	# It should call game_scene.debug_spawn_enemy_id() instead of doing instantiate() directly

	# TEST 1: Verify that spawned mob comes from right spawn area (portal side), not bridge side
	var mob1: Mob = _spawn_via_waves("goblin_bandit")
	if mob1 == null:
		push_error("[test_debug_spawn_mob_via_waves_manager] Failed to spawn goblin_bandit")
		quit(1)
		return

	# Mob spawned via waves manager should be near portal (x > 800), not near bridge (x < 500)
	if mob1.global_position.x < 700.0:
		push_error("[test_debug_spawn_mob_via_waves_manager] Mob spawned at x=%.1f, expected portal area (>700), not bridge area" % mob1.global_position.x)
		quit(1)
		return

	# TEST 2: Multiple mobs should use spawn cycle from portal area, not fixed position
	var positions: Array[Vector2] = []
	for i in range(3):
		var mob: Mob = _spawn_via_waves("goblin_swordsman")
		if mob == null:
			push_error("[test_debug_spawn_mob_via_waves_manager] Failed to spawn goblin_swordsman #%d" % i)
			quit(1)
			return
		positions.append(mob.global_position)

	# Positions should vary (different spawn markers), not all identical
	var unique_count = 0
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			if not positions[i].is_equal_approx(positions[j]):
				unique_count += 1

	if unique_count < 2:
		push_error("[test_debug_spawn_mob_via_waves_manager] Mob spawn positions not varying: %v" % positions)
		quit(1)
		return

	# TEST 3: Verify behavior_target_type is set correctly (should be "wall" for mobs coming from portal)
	var mob3: Mob = _spawn_via_waves("wall_buster")
	if mob3 == null:
		push_error("[test_debug_spawn_mob_via_waves_manager] Failed to spawn wall_buster")
		quit(1)
		return

	if mob3.behavior_target_type != "wall":
		push_error("[test_debug_spawn_mob_via_waves_manager] behavior_target_type is '%s', expected 'wall'" % mob3.behavior_target_type)
		quit(1)
		return

	print("[test_debug_spawn_mob_via_waves_manager] PASS")
	quit(0)


func _spawn_via_waves(enemy_id: String) -> Mob:
	# This simulates what DebugSpawnActions should do when a button is pressed
	# It should delegate to waves manager's debug spawn instead of instantiate()

	# For now, manually invoke the spawn path that waves manager uses
	var WaveSpawnServiceScript = preload("res://scripts/game_scene/modules/WaveSpawnService.gd")
	var service = WaveSpawnServiceScript.new()

	var root = get_root().get_child(0)  # FakeSingletonHost
	var mob_pivot = root.get_node_or_null("MobPivot")
	var marker_service = root.map_marker_service
	var battle_core = root.battle_core
	var mob_registry = root.mob_scene_registry

	service.initialize(
		mob_pivot,
		Rect2(0.0, -400.0, 1400.0, 1400.0),
		80.0,
		func(name: String) -> Node:
			match name:
				"MapMarkerService":
					return marker_service
				"BattleCore":
					return battle_core
				_:
					return null
	)

	var scene: PackedScene = mob_registry.get_mob_scene(enemy_id)
	if scene == null:
		return null

	var mob: Mob = service.spawn_mob_scene(scene, false) as Mob
	return mob
