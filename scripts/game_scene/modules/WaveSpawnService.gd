extends RefCounted
class_name WaveSpawnService

const PORTAL_SPAWN_JITTER := 35.0
const PORTAL_SPAWN_X_OFFSET := -50.0

var _mob_container: Node2D = null
var _map_bounds: Rect2 = Rect2()
var _wall_attack_stop_distance: float = -1.0
var _get_singleton: Callable = Callable()


func initialize(mob_container: Node2D, map_bounds: Rect2, wall_attack_stop_distance: float, get_singleton: Callable) -> void:
	_mob_container = mob_container
	_map_bounds = map_bounds
	_wall_attack_stop_distance = wall_attack_stop_distance
	_get_singleton = get_singleton


func spawn_mob_scene(scene: PackedScene, _track_for_wave: bool = false) -> Mob:
	if _mob_container == null:
		return null
	var mob_node: Node = scene.instantiate()
	if mob_node == null or not mob_node is Mob:
		return null
	var mob := mob_node as Mob
	var spawn_position := get_portal_spawn_position(PORTAL_SPAWN_JITTER)
	mob.position = _mob_container.to_local(spawn_position)
	if mob.has_method("set_assault_lane_y"):
		mob.set_assault_lane_y(spawn_position.y)
	if _wall_attack_stop_distance >= 0.0 and mob.has_method("set_wall_attack_stop_distance"):
		mob.set_wall_attack_stop_distance(_wall_attack_stop_distance)
	_mob_container.add_child(mob)

	var marker_service := _resolve_singleton("MapMarkerService")
	if marker_service:
		if marker_service.has_method("get_bridge_position"):
			mob.bridge_position = marker_service.call("get_bridge_position")
		if marker_service.has_method("get_portal_position"):
			mob.portal_position = marker_service.call("get_portal_position")
	mob.center_position = (mob.portal_position + mob.bridge_position) / 2.0
	mob.behavior_target_type = "wall"
	mob.set_map_bounds(_map_bounds)

	var speed_variants := [0.80, 0.85, 0.90, 0.95, 1.05, 1.10, 1.15, 1.20]
	var speed_multiplier: float = float(speed_variants[randi() % speed_variants.size()])
	if mob.has_method("apply_spawn_speed_variance"):
		mob.apply_spawn_speed_variance(speed_multiplier)

	var battle_core := _resolve_singleton("BattleCore")
	if battle_core and battle_core.has_method("register_mob"):
		battle_core.register_mob(mob)
	var artifact_core := _resolve_singleton("ArtifactCore")
	if artifact_core and artifact_core.has_method("on_enemy_spawned"):
		artifact_core.on_enemy_spawned(mob)

	return mob


func spawn_tracked_mob_scene(scene: PackedScene, track_for_wave: bool, wave_state_flow, wave_state: Dictionary, on_mob_died: Callable) -> Mob:
	var mob: Mob = spawn_mob_scene(scene, track_for_wave)
	if mob == null:
		push_error("[WaveSpawnService] Failed to instantiate mob from scene")
		return null
	if track_for_wave and wave_state_flow != null and wave_state_flow.has_method("register_spawned_mob"):
		wave_state_flow.register_spawned_mob(wave_state, mob, true)
	if on_mob_died.is_valid():
		mob.tree_exited.connect(on_mob_died.bind(mob, track_for_wave))
	return mob


func spawn_enemy_id_count(enemy_id: String, count: int, track_for_wave: bool, mob_scene_registry, wave_state_flow, wave_state: Dictionary, on_mob_died: Callable) -> int:
	var safe_count: int = max(0, count)
	if safe_count <= 0:
		return 0
	if mob_scene_registry == null or not mob_scene_registry.has_method("get_mob_scene"):
		push_error("[WaveSpawnService] Mob scene registry missing")
		return 0
	var scene: PackedScene = mob_scene_registry.get_mob_scene(enemy_id)
	if scene == null:
		return 0
	for _i in range(safe_count):
		spawn_tracked_mob_scene(scene, track_for_wave, wave_state_flow, wave_state, on_mob_died)
	if wave_state_flow != null and wave_state_flow.has_method("register_spawned_count"):
		wave_state_flow.register_spawned_count(wave_state, enemy_id.to_lower(), safe_count)
	return safe_count


func spawn_prophecy_patterns(patterns: Array, track_for_wave: bool, spawn_enemy_id_count_callable: Callable, collect_rewards_callable: Callable, fallback_callable: Callable) -> int:
	if patterns == null or patterns.is_empty():
		return int(fallback_callable.call()) if fallback_callable.is_valid() else 0

	var spawned: int = 0
	for pattern in patterns:
		if pattern == null:
			continue
		if spawn_enemy_id_count_callable.is_valid():
			spawned += int(spawn_enemy_id_count_callable.call(pattern.mob_1_id, pattern.mob_1_count, track_for_wave))
			if pattern.mob_2_enabled and pattern.mob_2_id != "":
				spawned += int(spawn_enemy_id_count_callable.call(pattern.mob_2_id, pattern.mob_2_count, track_for_wave))
		if collect_rewards_callable.is_valid():
			collect_rewards_callable.call(pattern)
	return spawned


func get_portal_spawn_position(jitter: float = PORTAL_SPAWN_JITTER) -> Vector2:
	var marker_service := _resolve_singleton("MapMarkerService")
	if marker_service and marker_service.has_method("get_random_spawn_position"):
		return marker_service.call("get_random_spawn_position", jitter) + Vector2(PORTAL_SPAWN_X_OFFSET, 0.0)
	return Vector2(PORTAL_SPAWN_X_OFFSET, 0.0)
func _resolve_singleton(name: String) -> Node:
	if _get_singleton.is_valid():
		return _get_singleton.call(name)
	return null
