extends Area2D
class_name BaseProjectile

@export var speed: float = 400.0
@export var damage: float = 10.0
@export var lifetime: float = 10.0
@export var projectile_type: String = "default"
@export var spin_speed_deg: float = 0.0
@export var damage_multiplier: float = 1.0
@export var tracks_target: bool = false

var _direction: Vector2 = Vector2.RIGHT
var _timer: float = 0.0
var _attack_id: int = 0
var _owner: Node = null
var _has_hit: bool = false
var _target_node: Node2D = null
var _debug_process_logs_left: int = 5

@onready var _animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D


func _enter_tree() -> void:
	collision_layer = 4
	collision_mask = 0
	monitoring = false
	monitorable = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = _direction.angle()
	if _animated_sprite:
		_animated_sprite.rotation = 0.0
	if _sprite:
		_sprite.rotation = 0.0
	_play_visual()
	if _is_ballista_debug():
		print("[BALLISTA PROJECTILE][ready] scene=%s type=%s pos=%s animated=%s sprite=%s monitoring=%s mask=%s" % [
			scene_file_path,
			projectile_type,
			str(global_position),
			str(_animated_sprite != null),
			str(_sprite != null),
			str(monitoring),
			str(collision_mask)
		])


func setup(p_direction: Vector2, p_damage: float, p_target = null, p_owner: Node = null) -> void:
	_direction = p_direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	damage = p_damage
	_owner = p_owner
	_attack_id += 1
	rotation = _direction.angle()
	if tracks_target and p_target != null and p_target is Node2D:
		_target_node = p_target as Node2D
	else:
		_target_node = null
	_configure_collision_mask(p_target)
	if _is_ballista_debug():
		print("[BALLISTA PROJECTILE][setup] scene=%s owner=%s dir=%s damage=%.2f target=%s tracks=%s mask=%s" % [
			scene_file_path,
			_debug_owner_id(),
			str(_direction),
			damage,
			_debug_target_name(p_target),
			str(tracks_target),
			str(collision_mask)
		])


func set_projectile_profile(type: String, projectile_speed: float, spin_deg: float = 0.0) -> void:
	projectile_type = type.strip_edges().to_lower()
	if projectile_type == "":
		projectile_type = "default"
	speed = maxf(1.0, projectile_speed)
	spin_speed_deg = spin_deg
	_play_visual()
	if _is_ballista_debug():
		print("[BALLISTA PROJECTILE][profile] scene=%s type=%s speed=%.2f spin=%.2f" % [
			scene_file_path,
			projectile_type,
			speed,
			spin_speed_deg
		])


func _configure_collision_mask(target) -> void:
	if target != null and target is Node and is_instance_valid(target):
		var target_node := target as Node
		if target_node.is_in_group("wall"):
			collision_mask = 128
			monitoring = true
			return
		if target_node.is_in_group("hero"):
			collision_mask = 1
		elif target_node.is_in_group("enemy") or target_node.is_in_group("mobs") or target_node.is_in_group("enemies"):
			collision_mask = 2
		else:
			collision_mask = 0
	elif _owner and is_instance_valid(_owner):
		if _owner.is_in_group("enemy"):
			collision_mask = 1
		elif _owner.is_in_group("hero"):
			collision_mask = 2
		else:
			collision_mask = 0
	else:
		collision_mask = 0
	monitoring = collision_mask != 0


func _play_visual() -> void:
	if _animated_sprite and _animated_sprite.sprite_frames:
		if _animated_sprite.sprite_frames.has_animation(projectile_type):
			_animated_sprite.play(projectile_type)
		elif _animated_sprite.sprite_frames.has_animation("default"):
			_animated_sprite.play("default")


func _get_target_tracking_position() -> Vector2:
	if _target_node == null or not is_instance_valid(_target_node):
		return global_position + _direction
	var hurtbox_shape := _target_node.get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	if hurtbox_shape:
		return hurtbox_shape.global_position
	var hurtbox := _target_node.get_node_or_null("Hurtbox") as Node2D
	if hurtbox:
		return hurtbox.global_position
	return _target_node.global_position


func _build_hit_excludes() -> Array[RID]:
	var excludes: Array[RID] = [get_rid()]
	if _owner and is_instance_valid(_owner) and _owner is CollisionObject2D:
		excludes.append((_owner as CollisionObject2D).get_rid())
	return excludes


func _raycast_hit_along_segment(from_pos: Vector2, to_pos: Vector2) -> Node:
	if collision_mask == 0:
		return null
	var world_2d := get_world_2d()
	if world_2d == null or world_2d.direct_space_state == null:
		return null
	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos, collision_mask, _build_hit_excludes())
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := world_2d.direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider") as Node


