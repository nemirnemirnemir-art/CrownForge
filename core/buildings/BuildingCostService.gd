extends RefCounted
class_name BuildingCostService


func can_afford_building(
	building_id: String,
	buildings_by_id: Dictionary,
	build_cost_step_per_existing: float,
	resource_core = null,
	artifact_core = null,
	current_scene: Node = null,
	economy_core = null
) -> bool:
	var cost := get_next_build_cost(
		building_id,
		buildings_by_id,
		build_cost_step_per_existing,
		artifact_core,
		current_scene
	)
	if cost.is_empty():
		return true

	var resolved_resource_core = _resolve_resource_core(resource_core)
	var resolved_economy_core = _resolve_economy_core(economy_core)
	if resolved_resource_core == null and resolved_economy_core == null:
		return false

	for resource_id in cost.keys():
		var normalized_resource_id := String(resource_id)
		var need: int = int(cost[normalized_resource_id])
		var have := _get_owned_amount(normalized_resource_id, resolved_resource_core, resolved_economy_core)
		if have < need:
			return false
	return true


func pay_for_building(
	building_id: String,
	buildings_by_id: Dictionary,
	build_cost_step_per_existing: float,
	resource_core = null,
	artifact_core = null,
	current_scene: Node = null,
	economy_core = null
) -> bool:
	var cost := get_next_build_cost(
		building_id,
		buildings_by_id,
		build_cost_step_per_existing,
		artifact_core,
		current_scene
	)
	if cost.is_empty():
		return true

	var resolved_resource_core = _resolve_resource_core(resource_core)
	var resolved_economy_core = _resolve_economy_core(economy_core)
	if not can_afford_building(
		building_id,
		buildings_by_id,
		build_cost_step_per_existing,
		resolved_resource_core,
		artifact_core,
		current_scene,
		resolved_economy_core
	):
		return false

	var paid_costs: Array[Dictionary] = []
	for resource_id in cost.keys():
		var normalized_resource_id := String(resource_id)
		var amount: int = int(cost[normalized_resource_id])
		if amount <= 0:
			continue
		var spent := false
		if normalized_resource_id == "gold":
			spent = resolved_economy_core != null and resolved_economy_core.spend_gold(float(amount))
		elif resolved_resource_core != null:
			spent = resolved_resource_core.consume_resource(normalized_resource_id, amount)
		if not spent:
			return false
		paid_costs.append({"resource_id": normalized_resource_id, "amount": amount})

	var resolved_artifact_core = _resolve_artifact_core(artifact_core)
	if resolved_artifact_core != null and resolved_artifact_core.has_method("apply_build_refund"):
		resolved_artifact_core.call("apply_build_refund", paid_costs)

	return true


func get_next_build_cost(
	building_id: String,
	buildings_by_id: Dictionary,
	build_cost_step_per_existing: float,
	artifact_core = null,
	current_scene: Node = null
) -> Dictionary:
	var normalized_id := String(building_id).to_lower()
	if normalized_id == "":
		return {}

	var config = buildings_by_id.get(normalized_id, null)
	if not (config is BuildingConfig):
		return {}

	var artifact_mult := get_artifact_build_cost_multiplier(artifact_core)
	var placed_count := get_placed_building_count(normalized_id, current_scene)
	var stack_mult := 1.0 + float(placed_count) * build_cost_step_per_existing

	var result: Dictionary = {}
	for cost_entry in config.build_costs:
		if cost_entry == null:
			continue
		var base_amount: int = int(cost_entry.amount)
		if base_amount <= 0:
			continue
		var scaled_amount := int(ceili(float(base_amount) * artifact_mult * stack_mult))
		if scaled_amount < 1:
			scaled_amount = 1
		result[String(cost_entry.resource_id)] = scaled_amount

	return result


func get_next_build_markup_percent(
	building_id: String,
	build_cost_step_or_current_scene: Variant = 0.20,
	current_scene: Node = null
) -> int:
	var build_cost_step_per_existing := 0.20
	if build_cost_step_or_current_scene is Node:
		current_scene = build_cost_step_or_current_scene as Node
	else:
		build_cost_step_per_existing = float(build_cost_step_or_current_scene)
	var placed_count := get_placed_building_count(building_id, current_scene)
	if placed_count <= 0:
		return 0
	return int(round(placed_count * build_cost_step_per_existing * 100.0))


func get_placed_building_count(building_id: String, current_scene: Node = null) -> int:
	var normalized_id := String(building_id).to_lower()
	if normalized_id == "":
		return 0

	var resolved_scene := _resolve_current_scene(current_scene)
	if resolved_scene == null:
		return 0

	var map_layout := _resolve_map_layout(resolved_scene)
	if map_layout == null or not ("slots" in map_layout):
		return 0

	var count := 0
	for slot in map_layout.slots:
		if slot == null or not is_instance_valid(slot):
			continue
		var slot_building_id: String = ""
		if slot is Object:
			var raw_building_id: Variant = slot.get("current_building_id")
			if raw_building_id != null:
				slot_building_id = String(raw_building_id).to_lower()
		if slot_building_id == normalized_id:
			count += 1

	return count


func get_artifact_build_cost_multiplier(artifact_core = null) -> float:
	var resolved_artifact_core = _resolve_artifact_core(artifact_core)
	if resolved_artifact_core != null and resolved_artifact_core.has_method("get_build_cost_multiplier"):
		return maxf(0.01, float(resolved_artifact_core.call("get_build_cost_multiplier")))
	return 1.0


func _resolve_resource_core(resource_core):
	if resource_core != null:
		return resource_core
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ResourceCore")


func _resolve_economy_core(economy_core):
	if economy_core != null:
		return economy_core
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("EconomyCore")


func _get_owned_amount(resource_id: String, resource_core, economy_core) -> int:
	if resource_id == "gold":
		if economy_core != null and economy_core.has_method("get_gold"):
			return int(economy_core.get_gold())
		return 0
	if resource_core != null and resource_core.has_method("get_resource"):
		return int(resource_core.get_resource(resource_id))
	return 0


func _resolve_artifact_core(artifact_core):
	if artifact_core != null:
		return artifact_core
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")


func _resolve_current_scene(current_scene: Node = null) -> Node:
	if current_scene != null:
		return current_scene
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.current_scene


func _resolve_map_layout(current_scene: Node) -> Node:
	if current_scene == null:
		return null
	if current_scene.has_method("_get_map_layout_node"):
		var map_layout: Variant = current_scene.call("_get_map_layout_node")
		if map_layout is Node:
			return map_layout
	return current_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")
