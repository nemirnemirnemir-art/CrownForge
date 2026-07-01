class_name CombatTargetFinder
extends RefCounted

## Unified target acquisition for heroes and mobs
## Usage: CombatTargetFinder.find_nearest(seeker, "enemy", 300.0)

static func find_nearest(seeker: Node2D, group: String, max_range: float = 1000.0) -> Node2D:
	if not seeker or not is_instance_valid(seeker):
		return null
	
	var nearest: Node2D = null
	var nearest_dist := max_range
	var seen: Dictionary = {}
	for candidate_group in _resolve_group_candidates(group):
		for node in seeker.get_tree().get_nodes_in_group(candidate_group):
			if not is_instance_valid(node):
				continue
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			
			# Skip dead units
			if "is_dead" in node and bool(node.is_dead):
				continue
			
			# Skip invincible units
			if "is_invincible" in node and bool(node.is_invincible):
				continue
			
			var dist := seeker.global_position.distance_to(node.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = node
	
	return nearest

static func find_all_in_range(seeker: Node2D, group: String, max_range: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not seeker or not is_instance_valid(seeker):
		return result
	
	var seen: Dictionary = {}
	for candidate_group in _resolve_group_candidates(group):
		for node in seeker.get_tree().get_nodes_in_group(candidate_group):
			if not is_instance_valid(node):
				continue
			var id := node.get_instance_id()
			if seen.has(id):
				continue
			seen[id] = true
			if "is_dead" in node and bool(node.is_dead):
				continue
			if "is_invincible" in node and bool(node.is_invincible):
				continue
			var dist := seeker.global_position.distance_to(node.global_position)
			if dist <= max_range:
				result.append(node)
	
	return result

static func has_enemies_nearby(seeker: Node2D, group: String, max_range: float) -> bool:
	return find_nearest(seeker, group, max_range) != null

static func _resolve_group_candidates(group: String) -> Array[String]:
	var normalized := group.strip_edges().to_lower()
	if normalized == "enemy":
		return ["enemy", "mobs", "enemies"]
	if normalized == "hero":
		return ["hero", "heroes"]
	if normalized == "mobs":
		return ["mobs", "enemy", "enemies"]
	if normalized == "enemies":
		return ["enemies", "enemy", "mobs"]
	if normalized == "heroes":
		return ["heroes", "hero"]
	return [group]
