extends RefCounted
class_name SpellUpgradeService

const MAX_ACTIVE_UPGRADE_LEVEL := 4
const ACTIVE_UPGRADE_COSTS := [
	{"gold": 250},
	{"crystal": 150, "clay": 150, "grapes": 100, "wine": 100},
	{"flour": 200, "metal": 200},
	{"meat": 250, "fuel": 150},
]


func get_max_active_upgrade_level() -> int:
	return MAX_ACTIVE_UPGRADE_LEVEL


func get_active_upgrade_costs() -> Array:
	return ACTIVE_UPGRADE_COSTS.duplicate(true)


func can_upgrade_active_spells(active_upgrade_level: int, max_active_upgrade_level: int) -> bool:
	return active_upgrade_level < max_active_upgrade_level


func get_next_upgrade_cost(active_upgrade_level: int, max_active_upgrade_level: int, active_upgrade_costs: Array) -> Dictionary:
	if not can_upgrade_active_spells(active_upgrade_level, max_active_upgrade_level):
		return {}
	return (active_upgrade_costs[active_upgrade_level] as Dictionary).duplicate(true)


func try_purchase_active_upgrade(active_upgrade_level: int, max_active_upgrade_level: int, active_upgrade_costs: Array, economy_core: Variant, resource_core: Variant) -> Dictionary:
	var cost := get_next_upgrade_cost(active_upgrade_level, max_active_upgrade_level, active_upgrade_costs)
	if cost.is_empty():
		return {
			"purchased": false,
			"next_level": active_upgrade_level,
		}
	if not _can_afford_upgrade_cost(cost, economy_core, resource_core):
		return {
			"purchased": false,
			"next_level": active_upgrade_level,
		}
	var spent_costs := _spend_upgrade_cost(cost, economy_core, resource_core)
	if spent_costs.size() != cost.size():
		_rollback_spent_costs(spent_costs, economy_core, resource_core)
		return {
			"purchased": false,
			"next_level": active_upgrade_level,
		}
	return {
		"purchased": true,
		"next_level": active_upgrade_level + 1,
	}


func _can_afford_upgrade_cost(cost: Dictionary, economy_core: Variant, resource_core: Variant) -> bool:
	for resource_id_variant in cost.keys():
		var resource_id := String(resource_id_variant)
		var amount := int(cost.get(resource_id, 0))
		if resource_id == "gold":
			if economy_core == null or not economy_core.can_afford(float(amount)):
				return false
		elif resource_core == null or resource_core.get_resource(resource_id) < amount:
			return false
	return true


func _spend_upgrade_cost(cost: Dictionary, economy_core: Variant, resource_core: Variant) -> Array[Dictionary]:
	var spent_costs: Array[Dictionary] = []
	for resource_id_variant in cost.keys():
		var resource_id := String(resource_id_variant)
		var amount := int(cost.get(resource_id, 0))
		var spent := false
		if resource_id == "gold":
			spent = economy_core != null and economy_core.spend_gold(float(amount))
		else:
			spent = resource_core != null and resource_core.consume_resource(resource_id, amount)
		if not spent:
			break
		spent_costs.append({
			"resource_id": resource_id,
			"amount": amount,
		})
	return spent_costs


func _rollback_spent_costs(spent_costs: Array[Dictionary], economy_core: Variant, resource_core: Variant) -> void:
	for index in range(spent_costs.size() - 1, -1, -1):
		var spent_cost := spent_costs[index]
		var resource_id := String(spent_cost.get("resource_id", ""))
		var amount := int(spent_cost.get("amount", 0))
		if amount <= 0:
			continue
		if resource_id == "gold":
			if economy_core != null and economy_core.has_method("add_gold"):
				economy_core.add_gold(float(amount))
		elif resource_core != null and resource_core.has_method("add_resource"):
			resource_core.add_resource(resource_id, amount)
