extends SpellEffect

## Bursting Bunch spell - spawns 1 bun that rolls and explodes

const BurstingGuyScene = preload("res://scenes/spells/effects/BurstingGuy.tscn")

const DEFAULT_DAMAGE: float = 250.0
const DEFAULT_LIFETIME: float = 5.0
const DEFAULT_EXPLOSION_RADIUS: float = 80.0
const DEFAULT_EXPLOSION_DELAY: float = 1.0

func execute_effect() -> void:
	var root: Node = get_tree().current_scene
	if get_parent() != null:
		root = get_parent()
	if root == null:
		queue_free()
		return

	var dmg := DEFAULT_DAMAGE
	if config != null and config.damage > 0.0:
		dmg = get_scaled_damage(config.damage)
	else:
		dmg = get_scaled_damage(DEFAULT_DAMAGE)

	var lifetime := DEFAULT_LIFETIME
	if config != null and config.duration > 0.0:
		lifetime = config.duration

	var explosion_radius := get_scaled_radius(DEFAULT_EXPLOSION_RADIUS)
	if config != null and config.target_radius > 0.0:
		explosion_radius = get_scaled_radius(config.target_radius)

	var dir := _get_spawn_direction()

	var bun: Node2D = BurstingGuyScene.instantiate()
	root.add_child(bun)
	bun.global_position = target_position
	if bun.has_method("setup"):
		bun.call("setup", dir, dmg, explosion_radius, DEFAULT_EXPLOSION_DELAY, lifetime)

	queue_free()

func _get_spawn_direction() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.RIGHT

	var candidates: Array = tree.get_nodes_in_group("enemy")
	candidates.append_array(tree.get_nodes_in_group("mobs"))
	candidates.append_array(tree.get_nodes_in_group("enemies"))

	var closest: Node2D = null
	var closest_dist_sq := INF
	for node in candidates:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if not is_instance_valid(enemy):
			continue
		if "is_dead" in enemy and bool(enemy.is_dead):
			continue
		var d2 := target_position.distance_squared_to(enemy.global_position)
		if d2 < closest_dist_sq:
			closest_dist_sq = d2
			closest = enemy

	if closest == null:
		return Vector2.RIGHT

	var dir := (closest.global_position - target_position).normalized()
	return dir if dir != Vector2.ZERO else Vector2.RIGHT
