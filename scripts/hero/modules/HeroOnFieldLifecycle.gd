extends RefCounted
class_name HeroOnFieldLifecycle

var hero = null


func setup(hero_ref) -> void:
	hero = hero_ref


func physics_tick(delta: float, debug_module, health_module, state_machine, visuals, update_attack_timer: Callable, validate_target: Callable, process_frame_mod: int) -> bool:
	if debug_module:
		debug_module.process_debug_tick(delta)
	if health_module:
		health_module.check_auto_potion_use()
		health_module.update_health_bar()
		if health_module.is_dead():
			die(state_machine, Callable())
			return true
	if hero != null and hero.is_stunned:
		hero.stun_timer = max(0.0, hero.stun_timer - delta)
		hero.velocity = Vector2.ZERO
		if hero.stun_timer <= 0.0:
			hero.is_stunned = false
			if hero.has_method("_set_stun_speed_scale"):
				hero._set_stun_speed_scale(1.0)
			if state_machine:
				state_machine.set_process(hero._stun_prev_sm_process)
				state_machine.set_physics_process(hero._stun_prev_sm_physics)
		else:
			return true
	if update_attack_timer.is_valid():
		update_attack_timer.call(delta)
	if process_frame_mod > 0 and visuals and Engine.get_process_frames() % process_frame_mod == 0:
		visuals.sync_selection_outline_flip()
	if validate_target.is_valid():
		validate_target.call()
	return false


func die(state_machine, queue_free_callback: Callable) -> void:
	if state_machine:
		state_machine.change_state("HeroDeathState")
	elif queue_free_callback.is_valid():
		queue_free_callback.call()


func return_to_bridge(movement, state_machine) -> void:
	if hero == null:
		return
	movement.is_returning = true
	hero.current_target = null
	if state_machine:
		state_machine.change_state("HeroReturningHomeState")


func on_bridge_reached(hero_id: String, runtime_bridge, remove_callback: Callable) -> void:
	var hero_core = runtime_bridge.get_hero_core() if runtime_bridge else null
	if hero_core != null:
		hero_core.call("remove_from_squad", hero_id)
	if remove_callback.is_valid():
		remove_callback.call()
