extends SceneTree

const FaceRigScene := preload("res://scenes/dev/FaceRigTest.tscn")

const USER_PROFILE_PATH := "user://head_profiles.json"
const RES_PROFILE_PATH := "res://assets/characters/character_faces/head_profiles.json"

const HAIR_VARIANT_POSITIONS := [
	Vector2(-45.0, -118.0),
	Vector2(13.0, -176.0),
	Vector2(74.0, -209.0),
	Vector2(-99.0, -154.0),
]

const EPS := 0.01


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var user_snapshot := _snapshot_file(USER_PROFILE_PATH)
	var res_snapshot := _snapshot_file(RES_PROFILE_PATH)

	if FileAccess.file_exists(USER_PROFILE_PATH):
		DirAccess.remove_absolute(USER_PROFILE_PATH)

	var rig1 := FaceRigScene.instantiate()
	if rig1 == null:
		_fail_and_quit("failed to instantiate FaceRigTest for save phase", user_snapshot, res_snapshot)
		return

	rig1.auto_anim = false
	rig1.profile_auto_apply = false
	rig1.profile_edit_mode = false

	get_root().add_child(rig1)
	await process_frame
	await process_frame

	var hair1 := rig1.get_node_or_null("Skeleton2D/Root/Head/Hair") as Sprite2D
	if hair1 == null:
		_fail_and_quit("Hair sprite not found during save phase", user_snapshot, res_snapshot)
		return

	if rig1.hair_textures.size() < HAIR_VARIANT_POSITIONS.size():
		_fail_and_quit("not enough hair variants in scene to run test", user_snapshot, res_snapshot)
		return

	rig1._head_profiles = {}
	rig1._apply_head_index(0)

	for i in range(HAIR_VARIANT_POSITIONS.size()):
		rig1._apply_hair_index(i)
		hair1.position = HAIR_VARIANT_POSITIONS[i]
		rig1._on_profile_save_pressed()
		rig1._on_profile_apply_pressed()

	rig1.queue_free()
	await process_frame
	await process_frame

	var rig2 := FaceRigScene.instantiate()
	if rig2 == null:
		_fail_and_quit("failed to instantiate FaceRigTest for reload phase", user_snapshot, res_snapshot)
		return

	rig2.auto_anim = false
	rig2.profile_auto_apply = false
	rig2.profile_edit_mode = false

	get_root().add_child(rig2)
	await process_frame
	await process_frame

	var hair2 := rig2.get_node_or_null("Skeleton2D/Root/Head/Hair") as Sprite2D
	if hair2 == null:
		_fail_and_quit("Hair sprite not found during reload phase", user_snapshot, res_snapshot)
		return

	rig2._apply_head_index(0)

	for i in range(HAIR_VARIANT_POSITIONS.size()):
		rig2._apply_hair_index(i)
		rig2._on_profile_apply_pressed()
		var expected: Vector2 = HAIR_VARIANT_POSITIONS[i]
		if hair2.position.distance_to(expected) > EPS:
			var saved_json := _read_file_text(USER_PROFILE_PATH)
			_fail_and_quit(
				"hair variant %d mismatch after reload: expected %s, got %s; saved user profile: %s" % [
					i,
					expected,
					hair2.position,
					saved_json,
				],
				user_snapshot,
				res_snapshot
			)
			return

	print("[test_face_rig_profile_variants_survive_reload] PASS")
	_cleanup_and_quit(0, user_snapshot, res_snapshot)


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


func _read_file_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<missing>"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "<open-failed>"
	var text := file.get_as_text()
	file.close()
	return text


func _restore_file(path: String, snapshot: Dictionary) -> void:
	if bool(snapshot.get("exists", false)):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(String(snapshot.get("text", "")))
			file.close()
		return
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _cleanup_and_quit(code: int, user_snapshot: Dictionary, res_snapshot: Dictionary) -> void:
	_restore_file(USER_PROFILE_PATH, user_snapshot)
	_restore_file(RES_PROFILE_PATH, res_snapshot)
	quit(code)


func _fail_and_quit(reason: String, user_snapshot: Dictionary, res_snapshot: Dictionary) -> void:
	push_error("[test_face_rig_profile_variants_survive_reload] %s" % reason)
	_cleanup_and_quit(1, user_snapshot, res_snapshot)
