extends RefCounted
class_name MapSlotVzorVisualFlow


func refresh_vzor_state(
	state: Dictionary,
	sprite: Sprite2D,
	anim_vzor: AnimatedSprite2D,
	special_handler: RefCounted,
	mine_visuals: Dictionary,
	apply_mine_visual_state: Callable,
	reset_active_mine_transform: Callable
) -> void:
	var next_active := bool(state.get("king_vzor_active", false)) or not Dictionary(state.get("external_vzor_sources", {})).is_empty()
	if bool(state.get("vzor_active", false)) == next_active:
		if special_handler and special_handler.has_method("set_vzor_active"):
			special_handler.call("set_vzor_active", next_active)
		if apply_mine_visual_state.is_valid():
			apply_mine_visual_state.call()
		return
	state["vzor_active"] = next_active
	if special_handler and special_handler.has_method("set_vzor_active"):
		special_handler.call("set_vzor_active", next_active)

	if anim_vzor == null or not anim_vzor.visible:
		if apply_mine_visual_state.is_valid():
			apply_mine_visual_state.call()
		return

	if next_active:
		if anim_vzor.sprite_frames and anim_vzor.sprite_frames.has_animation(anim_vzor.animation):
			anim_vzor.frame = int(state.get("vzor_anim_frame", 0))
			anim_vzor.play(anim_vzor.animation)
	else:
		state["vzor_anim_frame"] = anim_vzor.frame
		anim_vzor.stop()
		anim_vzor.frame = int(state.get("vzor_anim_frame", 0))

	if not next_active and reset_active_mine_transform.is_valid():
		reset_active_mine_transform.call()
	if apply_mine_visual_state.is_valid():
		apply_mine_visual_state.call()


func apply_mine_visual_state(state: Dictionary, sprite: Sprite2D, mine_visuals: Dictionary) -> void:
	if sprite == null or not sprite.visible:
		return
	var current_building_id := String(state.get("current_building_id", ""))
	if current_building_id == "":
		return
	if not mine_visuals.has(current_building_id):
		return
	var visual_def: Dictionary = mine_visuals[current_building_id]
	var target_path := String(visual_def.get("active" if bool(state.get("vzor_active", false)) else "inactive", ""))
	if target_path == "":
		return
	var tex := load(target_path)
	if tex is Texture2D:
		sprite.texture = tex
	if not bool(state.get("vzor_active", false)):
		reset_active_mine_transform(state, sprite)


func is_active_mine_visual(state: Dictionary, sprite: Sprite2D, anim_vzor: AnimatedSprite2D, mine_visuals: Dictionary) -> bool:
	var current_building_id := String(state.get("current_building_id", ""))
	if current_building_id == "":
		return false
	if not bool(state.get("vzor_active", false)):
		return false
	if not mine_visuals.has(current_building_id):
		return false
	if sprite == null or not sprite.visible:
		return false
	if anim_vzor and anim_vzor.visible:
		return false
	return true


func reset_active_mine_transform(state: Dictionary, sprite: Sprite2D) -> void:
	if sprite == null:
		return
	sprite.position = Vector2(state.get("base_sprite_position", Vector2.ZERO))
	sprite.rotation = float(state.get("base_sprite_rotation", 0.0))
	sprite.scale = Vector2(state.get("base_sprite_scale", Vector2.ONE))


func update_active_mine_animation(
	state: Dictionary,
	sprite: Sprite2D,
	anim_vzor: AnimatedSprite2D,
	mine_visuals: Dictionary,
	delta: float,
	rotation_degrees: float,
	scale_pulse: float,
	shake_pixels: float
) -> void:
	if sprite == null:
		return
	if not is_active_mine_visual(state, sprite, anim_vzor, mine_visuals):
		return
	state["mine_anim_time"] = float(state.get("mine_anim_time", 0.0)) + delta * 2.0
	var time := float(state.get("mine_anim_time", 0.0))
	var wave_a := sin(time)
	var wave_b := sin(time * 1.73)
	var wave_c := sin(time * 2.41)
	sprite.rotation = float(state.get("base_sprite_rotation", 0.0)) + deg_to_rad(rotation_degrees * wave_a)
	sprite.scale = Vector2(state.get("base_sprite_scale", Vector2.ONE)) * (1.0 + scale_pulse * wave_b)
	sprite.position = Vector2(state.get("base_sprite_position", Vector2.ZERO)) + Vector2(shake_pixels * wave_c, 0.0)
