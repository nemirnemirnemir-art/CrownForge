extends RefCounted
class_name HeroOnFieldStatusEffects

const FriendlyDamageBlockHelperScript := preload("res://scripts/hero/shared/FriendlyDamageBlockHelper.gd")

var hero = null


func setup(hero_ref) -> void:
	hero = hero_ref


func apply_stun(duration: float, state_machine, animations, stun_effect, floating_text) -> void:
	if hero == null or duration <= 0.0:
		return
	hero.stun_timer = max(hero.stun_timer, duration)
	if hero.is_stunned:
		return
	hero.is_stunned = true
	hero.velocity = Vector2.ZERO
	hero.current_target = null
	if state_machine:
		hero._stun_prev_sm_process = state_machine.is_processing()
		hero._stun_prev_sm_physics = state_machine.is_physics_processing()
		state_machine.set_process(false)
		state_machine.set_physics_process(false)
	var ac = hero.get_node_or_null("AttackComponent")
	if ac and ac.has_method("cancel_attack"):
		ac.cancel_attack()
	if animations and animations.has_method("set_attack_animation_playing"):
		animations.set_attack_animation_playing(false)
	set_stun_speed_scale(hero, 0.0)
	if stun_effect:
		var existing = hero.get_node_or_null("StunEffect")
		if existing and is_instance_valid(existing):
			existing.queue_free()
		stun_effect.attach_to(hero, duration)
	if floating_text and hero.get_parent():
		floating_text.spawn_stun(hero.get_parent(), hero.global_position + Vector2(0, -30))


func take_damage(amount: int, damage_taken_multiplier: float, is_invincible: bool, evasion_chance: float, runtime_bridge, damage_popup_pool_override = null, block_roll_provider: Callable = Callable()) -> void:
	if hero == null or is_invincible:
		return
	if evasion_chance > 0.0 and randf() < clampf(evasion_chance, 0.0, 1.0):
		var pool = damage_popup_pool_override if damage_popup_pool_override != null else runtime_bridge.get_damage_popup_pool()
		if pool == null and hero.get_parent() and FloatingText:
			FloatingText.spawn_evade(hero.get_parent(), hero.global_position + Vector2(0, -30))
		return
	if FriendlyDamageBlockHelperScript.should_block_damage(hero if hero is Node else null, block_roll_provider):
		if hero is Node and hero.get_parent() and FloatingText:
			FloatingText.spawn_evade(hero.get_parent(), hero.global_position + Vector2(0, -30))
		return
	var scaled_amount := maxf(1.0, float(amount) * maxf(0.0, damage_taken_multiplier))
	var final_amount := int(round(scaled_amount))
	if runtime_bridge:
		runtime_bridge.send_damage(String(hero.get("hero_id")), final_amount)
	var popup_pool = damage_popup_pool_override if damage_popup_pool_override != null else (runtime_bridge.get_damage_popup_pool() if runtime_bridge else null)
	if popup_pool != null and is_instance_valid(popup_pool) and popup_pool.has_method("show_damage"):
		popup_pool.call("show_damage", hero.global_position, final_amount, false)
	if hero is Node:
		UnitDamageFlash.flash_from_node(hero)


func on_hero_healed(healed_hero_id: String, local_hero_id: String, health_module) -> void:
	if healed_hero_id != local_hero_id or health_module == null:
		return
	if health_module.has_method("update_health_bar"):
		health_module.update_health_bar()


## Sets speed_scale on all animation sprites to pause or resume animations during stun.
func set_stun_speed_scale(hero_node: Node, scale_val: float) -> void:
	var anim_sprite = hero_node.get("animation_sprite")
	if anim_sprite and is_instance_valid(anim_sprite):
		anim_sprite.speed_scale = scale_val
	var walk_sprite := hero_node.get_node_or_null("AnimWalk") as AnimatedSprite2D
	if walk_sprite:
		walk_sprite.speed_scale = scale_val
	var attack_sprite := hero_node.get_node_or_null("AnimAttack") as AnimatedSprite2D
	if attack_sprite:
		attack_sprite.speed_scale = scale_val
