extends RefCounted
class_name SpellEnemyTracker


func resolve_enemy_from_collider(collider: Variant, alive_only: bool = true) -> Node2D:
	if collider == null:
		return null

	var enemy: Node2D = null
	if collider is Node2D:
		enemy = collider as Node2D
		if not _is_enemy(enemy):
			var parent := enemy.get_parent()
			if parent is Node2D and _is_enemy(parent as Node2D):
				enemy = parent as Node2D
			else:
				enemy = null

	if enemy == null:
		return null
	if not is_instance_valid(enemy):
		return null
	if alive_only and _is_dead(enemy):
		return null
	return enemy


func collect_tree_enemies_in_radius(tree_root: Node, center: Vector2, radius: float, include_enemy_group: bool = false) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if tree_root == null or tree_root.get_tree() == null:
		return result

	var seen: Dictionary = {}
	var radius_sq := radius * radius
	var groups: Array[String] = ["mobs", "enemies"]
	if include_enemy_group:
		groups.append("enemy")
	for group_name in groups:
		for node in tree_root.get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D):
				continue
			var enemy := node as Node2D
			if not is_instance_valid(enemy):
				continue
			var id := enemy.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			if _is_dead(enemy):
				continue
			if enemy.global_position.distance_squared_to(center) > radius_sq:
				continue
			result.append(enemy)
	return result


func find_nearest_enemy(tree_root: Node, center: Vector2, max_radius: float, include_enemy_group: bool = true) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	for enemy in collect_tree_enemies_in_radius(tree_root, center, max_radius, include_enemy_group):
		var dist := enemy.global_position.distance_to(center)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest


func find_nearest_enemy_in_groups(tree_root: Node, center: Vector2, max_radius: float, group_names: Array, min_radius: float = 0.0) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	if tree_root == null or tree_root.get_tree() == null:
		return null
	for group_name in group_names:
		for node in tree_root.get_tree().get_nodes_in_group(group_name):
			if not (node is Node2D):
				continue
			var enemy := node as Node2D
			if not is_instance_valid(enemy):
				continue
			if _is_dead(enemy):
				continue
			var dist := enemy.global_position.distance_to(center)
			if dist <= min_radius:
				continue
			if dist > max_radius:
				continue
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	return nearest


func _is_enemy(node: Node2D) -> bool:
	return node.is_in_group("enemy") or node.is_in_group("mobs") or node.is_in_group("enemies")


func _is_dead(node: Node2D) -> bool:
	return "is_dead" in node and bool(node.get("is_dead"))
