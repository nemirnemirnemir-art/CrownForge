extends RefCounted
class_name SpellDamageApplicator


func apply_damage(target: Node, amount: float, source: Node = null, attack_id: int = 0, prefer_apply_damage: bool = false) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	if prefer_apply_damage and target.has_method("apply_damage"):
		target.call("apply_damage", amount, source)
		return true

	var hurtbox := target.get_node_or_null("Hurtbox")
	if hurtbox != null and hurtbox.has_method("apply_hit"):
		hurtbox.call("apply_hit", amount, source, attack_id)
		return true

	if target.has_method("apply_hit"):
		target.call("apply_hit", amount, source, attack_id)
		return true

	if target.has_method("apply_damage"):
		target.call("apply_damage", amount, source)
		return true

	if target.has_method("take_damage"):
		target.call("take_damage", amount)
		return true

	return false
