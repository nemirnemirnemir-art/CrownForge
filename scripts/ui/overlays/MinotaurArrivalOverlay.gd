extends Control
class_name MinotaurArrivalOverlay

signal sequence_finished

@export var fade_time: float = 0.15
@export var show_time: float = 2.0

var _playing: bool = false
var _prev_tree_paused: bool = false
var _prev_speed_scale: float = 1.0

func _get_tick_manager() -> Node:
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	else:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TickManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0

func play() -> void:
	if _playing:
		return
	_playing = true
	call_deferred("_play_sequence")

func _play_sequence() -> void:
	if not is_inside_tree():
		_playing = false
		return

	var tick_manager := _get_tick_manager()
	_prev_tree_paused = get_tree().paused
	_prev_speed_scale = float(tick_manager.speed_scale) if tick_manager != null else 1.0
	if tick_manager != null:
		tick_manager.pause()
	get_tree().paused = true

	visible = true
	modulate.a = 0.0

	await _fade_alpha_to(1.0, fade_time)
	await get_tree().create_timer(show_time, true, false, true).timeout
	await _fade_alpha_to(0.0, fade_time)

	visible = false
	get_tree().paused = _prev_tree_paused
	if tick_manager != null:
		tick_manager.set_speed(_prev_speed_scale)
	sequence_finished.emit()
	_playing = false

func _fade_alpha_to(target_a: float, duration: float) -> void:
	var start_a: float = modulate.a
	var start_t: float = Time.get_ticks_msec() / 1000.0
	var end_t: float = start_t + maxf(0.001, duration)
	while true:
		var now: float = Time.get_ticks_msec() / 1000.0
		var t: float = clampf((now - start_t) / maxf(0.001, duration), 0.0, 1.0)
		modulate.a = lerpf(start_a, target_a, t)
		if now >= end_t or t >= 1.0:
			break
		await get_tree().process_frame
