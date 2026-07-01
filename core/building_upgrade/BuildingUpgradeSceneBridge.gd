extends RefCounted
class_name BuildingUpgradeSceneBridge


func get_map_slots() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	var game_scene := tree.current_scene
	if game_scene != null:
		var current_slots := _extract_slots(game_scene)
		if not current_slots.is_empty():
			return current_slots
	game_scene = tree.get_first_node_in_group("game_scene")
	if game_scene == null:
		return []
	return _extract_slots(game_scene)


func _extract_slots(game_scene: Node) -> Array:
	var map_layout: Node = game_scene.get("map_layout_node")
	if map_layout == null:
		map_layout = game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
	if map_layout == null:
		return []
	var slots: Variant = map_layout.get("slots")
	if slots is Array:
		return slots
	return []
