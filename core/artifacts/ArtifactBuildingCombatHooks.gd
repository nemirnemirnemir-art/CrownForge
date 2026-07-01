extends RefCounted
class_name ArtifactBuildingCombatHooks

func get_attacking_building_damage_multiplier() -> float:
	var artifact_core := _get_artifact_core()
	if artifact_core == null:
		return 1.0
	if artifact_core.has_method("get_attacking_building_damage_multiplier"):
		return maxf(0.0, float(artifact_core.call("get_attacking_building_damage_multiplier")))
	return ArtifactStatQueries.get_attacking_building_damage_multiplier(_get_active_artifacts(artifact_core))

func get_scaled_attacking_building_damage(base_damage: float) -> float:
	return maxf(0.0, base_damage) * get_attacking_building_damage_multiplier()

func _get_active_artifacts(artifact_core: Node) -> Dictionary:
	var active: Dictionary = {}
	if artifact_core.has_method("get_active_ids"):
		var active_ids: Variant = artifact_core.call("get_active_ids")
		if active_ids is Array:
			for artifact_id in active_ids:
				var normalized_id := str(artifact_id).strip_edges()
				if normalized_id != "":
					active[normalized_id] = true
			return active
	if artifact_core.has_method("is_active"):
		if bool(artifact_core.call("is_active", "frag_bomb")):
			active["frag_bomb"] = true
	return active

func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")
