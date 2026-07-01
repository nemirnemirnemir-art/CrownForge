extends RefCounted
class_name HeroEvasionService
## Handles evasion reaction logic: rolls evasion chance, finds hero node,
## spawns FloatingText, and applies temporary damage bonus on evade.


func try_apply_evasion_reaction(hero_id: String, _amount: float, update_hero_fn: Callable) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("get_friendly_evasion_chance"):
		return false
	var evade_chance: float = float(artifact_core.call("get_friendly_evasion_chance"))
	if evade_chance <= 0.0 or randf() >= clamp(evade_chance, 0.0, 1.0):
		return false
	var hero_node: Node2D = null
	var hero_nodes: Array = tree.get_nodes_in_group("hero")
	for n in hero_nodes:
		if n == null or not is_instance_valid(n):
			continue
		if not (n is Node2D):
			continue
		if "hero_id" in n and str(n.hero_id).to_lower() == hero_id.to_lower():
			hero_node = n as Node2D
			break
	if hero_node != null and FloatingText and hero_node.get_parent():
		FloatingText.spawn_evade(hero_node.get_parent(), hero_node.global_position + Vector2(0, -30))
	var until_ms := Time.get_ticks_msec() + 3000
	update_hero_fn.call(hero_id, {"temp_damage_bonus_percent": 0.5, "temp_damage_bonus_until_ms": until_ms})
	return true
