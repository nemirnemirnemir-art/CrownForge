extends SceneTree

const FaceRigScene := preload("res://scenes/dev/FaceRigTest.tscn")

const USER_PROFILE_PATH := "user://head_profiles.json"
const RES_PROFILE_PATH := "res://assets/characters/character_faces/head_profiles.json"
const HAIR_PATH := "Skeleton2D/Root/Head/Hair"

const HAIR_VARIANT_POSITIONS := [
	Vector2(-42.0, -120.0),
	Vector2(8.0, -166.0),
	Vector2(67.0, -201.0),
	Vector2(-103.0, -152.0),
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var user_snapshot := _snapshot_file(USER_PROFILE_PATH)
	var res_snapshot := _snapshot_file(RES_PROFILE_PATH)

	if FileAccess.file_exists(USER_PROFILE_PATH):
		DirAccess.remove_absolute(USER_PROFILE_PATH)

	var stale_rig := FaceRigScene.instantiate()
	if stale_rig == null:
		_fail_and_quit("failed to instantiate stale rig", user_snapshot, res_snapshot)
		return
	stale_rig.auto_anim = false
	stale_rig.profile_auto_apply = false
	stale_rig.profile_edit_mode = false
	get_root().add_child(stale_rig)
	await process_frame
	await process_frame

	var writer_rig := FaceRigScene.instantiate()
	if writer_rig == null:
		_fail_and_quit("failed to instantiate writer rig", user_snapshot, res_snapshot)
		return
	writer_rig.auto_anim = false
	writer_rig.profile_auto_apply = false
	writer_rig.profile_edit_mode = false
	get_root().add_child(writer_rig)
	await process_frame
	await process_frame

	var writer_hair := writer_rig.get_node_or_null(HAIR_PATH) as Sprite2D
	if writer_hair == null:
		_fail_and_quit("writer hair node not found", user_snapshot, res_snapshot)
		return

	writer_rig._head_profiles = {}
	writer_rig._apply_head_index(0)
	for i in range(HAIR_VARIANT_POSITIONS.size()):
		writer_rig._apply_hair_index(i)
		writer_hair.position = HAIR_VARIANT_POSITIONS[i]
		writer_rig._save_head_profile(writer_rig.head_index)

	stale_rig._apply_head_index(0)
	stale_rig._apply_hair_index(0)
	stale_rig._save_head_profile(stale_rig.head_index)

	var hair_keys := _read_hair_variant_keys(USER_PROFILE_PATH, 0)
	if hair_keys != ["0", "1", "2", "3"]:
		_fail_and_quit(
			"stale save dropped variants, expected [0,1,2,3], got %s" % [hair_keys],
			user_snapshot,
			res_snapshot
		)
		return

	print("[test_face_rig_profile_stale_instance_does_not_drop_variants] PASS")
	_cleanup_and_quit(0, user_snapshot, res_snapshot)


func _read_hair_variant_keys(path: String, head_idx: int) -> Array[String]:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var root := parsed as Dictionary
	if not root.has("heads") or typeof(root["heads"]) != TYPE_DICTIONARY:
		return []
	var heads := root["heads"] as Dictionary
	var head_key := str(head_idx)
	if not heads.has(head_key):
		return []
	var head := heads[head_key] as Dictionary
	if not head.has("parts") or typeof(head["parts"]) != TYPE_DICTIONARY:
		return []
	var parts := head["parts"] as Dictionary
	if not parts.has("hair") or typeof(parts["hair"]) != TYPE_DICTIONARY:
		return []
	var hair := parts["hair"] as Dictionary
	var keys: Array[String] = []
	for k in hair.keys():
		keys.append(String(k))
	keys.sort_custom(func(a: String, b: String) -> bool:
		return int(a) < int(b)
	)
	return keys


func _snapshot_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"exists": false, "text": ""}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "text": ""}
	var text := file.get_as_text()
	file.close()
	return {"exists": true, "text": text}


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
	push_error("[test_face_rig_profile_stale_instance_does_not_drop_variants] %s" % reason)
	_cleanup_and_quit(1, user_snapshot, res_snapshot)
