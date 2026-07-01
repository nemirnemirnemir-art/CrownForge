extends SceneTree

const MADMAN_SCENE_PATH := "res://scenes/heroes/madman.tscn"
const BLACK_SHEEP_SCENE_PATH := "res://scenes/heroes/black_sheep.tscn"

var _has_failed := false

func _init() -> void:
	_validate_scene_text(
		MADMAN_SCENE_PATH,
		[
			"res://assets/characters/tinyHeroes/Madman/run/1.png",
			"res://assets/characters/tinyHeroes/Madman/attack/1.png",
			"[node name=\"AnimWalk\"",
			"[node name=\"AnimAttack\"",
		]
	)

	_validate_scene_text(
		BLACK_SHEEP_SCENE_PATH,
		[
			"res://assets/characters/tinyHeroes/Black_Sheep/run/1.png",
			"[node name=\"AnimWalk\"",
			"[node name=\"AnimAttack\"",
		]
	)

	if _has_failed:
		quit(1)
		return

	print("[test_madman_black_sheep_scene_animation_override] PASS")
	quit(0)

func _validate_scene_text(scene_path: String, required_markers: Array[String]) -> void:
	var fs_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(fs_path):
		_fail("scene file missing: %s" % scene_path)
		return

	var file := FileAccess.open(fs_path, FileAccess.READ)
	if file == null:
		_fail("failed to read scene file: %s" % scene_path)
		return

	var text := file.get_as_text()
	if "instance=ExtResource(" in text:
		_fail("scene still has inherited nodes: %s" % scene_path)
		return

	for marker in required_markers:
		if not (marker in text):
			_fail("scene missing marker '%s': %s" % [marker, scene_path])
			return

func _fail(message: String) -> void:
	_has_failed = true
	push_error("[test_madman_black_sheep_scene_animation_override] %s" % message)
