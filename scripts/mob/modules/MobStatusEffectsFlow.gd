extends RefCounted
class_name MobStatusEffectsFlow

var mob = null
var health = null


func setup(mob_ref, health_ref) -> void:
	mob = mob_ref
	health = health_ref


func take_damage(amount: float, is_crit: bool, floating_text = null, damage_popup_pool = null) -> void:
	if mob == null or health == null:
		return
	var evasion := float(mob.evasion_chance)
	if evasion > 0.0 and randf() < evasion:
		if floating_text and mob.get_parent():
			floating_text.spawn_evade(mob.get_parent(), mob.global_position + Vector2(0, -30))
		return
	if bool(mob.is_invincible):
		return
	var actual_damage: float = amount * float(mob.damage_taken_multiplier)
	health.take_damage(actual_damage, is_crit)


func apply_stun(duration: float, stun_effect = null, floating_text = null) -> void:
	if health == null or mob == null:
		return
	health.apply_stun(duration)
	if stun_effect:
		var existing = mob.get_node_or_null("StunEffect")
		if existing and is_instance_valid(existing):
			existing.queue_free()
		stun_effect.attach_to(mob, duration)
	if floating_text and mob.get_parent():
		floating_text.spawn_stun(mob.get_parent(), mob.global_position + Vector2(0, -30))
