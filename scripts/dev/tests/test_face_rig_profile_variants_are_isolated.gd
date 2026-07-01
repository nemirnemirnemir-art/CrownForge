extends SceneTree

const FaceRigScene := preload("res://scenes/dev/FaceRigTest.tscn")

const USER_PROFILE_PATH := "user://head_profiles.json"
const TEST_PROFILE_PATH := "user://head_profiles_variant_scope_test.json"

const HAIR_VARIANT_A_POS := Vector2(41.0, -133.0)
const HAIR_VARIANT_B_POS := Vector2(-96.0, -207.0)
const EPS := 0.01


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var user_profile_snapshot := _snapshot_file(USER_PROFILE_PATH)
	var test_profile_snapshot := _snapshot_file(TEST_PROFILE_PATH)

	var rig := FaceRigScene.instantiate()
	if rig == null:
		push_error("[test_face_rig_profile_variants_are_isolated] failed to instantiate FaceRigTest")
		_cleanup_and_quit(1, user_profile_snapshot, test_profile_snapshot)
		return

	rig.auto_anim = false
	rig.profile_auto_apply = false
	rig.profile_edit_mode = false
	rig.head_profiles_path = TEST_PROFILE_PATH

	get_root().add_child(rig)
	await process_frame
	await process_frame

	var hair := rig.get_node_or_null("Skeleton2D/Root/Head/Hair") as Sprite2D
	if hair == null:
		push_error("[test_face_rig_profile_variants_are_isolated] Hair sprite not found")
		_cleanup_and_quit(1, user_profile_snapshot, test_profile_snapshot)
		return

	rig._head_profiles = {}
	rig._apply_head_index(0)

	rig._apply_hair_index(0)
	hair.position = HAIR_VARIANT_A_POS
	rig._save_head_profile(rig.head_index)

	rig._apply_hair_index(1)
	hair.position = HAIR_VARIANT_B_POS
	rig._save_head_profile(rig.head_index)

	rig._apply_hair_index(0)
	rig._apply_head_profile(rig.head_index)
	if hair.position.distance_to(HAIR_VARIANT_A_POS) > EPS:
		push_error("[test_face_rig_profile_variants_are_isolated] hair variant 0 position mismatch after apply: expected %s, got %s" % [HAIR_VARIANT_A_POS, hair.position])
		_cleanup_and_quit(1, user_profile_snapshot, test_profile_snapshot)
		return

	rig._apply_hair_index(1)
	rig._apply_head_profile(rig.head_index)
	if hair.position.distance_to(HAIR_VARIANT_B_POS) > EPS:
		push_error("[test_face_rig_profile_variants_are_isolated] hair variant 1 position mismatch after apply: expected %s, got %s" % [HAIR_VARIANT_B_POS, hair.position])
		_cleanup_and_quit(1, user_profile_snapshot, test_profile_snapshot)
		return

	print("[test_face_rig_profile_variants_are_isolated] PASS")
	_cleanup_and_quit(0, user_profile_snapshot, test_profile_snapshot)


func _snapshot_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"exists": false,
			"text": "",
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"exists": false,
			"text": "",
		}
	var text := file.get_as_text()
	file.close()
	return {
		"exists": true,
		"text": text,
	}


func _restore_file(path: String, snapshot: Dictionary) -> void:
	if bool(snapshot.get("exists", false)):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(String(snapshot.get("text", "")))
			file.close()
		return
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _cleanup_and_quit(code: int, user_snapshot: Dictionary, test_snapshot: Dictionary) -> void:
	_restore_file(USER_PROFILE_PATH, user_snapshot)
	_restore_file(TEST_PROFILE_PATH, test_snapshot)
	quit(code)
