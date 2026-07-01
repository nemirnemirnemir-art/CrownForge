extends SceneTree

const HERO_SCENES_DIR := "res://scenes/heroes"

func _init() -> void:
	var scene_paths := _collect_scene_paths(HERO_SCENES_DIR)
	var flattened_count := 0
	var skipped_count := 0
	var failures: Array[String] = []

	for scene_path in scene_paths:
		var scene_text := _read_scene_text(scene_path)
		if scene_text == "":
			failures.append("%s: read_failed" % scene_path)
			continue

		if not ("instance=ExtResource(" in scene_text):
			skipped_count += 1
			continue

		var err := _flatten_scene(scene_path)
		if err != OK:
			failures.append("%s: %s" % [scene_path, error_string(err)])
			continue

		flattened_count += 1

	if not failures.is_empty():
		push_error("[flatten_inherited_hero_scenes] Failed to flatten %d scene(s)" % failures.size())
		for item in failures:
			print(" - %s" % item)
		quit(1)
		return

	print("[flatten_inherited_hero_scenes] PASS flattened=%d skipped=%d" % [flattened_count, skipped_count])
	quit(0)

func _flatten_scene(scene_path: String) -> Error:
	var source_scene := load(scene_path) as PackedScene
	if source_scene == null:
		return ERR_CANT_OPEN

	var instance := source_scene.instantiate()
	if instance == null:
		return ERR_CANT_CREATE

	_assign_owner_recursive(instance, instance)

	var flattened := PackedScene.new()
	var pack_err := flattened.pack(instance)
	if pack_err != OK:
		instance.free()
		return pack_err

	var save_err := ResourceSaver.save(flattened, scene_path)
	instance.free()
	return save_err

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		if child is Node:
			var child_node := child as Node
			child_node.owner = owner_root
			_assign_owner_recursive(child_node, owner_root)

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
