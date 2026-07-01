extends RefCounted
class_name ArtifactOwnershipFlow

func add_artifact(artifact_id: String, owned: Dictionary, state: Dictionary, pending_spell_choice_rewards: int, pending_legendary_spell_choice_rewards: int, has_def: Callable, apply_on_pickup: Callable, queue_spell_rewards: Callable) -> Dictionary:
	if artifact_id == "":
		return {
			"added": false,
			"was_owned": false,
			"pending_spell_choice_rewards": pending_spell_choice_rewards,
			"pending_legendary_spell_choice_rewards": pending_legendary_spell_choice_rewards,
			"pending_rewards": [],
		}
	if not has_def.is_valid() or not has_def.call(artifact_id):
		return {
			"added": false,
			"was_owned": false,
			"pending_spell_choice_rewards": pending_spell_choice_rewards,
			"pending_legendary_spell_choice_rewards": pending_legendary_spell_choice_rewards,
			"pending_rewards": [],
		}

	var was_owned := owned.has(artifact_id)
	var next_pending := pending_spell_choice_rewards
	var next_pending_legendary := pending_legendary_spell_choice_rewards
	var pending_rewards: Array = []
	if not was_owned:
		owned[artifact_id] = true
		var pickup_result: Variant = null
		if apply_on_pickup.is_valid():
			pickup_result = apply_on_pickup.call(artifact_id, state)
		if pickup_result is Dictionary and pickup_result.get("queue_spell", false) and queue_spell_rewards.is_valid():
			var result: Dictionary = queue_spell_rewards.call(
				next_pending,
				next_pending_legendary,
				int((pickup_result as Dictionary).get("count", 0)),
				bool((pickup_result as Dictionary).get("legendary_only", false))
			)
			next_pending = int(result.get("pending", next_pending))
			next_pending_legendary = int(result.get("pending_legendary", next_pending_legendary))
		if pickup_result is Dictionary and pickup_result.has("pending_rewards"):
			var rewards_value: Variant = (pickup_result as Dictionary).get("pending_rewards", [])
			if rewards_value is Array:
				pending_rewards = rewards_value
	return {
		"added": not was_owned,
		"was_owned": was_owned,
		"pending_spell_choice_rewards": next_pending,
		"pending_legendary_spell_choice_rewards": next_pending_legendary,
		"pending_rewards": pending_rewards,
	}

func set_active(artifact_id: String, should_activate: bool, owned: Dictionary, active: Dictionary, state: Dictionary, runtime_class_bonus_applied: Dictionary, troop_core: Node, apply_on_activated: Callable, apply_on_deactivated: Callable) -> Dictionary:
	if not owned.has(artifact_id):
		return {"changed": false, "active": active.has(artifact_id)}
	var is_now_active := active.has(artifact_id)
	if should_activate and not is_now_active:
		active[artifact_id] = true
		if apply_on_activated.is_valid():
			apply_on_activated.call(artifact_id, state, runtime_class_bonus_applied, troop_core)
		return {"changed": true, "active": true}
	if (not should_activate) and is_now_active:
		active.erase(artifact_id)
		if apply_on_deactivated.is_valid():
			apply_on_deactivated.call(artifact_id, state, runtime_class_bonus_applied, troop_core)
		return {"changed": true, "active": false}
	return {"changed": false, "active": is_now_active}

func remove_artifact(artifact_id: String, owned: Dictionary, active: Dictionary, state: Dictionary, runtime_class_bonus_applied: Dictionary, troop_core: Node, apply_on_activated: Callable, apply_on_deactivated: Callable) -> Dictionary:
	if not owned.has(artifact_id):
		return {"removed": false, "was_active": false}
	var deactivate_result := set_active(artifact_id, false, owned, active, state, runtime_class_bonus_applied, troop_core, apply_on_activated, apply_on_deactivated)
	owned.erase(artifact_id)
	state.erase(artifact_id)
	runtime_class_bonus_applied.erase(artifact_id)
	return {
		"removed": true,
		"was_active": bool(deactivate_result.get("changed", false)),
		"active": false,
	}
