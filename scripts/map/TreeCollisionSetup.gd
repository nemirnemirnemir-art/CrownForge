extends Node2D

## Script to automatically add collision to all tree nodes for spell interaction
## Attaches to BiomeLayer or any parent node containing trees

const TREE_COLLISION_LAYER: int = 1  # Default physics layer
const TREE_COLLISION_RADIUS: float = 30.0  # Collision radius for trees

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame
	_setup_tree_collisions()

func _setup_tree_collisions() -> void:
	var trees_found: int = 0
	
	# Find all tree nodes recursively
	var all_trees := _find_all_trees(self)
	
	for tree in all_trees:
		if not is_instance_valid(tree):
			continue
		
		# Check if tree already has collision (avoid duplicates)
		if tree.has_node("TreeCollision"):
			continue
		
		# Add StaticBody2D for collision detection
		var collision_body := StaticBody2D.new()
		collision_body.name = "TreeCollision"
		collision_body.collision_layer = TREE_COLLISION_LAYER
		collision_body.collision_mask = 0  # Trees don't need to detect anything
		
		# Add collision shape
		var collision_shape := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = TREE_COLLISION_RADIUS
		collision_shape.shape = shape
		
		collision_body.add_child(collision_shape)
		tree.add_child(collision_body)
		
		trees_found += 1
	
	print("[TreeCollisionSetup] Added collision to %d trees" % trees_found)

func _find_all_trees(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	
	# Check if current node is a tree
	if node.name.begins_with("Tree_"):
		result.append(node)
	
	# Recursively check children
	for child in node.get_children():
		result.append_array(_find_all_trees(child))
	
	return result
