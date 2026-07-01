extends "res://scripts/combat/Projectile.gd"
class_name GnollBoneProjectile

const GnollStunIconEffect = preload("res://scripts/effects/GnollStunIconEffect.gd")

@export var stun_chance: float = 0.25
@export var stun_duration: float = 3.0

func _ready() -> void:
	projectile_type = "gnoll_bone"
	super()

func _try_damage(target: Node) -> void:
	if _has_hit:
		return
	if not target or not is_instance_valid(target):
		return

	var parent_node: Node = null
	if target:
		parent_node = target.get_parent()

	if _owner and is_instance_valid(_owner):
		if target == _owner:
			return
		if parent_node == _owner:
			return

		var target_faction_node: Node = target
		if parent_node and parent_node is Node:
			target_faction_node = parent_node

		if _owner.is_in_group("enemy") and target_faction_node.is_in_group("enemy"):
			return
		if _owner.is_in_group("hero") and target_faction_node.is_in_group("hero"):
			return

	var stun_target := _resolve_hero_target(target, parent_node)
	if stun_target:
		_try_apply_stun(stun_target)

	if target.has_method("apply_hit"):
		_has_hit = true
		_disable_collisions_deferred()
		target.apply_hit(damage, self, _attack_id)
		queue_free()
		return

	if parent_node and parent_node.has_method("apply_hit"):
		_has_hit = true
		_disable_collisions_deferred()
		parent_node.apply_hit(damage, self, _attack_id)
		queue_free()
		return

	if target.has_method("take_damage"):
		_has_hit = true
		_disable_collisions_deferred()
		target.take_damage(int(damage))
		queue_free()
		return

	if parent_node and parent_node.has_method("take_damage"):
		_has_hit = true
		_disable_collisions_deferred()
		parent_node.take_damage(int(damage))
		queue_free()
		return

func _resolve_hero_target(target: Node, parent_node: Node) -> Node2D:
	if target and target.is_in_group("hero") and target is Node2D:
		return target as Node2D
	if parent_node and parent_node.is_in_group("hero") and parent_node is Node2D:
		return parent_node as Node2D
	return null

func _try_apply_stun(hero: Node2D) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if randf() > clampf(stun_chance, 0.0, 1.0):
		return

	if hero.has_method("apply_stun"):
		hero.apply_stun(stun_duration)
		if GnollStunIconEffect:
			GnollStunIconEffect.attach_to(hero, stun_duration)
