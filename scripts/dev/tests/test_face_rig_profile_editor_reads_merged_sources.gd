extends SceneTree

const FaceRigScene := preload("res://scenes/dev/FaceRigTest.tscn")

const USER_PROFILE_PATH := "user://head_profiles.json"
const RES_PROFILE_PATH := "res://assets/characters/character_faces/head_profiles.json"
const HAIR_PATH := "Skeleton2D/Root/Head/Hair"

const HAIR_VARIANT_POSITIONS := [
	Vector2(-14.0, -133.0),
	Vector2(33.0, -177.0),
	Vector2(79.0, -205.0),
	Vector2(-101.0, -151.0),
]

const EPS := 0.01


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	if not Engine.is_editor_hint():
		push_error("[test_face_rig_profile_editor_reads_merged_sources] this test must run with --editor")
		quit(1)
		return

	var user_snapshot := _snapshot_file(USER_PROFILE_PATH)
	var res_snapshot := _snapshot_file(RES_PROFILE_PATH)

	var full_heads := _make_hair_heads({
		"0": HAIR_VARIANT_POSITIONS[0],
		"1": HAIR_VARIANT_POSITIONS[1],
		"2": HAIR_VARIANT_POSITIONS[2],
		"3": HAIR_VARIANT_POSITIONS[3],
	})
	var partial_heads := _make_hair_heads({
		"3": HAIR_VARIANT_POSITIONS[3],
	})

	if not _write_profile_file(RES_PROFILE_PATH, partial_heads):
		_fail_and_quit("failed to write partial profile to res path", user_snapshot, res_snapshot)
		return
	if not _write_profile_file(USER_PROFILE_PATH, full_heads):
		_fail_and_quit("failed to write full profile to user path", user_snapshot, res_snapshot)
		return

	var rig := FaceRigScene.instantiate()
	if rig == null:
		_fail_and_quit("failed to instantiate FaceRigTest", user_snapshot, res_snapshot)
		return

	rig.auto_anim = false
	rig.profile_auto_apply = false
	rig.profile_edit_mode = false

	get_root().add_child(rig)
	await process_frame
	await process_frame

	var hair := rig.get_node_or_null(HAIR_PATH) as Sprite2D
	if hair == null:
		_fail_and_quit("Hair sprite not found", user_snapshot, res_snapshot)
		return

	rig._apply_head_index(0)

	for i in range(HAIR_VARIANT_POSITIONS.size()):
		rig._apply_hair_index(i)
		rig._on_profile_apply_pressed()
		var expected: Vector2 = HAIR_VARIANT_POSITIONS[i]
		if hair.position.distance_to(expected) > EPS:
			var loaded_from: String = rig.head_profiles_path
			_fail_and_quit(
				"variant %d not restored in editor load order: expected %s, got %s, loaded_from=%s" % [
					i,
					expected,
					hair.position,
					loaded_from,
				],
				user_snapshot,
				res_snapshot
			)
			return

	print("[test_face_rig_profile_editor_reads_merged_sources] PASS")
	_cleanup_and_quit(0, user_snapshot, res_snapshot)


func _make_hair_heads(variants: Dictionary) -> Dictionary:
	var hair_variants: Dictionary = {}
	for variant_key_v in variants.keys():
		var variant_key := String(variant_key_v)
		var pos: Vector2 = variants[variant_key_v]
		hair_variants[variant_key] = {
			HAIR_PATH: {
				"pos": [pos.x, pos.y],
				"rot": 0.0,
				"scale": [1.0, 1.0],
			},
		}

	return {
		"0": {
			"parts": {
				"hair": hair_variants,
			},
		},
	}


func _write_profile_file(path: String, heads: Dictionary) -> bool:
	var payload := {
		"version": 2,
		"heads": heads,
	}
	var text := JSON.stringify(payload, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


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


func _cleanup_and_quit(code: int, user_snapshot: Dictionary, res_snapshot: Dictionary) -> void:
	_restore_file(USER_PROFILE_PATH, user_snapshot)
	_restore_file(RES_PROFILE_PATH, res_snapshot)
	quit(code)


func _fail_and_quit(reason: String, user_snapshot: Dictionary, res_snapshot: Dictionary) -> void:
	push_error("[test_face_rig_profile_editor_reads_merged_sources] %s" % reason)
	_cleanup_and_quit(1, user_snapshot, res_snapshot)
