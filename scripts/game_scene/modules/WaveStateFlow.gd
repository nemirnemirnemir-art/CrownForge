extends RefCounted
class_name WaveStateFlow


func create_state() -> Dictionary:
	return {
		"wave_active": false,
		"alive_wave_mob_ids": {},
		"current_wave_mob_counts": {},
		"current_wave_rewards": []
	}


func begin_wave(state: Dictionary) -> void:
	state["wave_active"] = true
	state["alive_wave_mob_ids"] = {}
	state["current_wave_mob_counts"] = {}
	state["current_wave_rewards"] = []


func register_spawned_mob(state: Dictionary, mob: Node, track_for_wave: bool) -> void:
	if not track_for_wave or mob == null:
		return
	var alive_ids: Dictionary = state.get("alive_wave_mob_ids", {})
	alive_ids[mob.get_instance_id()] = true
	state["alive_wave_mob_ids"] = alive_ids


func register_spawned_count(state: Dictionary, enemy_id: String, count: int) -> void:
	var mob_counts: Dictionary = state.get("current_wave_mob_counts", {})
	mob_counts[enemy_id] = int(mob_counts.get(enemy_id, 0)) + count
	state["current_wave_mob_counts"] = mob_counts


func get_current_wave_rewards(state: Dictionary) -> Array:
	return Array(state.get("current_wave_rewards", [])).duplicate(true)


func get_current_wave_counts(state: Dictionary) -> Dictionary:
	return Dictionary(state.get("current_wave_mob_counts", {})).duplicate(true)


func on_mob_died(state: Dictionary, mob: Node, track_for_wave: bool, wave_completed_emit: Callable, on_all_cleared: Callable, current_wave: int) -> void:
	if not track_for_wave:
		return
	if not bool(state.get("wave_active", false)):
		return
	if mob != null:
		var alive_ids: Dictionary = state.get("alive_wave_mob_ids", {})
		alive_ids.erase(mob.get_instance_id())
		state["alive_wave_mob_ids"] = alive_ids
	if Dictionary(state.get("alive_wave_mob_ids", {})).is_empty():
		state["wave_active"] = false
		if wave_completed_emit.is_valid():
			wave_completed_emit.call(current_wave)
		if on_all_cleared.is_valid():
			on_all_cleared.call()


func unregister_mob_from_battle(mob: Node, get_singleton: Callable) -> void:
	var battle_core: Node = get_singleton.call("BattleCore")
	if battle_core and battle_core.has_method("unregister_mob"):
		battle_core.unregister_mob(mob)
