extends SceneTree

const MapSlotVzorVisualFlowScript := preload("res://scripts/map_slot/MapSlotVzorVisualFlow.gd")


class FakeSpecialHandler:
	extends RefCounted

	var vzor_values: Array[bool] = []

	func set_vzor_active(value: bool) -> void:
		vzor_values.append(value)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MapSlotVzorVisualFlowScript.new()
	if flow == null:
		push_error("[test_mapslot_vzor_visual_flow] failed to instantiate helper")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var sprite := Sprite2D.new()
	sprite.visible = true
	root.add_child(sprite)
	var frames := SpriteFrames.new()
	frames.add_frame("default", AtlasTexture.new())
	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = frames
	anim.animation = "default"
	anim.visible = true
	root.add_child(anim)

	var handler := FakeSpecialHandler.new()
	var state := {
		"current_building_id": "clay_gold_mine",
		"vzor_active": false,
		"king_vzor_active": true,
		"external_vzor_sources": {},
		"vzor_anim_frame": 0,
		"mine_anim_time": 0.0,
		"base_sprite_position": Vector2.ZERO,
		"base_sprite_rotation": 0.0,
		"base_sprite_scale": Vector2.ONE,
	}
	var mine_visuals := {
		"clay_gold_mine": {"inactive": "", "active": ""}
	}

	flow.refresh_vzor_state(
		state,
		sprite,
		anim,
		handler,
		mine_visuals,
		func() -> void: flow.apply_mine_visual_state(state, sprite, mine_visuals),
		func() -> void: flow.reset_active_mine_transform(state, sprite)
	)
	if not bool(state["vzor_active"]):
		push_error("[test_mapslot_vzor_visual_flow] king gaze must activate vzor state")
		quit(1)
		return
	if handler.vzor_values.is_empty() or not handler.vzor_values[-1]:
		push_error("[test_mapslot_vzor_visual_flow] special handler must receive vzor state")
		quit(1)
		return

	state["vzor_active"] = true
	state["king_vzor_active"] = false
	state["external_vzor_sources"] = {}
	flow.refresh_vzor_state(
		state,
		sprite,
		anim,
		handler,
		mine_visuals,
		func() -> void: flow.apply_mine_visual_state(state, sprite, mine_visuals),
		func() -> void: flow.reset_active_mine_transform(state, sprite)
	)
	if bool(state["vzor_active"]):
		push_error("[test_mapslot_vzor_visual_flow] vzor state must turn off when no sources remain")
		quit(1)
		return

	state["vzor_active"] = true
	anim.visible = false
	state["mine_anim_time"] = 0.0
	flow.update_active_mine_animation(state, sprite, anim, mine_visuals, 0.2, 3.0, 0.05, 2.0)
	if sprite.position == Vector2.ZERO and is_zero_approx(sprite.rotation) and sprite.scale == Vector2.ONE:
		push_error("[test_mapslot_vzor_visual_flow] active mine animation must move sprite transform")
		quit(1)
		return

	print("[test_mapslot_vzor_visual_flow] PASS")
	quit(0)
