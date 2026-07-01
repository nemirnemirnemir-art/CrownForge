extends SceneTree

const HERO_SCENES_DIR := "res://scenes/heroes"

func _init() -> void:
	var offenders: Array[String] = []
	var scene_paths := _collect_scene_paths(HERO_SCENES_DIR)

	for scene_path in scene_paths:
		var scene_text := _read_scene_text(scene_path)
		if scene_text == "":
			offenders.append("%s (read_failed)" % scene_path)
			continue

		if "instance=ExtResource(" in scene_text:
			offenders.append(scene_path)

	if not offenders.is_empty():
		push_error("[test_all_hero_scenes_not_inherited] Found %d inherited hero scene(s)" % offenders.size())
		for item in offenders:
			print(" - %s" % item)
		quit(1)
		return

	print("[test_all_hero_scenes_not_inherited] PASS")
	quit(0)

func _collect_scene_paths(root_dir: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(root_dir)
	if dir == null:
		return result

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tscn"):
			continue
		result.append("%s/%s" % [root_dir, file_name])
	dir.list_dir_end()

	result.sort()
	return result

func _read_scene_text(scene_path: String) -> String:
	var fs_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(fs_path):
		return ""

	var file := FileAccess.open(fs_path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()
