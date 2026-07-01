extends RefCounted
class_name MobBootstrap


func run(mob) -> void:
	mob.stats.setup(mob, mob.move_speed, mob.invert_visual_facing, mob.attack_range, mob.aggro_range, mob.mob_damage, mob.heal_amount, mob.projectile_scene)
	mob.movement.setup(mob)
	mob.combat.setup(mob, null, null)
	mob.visuals.setup(mob)
	var wall_targeting_flow = mob.get("_wall_targeting_flow")
	if wall_targeting_flow and wall_targeting_flow.has_method("setup"):
		wall_targeting_flow.setup(mob)
	if mob.has_method("_consume_pending_wall_attack_stop_distance_override") and mob.movement and mob.movement.has_method("set_wall_attack_stop_distance"):
		var pending_wall_stop_override: float = float(mob._consume_pending_wall_attack_stop_distance_override())
		if pending_wall_stop_override >= 0.0:
			mob.movement.set_wall_attack_stop_distance(pending_wall_stop_override)
	if mob._runtime_bridge:
		mob._runtime_bridge.setup(mob)
	if mob.has_method("_register_combat_groups"):
		mob._register_combat_groups()
	if mob.has_method("_behavior_setup"):
		mob._behavior_setup()
	if mob.has_method("_component_setup"):
		mob._component_setup()
	if mob.has_method("_animation_setup"):
		mob._animation_setup()
	if mob.has_method("_signal_setup"):
		mob._signal_setup()
	if mob.has_method("_spawn_effects_setup"):
		mob._spawn_effects_setup()


## Resolves and wires all child-node components on the mob.
## Called from mob._component_setup() as a delegation target.
func setup_components(mob) -> void:
	mob._hurtbox = mob.get_node_or_null("Hurtbox")
	mob._hitbox = mob.get_node_or_null("Hitbox")
	mob._state_machine = mob.get_node_or_null("MobStateMachine")
	mob._aggro_area = mob.get_node_or_null("AggroArea")
	mob._attack_component = mob.get_node_or_null("AttackComponent")

	if not mob.health: push_error("[Mob] %s: Health component missing!" % mob.name)
	if not mob.rewards: push_error("[Mob] %s: Rewards component missing!" % mob.name)
	if not mob.slots: push_error("[Mob] %s: Slots component missing!" % mob.name)
	if not mob.click_handler: push_error("[Mob] %s: ClickHandler component missing!" % mob.name)

	mob.health.setup(mob)
	mob.rewards.setup(mob, mob.health)
	mob.slots.setup(mob)
	mob.click_handler.setup(mob, mob.click_area, mob.health)
	mob._status_effects_flow.setup(mob, mob.health)
	mob._death_flow.setup(mob)

	mob.collision_layer = 2
	mob.collision_mask = 1

	mob.combat.setup(mob, mob._aggro_area, mob._attack_component)
	mob.combat.set_attack_range(mob.stats.attack_range)
	mob.combat.mob_damage = mob.stats.mob_damage
	mob.combat.aggro_range = mob.stats.aggro_range

	mob.animations.setup(mob, mob.animation_sprite, mob.animation_dead, mob._attack_component, mob.anim_walk, mob.anim_attack)


## Detects dual-sprite vs single-sprite layout and sets initial visibility.
## Called from mob._animation_setup() as a delegation target.
func setup_animation_sprites(mob) -> void:
	if mob._death_anim_setup:
		mob._death_anim_setup.setup_death_anim(mob)
	if mob.anim_walk and mob.anim_attack:
		mob._use_dual_sprites = true
		mob.anim_walk.visible = true
		mob.anim_attack.visible = false
	elif mob.animation_sprite:
		mob._use_dual_sprites = false
	else:
		push_warning("[Mob] %s: No animation sprites found!" % mob.name)
