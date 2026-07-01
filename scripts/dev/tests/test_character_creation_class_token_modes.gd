extends SceneTree

const CharacterCreationScene := preload("res://scenes/dev/CharacterCreationScratchEditable.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var scene := CharacterCreationScene.instantiate()
	if scene == null:
		push_error("[test_character_creation_class_token_modes] failed to instantiate scene")
		quit(1)
		return
	get_root().add_child(scene)
	await process_frame

	if scene.get_node_or_null("ClassPanel/TokenRig") == null:
		push_error("[test_character_creation_class_token_modes] TokenRig not found")
		quit(1)
		return
	if scene.get_node_or_null("ClassPanel/TokenRig/RopeAnchor") == null:
		push_error("[test_character_creation_class_token_modes] RopeAnchor not found")
		quit(1)
		return
	if scene.get_node_or_null("ClassPanel/TokenRig/TokenRoot/TokenSprite") == null:
		push_error("[test_character_creation_class_token_modes] TokenSprite not found")
		quit(1)
		return
	if scene.get_node_or_null("ClassPanel/TokenRig/RopeLine") == null:
		push_error("[test_character_creation_class_token_modes] RopeLine not found")
		quit(1)
		return
	if scene.get_node_or_null("AgePanel/AgeFocusCaret") == null:
		push_error("[test_character_creation_class_token_modes] AgeFocusCaret not found")
		quit(1)
		return
	if scene.get_node_or_null("NamePanel/NameFocusCaret") == null:
		push_error("[test_character_creation_class_token_modes] NameFocusCaret not found")
		quit(1)
		return

	var has_mode_property := false
	for property_data in scene.get_property_list():
		if String(property_data.get("name", "")) == "class_token_physics_mode":
			has_mode_property = true
			break
	if not has_mode_property:
		push_error("[test_character_creation_class_token_modes] class_token_physics_mode property not found on root")
		quit(1)
		return

	var token_sprite := scene.get_node("ClassPanel/TokenRig/TokenRoot/TokenSprite") as Sprite2D
	if token_sprite == null:
		push_error("[test_character_creation_class_token_modes] TokenSprite cast failed")
		quit(1)
		return
	if token_sprite.scale.distance_to(Vector2(0.666667, 0.666667)) > 0.01:
		push_error("[test_character_creation_class_token_modes] expected token sprite scale 0.666667x, got %s" % [token_sprite.scale])
		quit(1)
		return

	print("[test_character_creation_class_token_modes] PASS")
	quit(0)
