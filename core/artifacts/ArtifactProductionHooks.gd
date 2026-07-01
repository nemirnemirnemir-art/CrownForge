extends RefCounted
class_name ArtifactProductionHooks

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

const COMFORTABLE_HANDLE_ID := "comfortable_handle"
const COMFORTABLE_HANDLE_WELL_IDS := {
	"well": true,
	"big_well": true,
}
const FILTERED_FUEL_ID := "filtered_fuel"
const CLAY_TREASURE_ID := "clay_treasure"
const MAGIC_ACORN_ID := "magic_acorn"
const ROYAL_ORDER_ID := "royal_order"
const FLOUR_DEITY_ID := "flour_deity"
const SUPER_METAL_ID := "super_metal"
const TRACKED_PRODUCTION_ARTIFACTS := {
	CLAY_TREASURE_ID: {
		"resource_id": "clay",
		"threshold": 1000,
		"state_key": "clay_progress",
		"completion_key": "clay_reward_claimed",
		"reward_type": "legendary_artifact_choice",
	},
	MAGIC_ACORN_ID: {
		"resource_id": "wood",
		"threshold": 1000,
		"state_key": "wood_progress",
		"completion_key": "wood_reward_claimed",
		"reward_type": "bonus_wood",
	},
	ROYAL_ORDER_ID: {
		"resource_id": "crystal",
		"threshold": 1000,
		"state_key": "crystal_progress",
		"completion_key": "crystal_reward_claimed",
		"reward_type": "legendary_spell_grants",
	},
}


func on_resource_production_completed(active: Dictionary, state: Dictionary, building_id: String, outputs: Array, production_count: int, resource_core: Variant) -> bool:
	var changed := false
	if resource_core == null or not resource_core.has_method("add_resource"):
		return false

	var normalized_id := String(building_id).strip_edges().to_lower()
	var safe_production_count: int = max(1, production_count)

	if active.has(COMFORTABLE_HANDLE_ID) and COMFORTABLE_HANDLE_WELL_IDS.has(normalized_id):
		for _i in range(safe_production_count):
			if randf() < 0.10:
				resource_core.call("add_resource", "wood", 1)

	if outputs.is_empty():
		return changed

	var produced_totals := _collect_output_totals(outputs)
	if produced_totals.is_empty():
		return changed

	if active.has(FILTERED_FUEL_ID):
		_process_filtered_fuel(produced_totals, resource_core)

	if active.has(FLOUR_DEITY_ID):
		changed = _accumulate_scalar_progress(state, FLOUR_DEITY_ID, "flour_produced", int(produced_totals.get("flour", 0))) or changed

	if active.has(SUPER_METAL_ID):
		changed = _accumulate_scalar_progress(state, SUPER_METAL_ID, "metal_produced", int(produced_totals.get("steel", 0))) or changed

	for artifact_id in TRACKED_PRODUCTION_ARTIFACTS.keys():
		if not active.has(artifact_id):
			continue
		changed = _process_threshold_reward(str(artifact_id), state, produced_totals, resource_core) or changed

	return changed


func _collect_output_totals(outputs: Array) -> Dictionary:
	var totals: Dictionary = {}
	for output_value in outputs:
		if not (output_value is Dictionary):
			continue
		var output := output_value as Dictionary
		var resource_id := _normalize_resource_id(String(output.get("resource_id", "")))
		if resource_id == "":
			continue
		var amount: int = max(0, int(output.get("amount", 0)))
		if amount <= 0:
			continue
		totals[resource_id] = int(totals.get(resource_id, 0)) + amount
	return totals


func _process_filtered_fuel(produced_totals: Dictionary, resource_core: Variant) -> void:
	var water_amount := int(produced_totals.get("water", 0))
	if water_amount <= 0:
		return
	var bonus_fuel := 0
	for _i in range(water_amount):
		if randf() < 0.04:
			bonus_fuel += 1
	if bonus_fuel > 0:
		resource_core.call("add_resource", "fuel", bonus_fuel)


func _process_threshold_reward(artifact_id: String, state: Dictionary, produced_totals: Dictionary, resource_core: Variant) -> bool:
	var config: Dictionary = TRACKED_PRODUCTION_ARTIFACTS.get(artifact_id, {})
	if config.is_empty():
		return false
	var resource_id := String(config.get("resource_id", ""))
	var produced_amount := int(produced_totals.get(resource_id, 0))
	if produced_amount <= 0:
		return false

	var progress_key := String(config.get("state_key", "progress"))
	var completion_key := String(config.get("completion_key", "reward_claimed"))
	if ArtifactState.get_int(state, artifact_id, completion_key, 0) > 0:
		return false

	var threshold: int = max(1, int(config.get("threshold", 1)))
	var next_progress := ArtifactState.get_int(state, artifact_id, progress_key, 0) + produced_amount
	ArtifactState.set_int(state, artifact_id, progress_key, next_progress)
	if next_progress < threshold:
		return true

	ArtifactState.set_int(state, artifact_id, completion_key, 1)
	match String(config.get("reward_type", "")):
		"bonus_wood":
			resource_core.call("add_resource", "wood", 500)
		"legendary_artifact_choice":
			_enqueue_pending_reward({
				"type": "artifact_choice",
				"legendary_only": true,
				"offered_count": 1,
			})
		"legendary_spell_grants":
			_enqueue_random_legendary_spell_rewards(3)
	return true


func _accumulate_scalar_progress(state: Dictionary, artifact_id: String, state_key: String, amount: int) -> bool:
	if amount <= 0:
		return false
	var next_value := ArtifactState.get_int(state, artifact_id, state_key, 0) + amount
	ArtifactState.set_int(state, artifact_id, state_key, next_value)
	return true


func _enqueue_random_legendary_spell_rewards(count: int) -> void:
	var safe_count: int = max(0, count)
	if safe_count <= 0:
		return
	var pool := PathRegistryScript.list_spell_config_ids(true)
	if pool.is_empty():
		return
	for _i in range(safe_count):
		var spell_id := String(pool[randi() % pool.size()])
		if spell_id == "":
			continue
		_enqueue_pending_reward({
			"type": "spell_grant",
			"spell_id": spell_id,
		})


func _enqueue_pending_reward(reward: Dictionary) -> void:
	if reward.is_empty():
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var game_scene := tree.get_first_node_in_group("game_scene")
	if game_scene == null or not game_scene.has_method("enqueue_pending_reward"):
		return
	game_scene.call("enqueue_pending_reward", reward)


func _normalize_resource_id(resource_id: String) -> String:
	match resource_id.strip_edges().to_lower():
		"ore":
			return "iron_ore"
		"metal":
			return "steel"
		"fuel":
			return "oil"
		_:
			return resource_id.strip_edges().to_lower()