func _process(delta: float) -> void:
	var previous_position := global_position
	if _target_node != null and is_instance_valid(_target_node) and not _has_hit:
		var is_dead := false
		if "is_dead" in _target_node:
			is_dead = bool(_target_node.is_dead)
		if not is_dead:
			_direction = (_get_target_tracking_position() - global_position).normalized()
			if _direction == Vector2.ZERO:
				_direction = Vector2.RIGHT
			rotation = _direction.angle()
	position += _direction * speed * delta
	if _is_ballista_debug() and _debug_process_logs_left > 0:
		_debug_process_logs_left -= 1
		var visual_state := "none"
		if _animated_sprite:
			visual_state = "anim:%s playing=%s frame=%d visible=%s" % [_animated_sprite.animation, str(_animated_sprite.is_playing()), _animated_sprite.frame, str(_animated_sprite.visible)]
		elif _sprite:
			visual_state = "sprite visible=%s" % str(_sprite.visible)
		print("[BALLISTA PROJECTILE][process] scene=%s pos=%s dir=%s speed=%.2f monitor=%s mask=%s visual=%s" % [
			scene_file_path,
			str(global_position),
			str(_direction),
			speed,
			str(monitoring),
			str(collision_mask),
			visual_state
		])
	if not _has_hit:
		var raycast_hit := _raycast_hit_along_segment(previous_position, global_position)
		if raycast_hit != null:
			_try_damage(raycast_hit)
	if _animated_sprite and absf(spin_speed_deg) > 0.001:
		_animated_sprite.rotation += deg_to_rad(spin_speed_deg) * delta
	elif _sprite and absf(spin_speed_deg) > 0.001:
		_sprite.rotation += deg_to_rad(spin_speed_deg) * delta
	_timer += delta
	if _timer >= lifetime:
		if _is_ballista_debug():
			print("[BALLISTA PROJECTILE][lifetime_free] scene=%s pos=%s lifetime=%.2f" % [scene_file_path, str(global_position), lifetime])
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	_try_damage(area)


func _on_body_entered(body: Node2D) -> void:
	_try_damage(body)


func _disable_collisions_deferred() -> void:
	set_deferred("monitoring", false)
	set_deferred("collision_mask", 0)


func _try_damage(target: Node) -> void:
	if _has_hit or target == null or not is_instance_valid(target):
		return
	if _is_ballista_debug():
		print("[BALLISTA PROJECTILE][hit_check] scene=%s target=%s parent=%s has_apply_hit=%s has_take_damage=%s" % [
			scene_file_path,
			_debug_target_name(target),
			_debug_target_name(target.get_parent() if target else null),
			str(target.has_method("apply_hit")),
			str(target.has_method("take_damage"))
		])
	var parent_node := target.get_parent() if target else null
	if _owner and is_instance_valid(_owner):
		if target == _owner or parent_node == _owner:
			return
		var target_faction_node: Node = target
		if parent_node and parent_node is Node:
			target_faction_node = parent_node
		if _owner.is_in_group("enemy") and target_faction_node.is_in_group("enemy"):
			return
		if _owner.is_in_group("hero") and target_faction_node.is_in_group("hero"):
			return
	if target.has_method("apply_hit"):
		_has_hit = true
		_disable_collisions_deferred()
		if _is_ballista_debug():
			print("[BALLISTA PROJECTILE][apply_hit] target=%s damage=%.2f mult=%.2f" % [_debug_target_name(target), damage, damage_multiplier])
		target.apply_hit(damage * damage_multiplier, self, _attack_id)
		queue_free()
		return
	if parent_node and parent_node.has_method("apply_hit"):
		_has_hit = true
		_disable_collisions_deferred()
		if _is_ballista_debug():
			print("[BALLISTA PROJECTILE][apply_hit_parent] target=%s damage=%.2f mult=%.2f" % [_debug_target_name(parent_node), damage, damage_multiplier])
		parent_node.apply_hit(damage * damage_multiplier, self, _attack_id)
		queue_free()
		return
	if target.has_method("take_damage"):
		_has_hit = true
		_disable_collisions_deferred()
		if _is_ballista_debug():
			print("[BALLISTA PROJECTILE][take_damage] target=%s damage=%.2f mult=%.2f" % [_debug_target_name(target), damage, damage_multiplier])
		target.take_damage(int(damage * damage_multiplier))
		queue_free()
		return
	if parent_node and parent_node.has_method("take_damage"):
		_has_hit = true
		_disable_collisions_deferred()
		if _is_ballista_debug():
			print("[BALLISTA PROJECTILE][take_damage_parent] target=%s damage=%.2f mult=%.2f" % [_debug_target_name(parent_node), damage, damage_multiplier])
		parent_node.take_damage(int(damage * damage_multiplier))
		queue_free()


func _is_ballista_debug() -> bool:
	if projectile_type == "cannonball":
		return true
	if scene_file_path.contains("CannonProjectile"):
		return true
	if _owner and is_instance_valid(_owner) and "hero_id" in _owner:
		return String(_owner.hero_id).begins_with("ballista")
	return false


func _debug_owner_id() -> String:
	if _owner == null or not is_instance_valid(_owner):
		return "null"
	if "hero_id" in _owner:
		return String(_owner.hero_id)
	return String(_owner.name)


func _debug_target_name(target) -> String:
	if target == null or not is_instance_valid(target):
		return "null"
	if target is Node:
		return String((target as Node).name)
	return str(target)
