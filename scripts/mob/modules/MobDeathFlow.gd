extends RefCounted
class_name MobDeathFlow

var mob = null
var _corpse_spawn_callable: Callable = Callable(Corpse, "try_spawn_at")


func setup(mob_ref) -> void:
	mob = mob_ref


func on_died(shadow, anim_walk, anim_attack, animation_sprite, dead_node, animation_dead) -> void:
	if shadow:
		shadow.visible = false
	if anim_walk:
		anim_walk.visible = false
	if anim_attack:
		anim_attack.visible = false
	if animation_sprite:
		animation_sprite.visible = false
	if dead_node:
		dead_node.visible = true
		if dead_node.sprite_frames:
			var anim_to_play := ""
			if dead_node.sprite_frames.has_animation("dead"):
				anim_to_play = "dead"
			elif dead_node.sprite_frames.has_animation("death"):
				anim_to_play = "death"
			elif dead_node.sprite_frames.has_animation("default"):
				anim_to_play = "default"
			if anim_to_play != "":
				if dead_node.sprite_frames.has_method("set_animation_loop"):
					dead_node.sprite_frames.set_animation_loop(anim_to_play, false)
				if dead_node.has_method("play_anim"):
					dead_node.play_anim(anim_to_play)
				elif dead_node.has_method("play"):
					dead_node.play(anim_to_play)
		return
	if animation_dead:
		animation_dead.visible = true
		if animation_dead.has_method("play_anim"):
			animation_dead.play_anim("default")
		elif animation_dead.has_method("play"):
			animation_dead.play("default")
		return
	if animation_sprite:
		animation_sprite.visible = true


func on_death_animation_finished() -> void:
	if mob:
		mob.queue_free()


func set_corpse_spawn_callable(spawn_callable: Callable) -> void:
	_corpse_spawn_callable = spawn_callable


func try_spawn_corpse(mob_ref: Node2D) -> void:
	if mob_ref == null or not is_instance_valid(mob_ref):
		return
	if not _corpse_spawn_callable.is_valid():
		return
	_corpse_spawn_callable.call(mob_ref.get_parent(), mob_ref.global_position)


## Full death sequence: corpse, boss registration, health, combat teardown, animation, cleanup.
## Called from mob.die() as a thin delegation.
func execute_die(mob_ref: Node, aggro_area, hurtbox, hitbox, attack_component, runtime_bridge) -> void:
	if mob_ref is Node2D:
		try_spawn_corpse(mob_ref as Node2D)
	if mob_ref.has_method("_is_boss_mob") and mob_ref._is_boss_mob() and runtime_bridge:
		runtime_bridge.register_boss_killed()

	var health = mob_ref.get("health")
	if health and not health.is_dead:
		health.die()

	disable_combat_components(aggro_area, hurtbox, hitbox, attack_component)

	if mob_ref.has_method("play_death"):
		mob_ref.play_death()

	if mob_ref.is_in_group("enemy"):
		mob_ref.remove_from_group("enemy")

	if runtime_bridge:
		runtime_bridge.unregister_from_battle_core()

	mob_ref.get_tree().create_timer(1.5).timeout.connect(mob_ref._on_death_cleanup)


## Disables monitoring on all combat-related areas and cancels any pending attack.
func disable_combat_components(aggro_area, hurtbox, hitbox, attack_component) -> void:
	if aggro_area:
		aggro_area.monitoring = false
	if hurtbox:
		hurtbox.monitoring = false
	if hitbox:
		hitbox.monitoring = false
	if attack_component and attack_component.has_method("cancel_attack"):
		attack_component.cancel_attack()


## Wires up the post-death animation signal and fallback fade/free logic.
## Must be called AFTER on_died() so the correct anim node is visible.
func connect_death_cleanup(mob_ref: Node, dead_node, animation_dead, animation_sprite, death_anim_callback: Callable) -> void:
	if dead_node:
		if not dead_node.animation_finished.is_connected(death_anim_callback):
			dead_node.animation_finished.connect(death_anim_callback)
		mob_ref.get_tree().create_timer(2.0).timeout.connect(mob_ref.queue_free)
		return
	if animation_dead:
		if not animation_dead.animation_finished.is_connected(death_anim_callback):
			animation_dead.animation_finished.connect(death_anim_callback)
		mob_ref.get_tree().create_timer(2.0).timeout.connect(mob_ref.queue_free)
		return
	if animation_sprite:
		animation_sprite.visible = true
		var tween := mob_ref.create_tween()
		tween.tween_property(animation_sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(mob_ref.queue_free)
	else:
		mob_ref.queue_free()
