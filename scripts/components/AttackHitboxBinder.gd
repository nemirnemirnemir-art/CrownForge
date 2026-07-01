extends RefCounted
class_name AttackHitboxBinder

@export var animation_sprite_path: NodePath
@export var hit_component_path: NodePath
@export var shapecast_path: NodePath

@export var hit_offset: float = 26.0
@export var hit_length: float = 44.0
@export var hit_width: float = 26.0

var _owner_node: Node = null

func init(owner_node: Node) -> void:
	_owner_node = owner_node

func get_shapecast() -> ShapeCast2D:
	if not is_instance_valid(_owner_node):
		return null
	var n = _owner_node.get_node_or_null(shapecast_path)
	if n == null:
		var p = _owner_node.get_parent()
		if p:
			n = p.get_node_or_null("AttackShapeCast")
	return n as ShapeCast2D

func get_hit_component() -> Area2D:
	if not is_instance_valid(_owner_node):
		return null
	var n = _owner_node.get_node_or_null(hit_component_path)
	if n == null:
		var p = _owner_node.get_parent()
		if p:
			n = p.get_node_or_null("Hitbox")
	return n as Area2D

func get_anim() -> AnimatedSprite2D:
	if not is_instance_valid(_owner_node):
		return null
	var n = _owner_node.get_node_or_null(animation_sprite_path)
	if n == null:
		var p = _owner_node.get_parent()
		if p:
			n = p.get_node_or_null("AnimationSprite2D")
	return n as AnimatedSprite2D

func update_hitbox_transform(dir: Vector2) -> void:
	var hit := get_hit_component()
	if hit == null:
		return
	hit.position = dir * hit_offset

	var sc := get_shapecast()
	if sc:
		sc.position = hit.position

	var cs := hit.get_node_or_null("CollisionShape2D")
	if cs and cs is CollisionShape2D and (cs as CollisionShape2D).shape is RectangleShape2D:
		var rect := (cs as CollisionShape2D).shape as RectangleShape2D
		if dir == Vector2.LEFT or dir == Vector2.RIGHT:
			rect.size = Vector2(hit_length, hit_width)
		else:
			rect.size = Vector2(hit_width, hit_length)
		if sc and sc.shape is RectangleShape2D:
			(sc.shape as RectangleShape2D).size = rect.size
		elif sc:
			var new_rect := RectangleShape2D.new()
			new_rect.size = rect.size
			sc.shape = new_rect
	elif cs and cs is CollisionShape2D and (cs as CollisionShape2D).shape is CircleShape2D:
		var circle := (cs as CollisionShape2D).shape as CircleShape2D
		if sc and sc.shape is CircleShape2D:
			(sc.shape as CircleShape2D).radius = circle.radius
		elif sc:
			var new_circle := CircleShape2D.new()
			new_circle.radius = circle.radius
			sc.shape = new_circle

func enable_hitbox(attack_id: int, attack_damage: float, target: Node2D, on_hit_callback: Callable) -> void:
	var hit := get_hit_component()
	if hit and hit.has_method("enabled"):
		if hit.has_signal("hit_landed") and not hit.hit_landed.is_connected(on_hit_callback):
			hit.hit_landed.connect(on_hit_callback)
		hit.enabled(attack_id, attack_damage, target)
		_ensure_debug_visual(hit)

func disable_hitbox() -> void:
	var hit := get_hit_component()
	if hit and hit.has_method("disabled"):
		hit.disabled()
	var debug_node = hit.get_node_or_null("DebugVisual") if hit else null
	if debug_node:
		debug_node.visible = false

func _ensure_debug_visual(hit: Area2D) -> void:
	if not OS.is_debug_build():
		return
	var debug_node = hit.get_node_or_null("DebugVisual")
	if debug_node == null:
		var rect := ColorRect.new()
		rect.name = "DebugVisual"
		rect.color = Color(1, 0, 0, 0.4)
		hit.add_child(rect)
		debug_node = rect
	var cs := hit.get_node_or_null("CollisionShape2D")
	if cs and cs.shape is RectangleShape2D:
		var size := (cs.shape as RectangleShape2D).size
		debug_node.size = size
		debug_node.position = -size / 2.0
	elif cs and cs.shape is CircleShape2D:
		var r := (cs.shape as CircleShape2D).radius
		debug_node.size = Vector2(r * 2, r * 2)
		debug_node.position = Vector2(-r, -r)
	debug_node.visible = true
