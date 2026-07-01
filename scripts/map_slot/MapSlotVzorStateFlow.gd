extends RefCounted
class_name MapSlotVzorStateFlow

var _vzor_active: bool = false
var _king_vzor_active: bool = false
var _external_vzor_sources: Dictionary = {}
var _vzor_anim_frame: int = 0
var _mine_anim_time: float = 0.0
var _base_sprite_position: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_sprite_rotation: float = 0.0
var _external_gaze_debug_elapsed: float = 0.0

var _vzor_visual_flow: RefCounted = null
var _sprite: Sprite2D = null
var _anim_vzor: AnimatedSprite2D = null
var _mine_visuals: Dictionary = {}


func initialize(
	vzor_visual_flow: RefCounted,
	sprite: Sprite2D,
	anim_vzor: AnimatedSprite2D,
	mine_visuals: Dictionary
) -> void:
	_vzor_visual_flow = vzor_visual_flow
	_sprite = sprite
	_anim_vzor = anim_vzor
	_mine_visuals = mine_visuals
	if sprite:
		_base_sprite_position = sprite.position
		_base_sprite_scale = sprite.scale
		_base_sprite_rotation = sprite.rotation


func set_vzor_active(active: bool, current_building_id: String, special_handler: RefCounted) -> void:
	_king_vzor_active = active
	_refresh_vzor_state(current_building_id, special_handler)


func set_external_vzor_active(source_id: String, active: bool, current_building_id: String, special_handler: RefCounted) -> void:
	var key := source_id.strip_edges()
	if key == "":
		return
	if active:
		_external_vzor_sources[key] = true
	else:
		_external_vzor_sources.erase(key)
	_refresh_vzor_state(current_building_id, special_handler)


func is_effectively_vzor_active() -> bool:
	return _vzor_active


func is_king_vzor_active() -> bool:
	return _king_vzor_active


func is_external_vzor_active() -> bool:
	return not _external_vzor_sources.is_empty()


func get_external_vzor_sources() -> Dictionary:
	return _external_vzor_sources


func tick_external_gaze(delta: float, tick_active_building: Callable) -> void:
	if _external_vzor_sources.is_empty():
		return
	if tick_active_building.is_valid():
		tick_active_building.call(delta)


func tick_effective_vzor(
	delta: float,
	current_building_id: String,
	slot_index: int,
	debug_direct_vzor_special: bool,
	tick_active_building: Callable
) -> void:
	if not _king_vzor_active:
		return
	if debug_direct_vzor_special and current_building_id in ["tesla_tower", "monument_to_the_kings_gaze"]:
		print("[MapSlot][DirectVzor] slot=%d building=%s delta=%.3f king_vzor=%s external=%s" % [
			slot_index,
			current_building_id,
			delta,
			str(_king_vzor_active),
			str(not _external_vzor_sources.is_empty()),
		])
	if tick_active_building.is_valid():
		tick_active_building.call(delta)


func debug_external_gaze_tick(
	delta: float,
	result: Dictionary,
	current_building_id: String,
	slot_index: int,
	debug_external_gaze: bool
) -> void:
	if not debug_external_gaze:
		return
	if _king_vzor_active:
		return
	if _external_vzor_sources.is_empty():
		_external_gaze_debug_elapsed = 0.0
		return
	_external_gaze_debug_elapsed += maxf(0.0, delta)
	var should_log := bool(result.get("completed", false)) or _external_gaze_debug_elapsed >= 1.0
	if not should_log:
		return
	_external_gaze_debug_elapsed = 0.0
	print("[MapSlot][ExternalGaze] slot=%d building=%s producing=%s progress=%.3f completed=%s cycle=%.3f sources=%s" % [
		slot_index,
		current_building_id,
		str(bool(result.get("is_producing", false))),
		float(result.get("progress_ratio", 0.0)),
		str(bool(result.get("completed", false))),
		float(result.get("cycle_time", 0.0)),
		_external_vzor_sources.keys(),
	])


func apply_mine_visual_state(current_building_id: String) -> void:
	if _vzor_visual_flow:
		_vzor_visual_flow.apply_mine_visual_state(_build_vzor_state(current_building_id), _sprite, _mine_visuals)


func is_active_mine_visual(current_building_id: String) -> bool:
	if _vzor_visual_flow:
		return _vzor_visual_flow.is_active_mine_visual(_build_vzor_state(current_building_id), _sprite, _anim_vzor, _mine_visuals)
	return false


func reset_active_mine_transform(current_building_id: String) -> void:
	if _vzor_visual_flow:
		_vzor_visual_flow.reset_active_mine_transform(_build_vzor_state(current_building_id), _sprite)


func update_active_mine_animation(
	delta: float,
	current_building_id: String,
	anim_speed: float,
	rotation_degrees: float,
	scale_pulse: float,
	shake_pixels: float
) -> void:
	if _vzor_visual_flow == null:
		return
	var state := _build_vzor_state(current_building_id)
	_vzor_visual_flow.update_active_mine_animation(
		state, _sprite, _anim_vzor, _mine_visuals,
		delta * anim_speed, rotation_degrees, scale_pulse, shake_pixels
	)
	_sync_vzor_state_from_dict(state)


func _refresh_vzor_state(current_building_id: String, special_handler: RefCounted) -> void:
	if _vzor_visual_flow == null:
		return
	var state := _build_vzor_state(current_building_id)
	var bid := current_building_id
	_vzor_visual_flow.refresh_vzor_state(
		state,
		_sprite,
		_anim_vzor,
		special_handler,
		_mine_visuals,
		func() -> void: apply_mine_visual_state(bid),
		func() -> void: reset_active_mine_transform(bid)
	)
	_sync_vzor_state_from_dict(state)


func _build_vzor_state(current_building_id: String) -> Dictionary:
	return {
		"current_building_id": current_building_id,
		"vzor_active": _vzor_active,
		"king_vzor_active": _king_vzor_active,
		"external_vzor_sources": _external_vzor_sources.duplicate(true),
		"vzor_anim_frame": _vzor_anim_frame,
		"mine_anim_time": _mine_anim_time,
		"base_sprite_position": _base_sprite_position,
		"base_sprite_rotation": _base_sprite_rotation,
		"base_sprite_scale": _base_sprite_scale,
	}


func _sync_vzor_state_from_dict(state: Dictionary) -> void:
	_vzor_active = bool(state.get("vzor_active", _vzor_active))
	_king_vzor_active = bool(state.get("king_vzor_active", _king_vzor_active))
	var external_sources: Variant = state.get("external_vzor_sources", _external_vzor_sources)
	if external_sources is Dictionary:
		_external_vzor_sources = (external_sources as Dictionary).duplicate(true)
	_vzor_anim_frame = int(state.get("vzor_anim_frame", _vzor_anim_frame))
	_mine_anim_time = float(state.get("mine_anim_time", _mine_anim_time))
	_base_sprite_position = state.get("base_sprite_position", _base_sprite_position)
	_base_sprite_rotation = float(state.get("base_sprite_rotation", _base_sprite_rotation))
	_base_sprite_scale = state.get("base_sprite_scale", _base_sprite_scale)


func load_visual_runtime_state(state: Dictionary) -> void:
	_sync_vzor_state_from_dict(state)
