extends RefCounted
class_name GameSceneStartupValidator

## Dev-only startup sanity checks for GameScene.
## Extracted from GameScene._dev_validate_startup().

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

static func validate(game_scene: Node) -> void:
	var required_groups: Array[String] = [
		"game_scene",
		"main_ui",
		"hero_bar",
		"hero_card",
		"wall",
	]
	for g in required_groups:
		if game_scene.get_tree().get_nodes_in_group(g).is_empty():
			push_warning("[GameScene] Missing required group '%s' (0 nodes)" % g)

	var required_marker_groups: Array[String] = [
		"portal_markers",
		"bridge_markers",
		"wall_markers",
	]
	for g in required_marker_groups:
		if game_scene.get_tree().get_nodes_in_group(g).is_empty():
			push_warning("[GameScene] Missing marker group '%s' (0 nodes)" % g)

	var required_unit_id := "peasant"
	var scene_path := HeroSceneRegistryScript.get_scene_path(required_unit_id)
	if scene_path == "":
		push_error("[GameScene] Critical hero entry scene missing for unit: %s" % required_unit_id)
		return

	var packed := HeroSceneRegistryScript.load_scene(required_unit_id)
	if packed == null:
		push_error("[GameScene] Failed to load critical hero scene: %s" % scene_path)
		return

	var inst := packed.instantiate()
	if inst == null:
		push_error("[GameScene] Failed to instantiate critical hero scene: %s" % scene_path)
		return

	inst.free()
