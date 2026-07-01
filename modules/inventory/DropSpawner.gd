extends RefCounted
class_name DropSpawner

const DROP_ITEM_SCENE = preload("res://scenes/items/DropItem.tscn")

func spawn_drop(item_data: Dictionary, position: Vector2, scene_tree: SceneTree) -> void:
	if item_data.is_empty() or DROP_ITEM_SCENE == null:
		return
	var drop := DROP_ITEM_SCENE.instantiate()
	var world := scene_tree.current_scene.get_node_or_null("WorldYSort/MapContainer")
	if not world:
		world = scene_tree.current_scene
	world.add_child(drop)
	drop.global_position = position
	drop.setup(item_data)

