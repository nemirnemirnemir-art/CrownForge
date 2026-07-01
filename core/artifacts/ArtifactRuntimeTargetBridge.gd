extends RefCounted
class_name ArtifactRuntimeTargetBridge

func get_troop_bonus_core(tree: SceneTree) -> Node:
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TroopBonusCore")

func get_game_scene(tree: SceneTree) -> Node:
	if tree == null:
		return null
	if tree.current_scene and tree.current_scene.is_in_group("game_scene"):
		return tree.current_scene
	var scenes := tree.get_nodes_in_group("game_scene")
	if scenes.is_empty():
		return null
	return scenes[0]

func enqueue_pending_rewards(rewards: Variant, game_scene: Node) -> void:
	if not (rewards is Array):
		return
	if game_scene == null or not game_scene.has_method("enqueue_pending_reward"):
		return
	for reward_value in (rewards as Array):
		if reward_value is Dictionary:
			game_scene.enqueue_pending_reward(reward_value)


func get_map_layout(tree: SceneTree) -> Node:
	var game_scene := get_game_scene(tree)
	if game_scene == null:
		return null
	var raw_map_layout: Node = game_scene.get("map_layout_node")
	if raw_map_layout != null:
		return raw_map_layout
	return game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")


func get_slot_by_index(tree: SceneTree, slot_index: int, building_id: String = "") -> Node2D:
	if slot_index < 0:
		return null
	var map_layout := get_map_layout(tree)
	if map_layout == null:
		return null
	var raw_slots: Variant = map_layout.get("slots")
	if not (raw_slots is Array):
		return null
	var normalized_building_id := String(building_id).strip_edges().to_lower()
	for slot_value in raw_slots:
		var slot := slot_value as Node2D
		if slot == null:
			continue
		var raw_slot_index: Variant = slot.get("slot_index")
		if raw_slot_index == null or int(raw_slot_index) != slot_index:
			continue
		if normalized_building_id != "":
			var current_building_id := String(slot.get("current_building_id")).strip_edges().to_lower()
			if current_building_id != normalized_building_id:
				continue
		return slot
	return null


func collect_alive_enemies(tree: SceneTree) -> Array[Node2D]:
	if tree == null:
		return []
	var nodes: Array = []
	nodes.append_array(tree.get_nodes_in_group("enemy"))
	nodes.append_array(tree.get_nodes_in_group("mobs"))
	var out: Array[Node2D] = []
	var seen: Dictionary = {}
	for node in nodes:
		if node == null or not is_instance_valid(node):
			continue
		if seen.has(node):
			continue
		seen[node] = true
		if not (node is Node2D):
			continue
		var n2 := node as Node2D
		if "is_dead" in n2 and bool(n2.is_dead):
			continue
		out.append(n2)
	return out
