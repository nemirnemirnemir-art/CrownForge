extends RefCounted
class_name ArtifactPersistenceFlow

func get_save_data(owned: Dictionary, active: Dictionary, state: Dictionary, pending_spell_choice_rewards: int, pending_legendary_spell_choice_rewards: int) -> Dictionary:
	return {
		"owned": owned.keys(),
		"active": active.keys(),
		"state": state.duplicate(true),
		"pending_spell_choice_rewards": pending_spell_choice_rewards,
		"pending_legendary_spell_choice_rewards": pending_legendary_spell_choice_rewards,
	}

func load_save_data(data: Dictionary, has_def: Callable) -> Dictionary:
	var owned: Dictionary = {}
	var active: Dictionary = {}
	var state: Dictionary = {}
	var pending_spell_choice_rewards: int = max(0, int(data.get("pending_spell_choice_rewards", 0)))
	var pending_legendary_spell_choice_rewards: int = max(0, int(data.get("pending_legendary_spell_choice_rewards", 0)))

	var owned_arr: Array = data.get("owned", [])
	for a in owned_arr:
		var artifact_id := str(a)
		if has_def.is_valid() and has_def.call(artifact_id):
			owned[artifact_id] = true

	var active_arr: Array = data.get("active", [])
	for a in active_arr:
		var artifact_id := str(a)
		if owned.has(artifact_id):
			active[artifact_id] = true

	var s_val: Variant = data.get("state", {})
	if s_val is Dictionary:
		state = (s_val as Dictionary).duplicate(true)

	return {
		"owned": owned,
		"active": active,
		"state": state,
		"pending_spell_choice_rewards": pending_spell_choice_rewards,
		"pending_legendary_spell_choice_rewards": pending_legendary_spell_choice_rewards,
	}

func reset_state() -> Dictionary:
	return {
		"owned": {},
		"active": {},
		"state": {},
		"runtime_class_bonus_applied": {},
		"pending_spell_choice_rewards": 0,
		"pending_legendary_spell_choice_rewards": 0,
	}

func reapply_active_effects(active: Dictionary, runtime_class_bonus_applied: Dictionary, troop_core: Node, reapply_class_bonuses: Callable, refresh_dependents: Callable) -> void:
	if reapply_class_bonuses.is_valid():
		reapply_class_bonuses.call(active, runtime_class_bonus_applied, troop_core)
	if refresh_dependents.is_valid():
		refresh_dependents.call()
