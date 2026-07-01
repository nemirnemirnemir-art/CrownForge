extends SceneTree

const FaceRigScene := preload("res://scenes/dev/FaceRigTest.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var rig := FaceRigScene.instantiate()
	if rig == null:
		push_error("[test_face_rig_hat_blocks_hair_variants] failed to instantiate FaceRigTest")
		quit(1)
		return

	rig.auto_anim = false
	rig.profile_auto_apply = false
	rig.profile_edit_mode = false
	rig.hat_blocked_hair_variants = {
		"0": [1, 2],
	}

	get_root().add_child(rig)
	await process_frame
	await process_frame

	if rig.hair_textures.size() < 4:
		push_error("[test_face_rig_hat_blocks_hair_variants] test requires at least 4 hair variants")
		quit(1)
		return

	rig._on_hat_toggle_toggled(true)
	rig._apply_hat_index(0)

	rig._apply_hair_index(1)
	if rig.hair_index != 3:
		push_error("[test_face_rig_hat_blocks_hair_variants] expected blocked hair #2 to redirect to #4, got #%d" % [rig.hair_index + 1])
		quit(1)
		return

	rig._apply_hair_index(2)
	if rig.hair_index != 3:
		push_error("[test_face_rig_hat_blocks_hair_variants] expected blocked hair #3 to redirect to #4, got #%d" % [rig.hair_index + 1])
		quit(1)
		return

	rig._on_hat_toggle_toggled(false)
	rig._apply_hair_index(2)
	if rig.hair_index != 2:
		push_error("[test_face_rig_hat_blocks_hair_variants] expected hair #3 to be selectable when hat is hidden, got #%d" % [rig.hair_index + 1])
		quit(1)
		return

	print("[test_face_rig_hat_blocks_hair_variants] PASS")
	quit(0)
