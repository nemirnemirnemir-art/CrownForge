extends RefCounted
class_name ProjectileSpawnHelper


static func spawn(projectile_scene: PackedScene, owner: Node2D, target: Node2D, damage: float, projectile_speed: float, spin_deg: float = 0.0, start_offset: Vector2 = Vector2(0.0, -20.0), projectile_type: String = "default") -> Node2D:
	if projectile_scene == null or owner == null or target == null:
		return null
	return spawn_at(projectile_scene, owner.get_parent(), owner.global_position + start_offset, target, damage, projectile_speed, spin_deg, owner, projectile_type)


static func spawn_at(projectile_scene: PackedScene, parent: Node, start_pos: Vector2, target: Node2D, damage: float, projectile_speed: float, spin_deg: float = 0.0, owner: Node = null, projectile_type: String = "default") -> Node2D:
	if projectile_scene == null or parent == null or target == null:
		return null
	var is_ballista_debug := projectile_type == "cannonball"
	if not is_ballista_debug and owner != null and is_instance_valid(owner) and "hero_id" in owner:
		is_ballista_debug = String(owner.hero_id).begins_with("ballista")
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		if is_ballista_debug:
			print("[BALLISTA PROJECTILE][spawn_failed] scene=%s owner=%s" % [projectile_scene.resource_path, String(owner.hero_id) if owner and "hero_id" in owner else "null"])
		return null
	parent.add_child(projectile)
	projectile.global_position = start_pos
	var direction := (target.global_position - start_pos).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if is_ballista_debug:
		print("[BALLISTA PROJECTILE][spawn] scene=%s owner=%s start=%s target=%s dir=%s type=%s parent=%s" % [
			projectile_scene.resource_path,
			String(owner.hero_id) if owner and "hero_id" in owner else (String(owner.name) if owner else "null"),
			str(start_pos),
			str(target.global_position),
			str(direction),
			projectile_type,
			String(parent.name)
		])
	if projectile.has_method("setup"):
		projectile.call("setup", direction, damage, target, owner)
	if projectile.has_method("set_projectile_profile"):
		projectile.call("set_projectile_profile", projectile_type, projectile_speed, spin_deg)
	if "spin_speed_deg" in projectile:
		projectile.spin_speed_deg = spin_deg
	if "speed" in projectile:
		projectile.speed = projectile_speed
	return projectile
