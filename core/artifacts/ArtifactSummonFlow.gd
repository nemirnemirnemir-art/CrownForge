extends RefCounted
class_name ArtifactSummonFlow

const TEMP_SUMMON_EVENT_PREFIX := "temp_summon"
const TEMP_SUMMON_DURATION_MULTIPLIER := 3.0

static var _pending_temporary_deaths: Dictionary = {}

static func get_temporary_unit_duration(active: Dictionary, base_duration: float) -> float:
	var duration := maxf(0.1, base_duration)
	if active.has("sturdy_candle"):
		duration *= TEMP_SUMMON_DURATION_MULTIPLIER
	return duration

static func spawn_temporary_units(active: Dictionary, unit_id: String, count: int, base_duration: float, positions: Array = []) -> void:
	var safe_unit_id := String(unit_id).strip_edges().to_lower()
	if safe_unit_id == "":
		return
	var safe_count: int = max(0, count)
	if safe_count <= 0:
		return
	var duration := get_temporary_unit_duration(active, base_duration)
	var game_scene := _get_game_scene()
	if game_scene == null:
		return
	for i in range(safe_count):
		var override_position := Vector2.INF
		if i < positions.size() and positions[i] is Vector2:
			override_position = positions[i]
		if game_scene.has_method("spawn_temporary_hero_on_field"):
			game_scene.call("spawn_temporary_hero_on_field", safe_unit_id, duration, override_position)

static func register_temporary_death(unit_id: String, position: Vector2, duration: float) -> String:
	var safe_unit_id := String(unit_id).strip_edges().to_lower()
	if safe_unit_id == "":
		return ""
	var token := "%s:%s:%d" % [TEMP_SUMMON_EVENT_PREFIX, safe_unit_id, Time.get_ticks_usec()]
	_pending_temporary_deaths[token] = {
		"unit_id": safe_unit_id,
		"position": position,
		"duration": maxf(0.1, duration),
	}
	return token

static func try_resummon_temporary_unit(active: Dictionary, event_id: String) -> bool:
	var token := String(event_id).strip_edges()
	if token == "" or not _pending_temporary_deaths.has(token):
		return false
	var payload: Dictionary = _pending_temporary_deaths.get(token, {})
	_pending_temporary_deaths.erase(token)
	if not active.has("second_chance"):
		return false
	if randf() >= 0.5:
		return false
	spawn_temporary_units(
		active,
		String(payload.get("unit_id", "")),
		1,
		float(payload.get("duration", 1.0)),
		[payload.get("position", Vector2.INF)]
	)
	return true

static func _get_game_scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene != null:
		return game_scene
	return tree.current_scene
