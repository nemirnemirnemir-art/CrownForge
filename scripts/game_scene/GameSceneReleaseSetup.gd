extends RefCounted
class_name GameSceneReleaseSetup

## Release-mode starting recipe setup for BuildingRegistry.
## Extracted from GameScene._apply_release_starting_recipes().

static func apply_starting_recipes() -> void:
	var building_registry: Node = _get_building_registry()
	if building_registry == null:
		return
	if not building_registry.has_method("clear_recipes"):
		return
	building_registry.call("clear_recipes")
	if not building_registry.has_method("add_recipe"):
		return
	building_registry.call("add_recipe", "well", 3)
	building_registry.call("add_recipe", "small_wheat_field", 3)
	building_registry.call("add_recipe", "tree", 3)
	building_registry.call("add_recipe", "market", 1)
	building_registry.call("add_recipe", "small_peasants_hut", 2)
	building_registry.call("add_recipe", "research_table", 1)
	building_registry.call("add_recipe", "magic_school", 1)

static func _get_building_registry() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("BuildingRegistry")
