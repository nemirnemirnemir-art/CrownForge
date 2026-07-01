extends RefCounted
class_name GameScenePauseState

const PAUSE_SPEED_EPSILON := 0.001
const DEBUG_PAUSE_TRACE := true

var _prophecy_prev_tree_paused: bool = false
var _prophecy_prev_tick_speed: float = 1.0
var _prophecy_pause_applied: bool = false
var _encounter_prev_tree_paused: bool = false
var _encounter_prev_tick_speed: float = 1.0
var _encounter_pause_applied: bool = false
var _game_scene: Node = null

func _get_singleton(node_name: String) -> Node:
	var tree: SceneTree = null
	if _game_scene != null and is_instance_valid(_game_scene) and _game_scene.get_tree() != null:
		tree = _game_scene.get_tree()
	else:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

func _get_tick_manager() -> Node:
	return _get_singleton("TickManager")

func _debug_state(context: String) -> void:
	if not DEBUG_PAUSE_TRACE:
		return
	var tree_paused := false
	if _game_scene and _game_scene.get_tree():
		tree_paused = _game_scene.get_tree().paused
	var tick_speed := -1.0
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		tick_speed = float(tick_manager.speed_scale)
	print("[PauseState][DEBUG] %s | tree_paused=%s tick_speed=%.2f prophecy_applied=%s encounter_applied=%s p_prev=(%s,%.2f) e_prev=(%s,%.2f)" % [
		context,
		str(tree_paused),
		tick_speed,
		str(_prophecy_pause_applied),
		str(_encounter_pause_applied),
		str(_prophecy_prev_tree_paused),
		_prophecy_prev_tick_speed,
		str(_encounter_prev_tree_paused),
		_encounter_prev_tick_speed,
	])

func initialize(game_scene: Node) -> void:
	_game_scene = game_scene

func apply_prophecy_pause() -> void:
	if _prophecy_pause_applied:
		_debug_state("apply_prophecy_pause skipped (already applied)")
		return
	var tree: SceneTree = _game_scene.get_tree()
	if tree:
		_prophecy_prev_tree_paused = tree.paused
		tree.paused = true
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		_prophecy_prev_tick_speed = float(tick_manager.speed_scale)
		tick_manager.pause()
	_prophecy_pause_applied = true
	_debug_state("apply_prophecy_pause")

func release_prophecy_pause() -> void:
	if not _prophecy_pause_applied:
		_debug_state("release_prophecy_pause skipped (not applied)")
		return
	var tree: SceneTree = _game_scene.get_tree()
	if tree:
		tree.paused = _prophecy_prev_tree_paused
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		tick_manager.set_speed(_prophecy_prev_tick_speed)
	_prophecy_pause_applied = false
	_debug_state("release_prophecy_pause")

func apply_encounter_pause() -> void:
	if _encounter_pause_applied:
		_debug_state("apply_encounter_pause skipped (already applied)")
		return
	var tree: SceneTree = _game_scene.get_tree()
	if tree:
		_encounter_prev_tree_paused = tree.paused
		tree.paused = true
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		_encounter_prev_tick_speed = float(tick_manager.speed_scale)
		tick_manager.pause()
	_encounter_pause_applied = true
	_debug_state("apply_encounter_pause")

func transfer_prophecy_pause_to_encounter() -> void:
	# Preserve original pre-prophecy state for encounter release without unpausing in between.
	if _prophecy_pause_applied:
		_encounter_prev_tree_paused = _prophecy_prev_tree_paused
		_encounter_prev_tick_speed = _prophecy_prev_tick_speed
		_encounter_pause_applied = true
		_prophecy_pause_applied = false
		_debug_state("transfer_prophecy_pause_to_encounter")
		return
	apply_encounter_pause()

func release_encounter_pause() -> void:
	if not _encounter_pause_applied:
		_debug_state("release_encounter_pause skipped (not applied)")
		return
	var tree: SceneTree = _game_scene.get_tree()
	if tree:
		tree.paused = _encounter_prev_tree_paused
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		tick_manager.set_speed(_encounter_prev_tick_speed)
	_encounter_pause_applied = false
	_debug_state("release_encounter_pause")

func is_effectively_paused() -> bool:
	var tree: SceneTree = _game_scene.get_tree()
	if tree and tree.paused:
		return true
	var tick_manager := _get_tick_manager()
	if tick_manager != null:
		return float(tick_manager.speed_scale) <= PAUSE_SPEED_EPSILON
	return false

func is_prophecy_pause_applied() -> bool:
	return _prophecy_pause_applied

func set_prophecy_pause_applied(value: bool) -> void:
	_prophecy_pause_applied = value
