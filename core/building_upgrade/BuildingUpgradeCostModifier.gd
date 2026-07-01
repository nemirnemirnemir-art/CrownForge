## BuildingUpgradeCostModifier
## Provides production cost multipliers for military buildings.
##
## Design: Cost upgrades modify the consumes resource amounts
## per production cycle. The modifier is expressed as a multiplier
## applied to each consume entry's amount (rounded up via ceili, min 1).
##
## Discounts (<1.0):
##   barbarian_tent:1  → 50% cheaper  (multiplier 0.5)
##   firing_range:2    → 40% cheaper  (multiplier 0.6)
##   geese_training_field:2 → 50% cheaper (multiplier 0.5)
##
## Cost increases (>1.0) are applied by the caller (e.g. lion_circus versatility x2.0).

const COST_DISCOUNT_MAP: Dictionary = {
	"barbarian_tent": {"upgrade_id": "barbarian_tent:1", "multiplier": 0.5},
	"firing_range": {"upgrade_id": "firing_range:2", "multiplier": 0.6},
	"geese_training_field": {"upgrade_id": "geese_training_field:2", "multiplier": 0.5},
}


## Returns the cost multiplier for a building's production consumes.
## 1.0 = full price (no discount), <1.0 = discounted.
static func get_cost_multiplier(building_id: String, has_upgrade_func: Callable) -> float:
	if not COST_DISCOUNT_MAP.has(building_id):
		return 1.0
	var entry: Dictionary = COST_DISCOUNT_MAP[building_id]
	var upgrade_id: String = entry.get("upgrade_id", "")
	if upgrade_id == "" or not has_upgrade_func.is_valid():
		return 1.0
	if has_upgrade_func.call(building_id, upgrade_id):
		return float(entry.get("multiplier", 1.0))
	return 1.0


## Checks whether the building can afford production at the (possibly discounted) cost.
## Mirrors BuildingConfig.can_produce() but applies the discount multiplier.
static func can_produce_discounted(consumes: Array, cost_multiplier: float, resource_core: Node) -> bool:
	if resource_core == null:
		return false
	for consume in consumes:
		if consume == null:
			continue
		var discounted_amount: int = _apply_discount(int(consume.amount), cost_multiplier)
		var current: int = int(resource_core.call("get_resource", consume.resource_id))
		if current < discounted_amount:
			return false
	return true


## Consumes resources at the (possibly discounted) cost.
## Mirrors BuildingConfig.consume_inputs() but applies the discount multiplier.
static func consume_inputs_discounted(consumes: Array, cost_multiplier: float, resource_core: Node) -> void:
	if resource_core == null:
		return
	for consume in consumes:
		if consume == null:
			continue
		var discounted_amount: int = _apply_discount(int(consume.amount), cost_multiplier)
		if discounted_amount > 0:
			resource_core.call("consume_resource", consume.resource_id, discounted_amount)


## Apply cost modifier: multiply amount by multiplier, round up to at least 1.
static func _apply_discount(base_amount: int, multiplier: float) -> int:
	if is_equal_approx(multiplier, 1.0):
		return base_amount
	var result: int = ceili(float(base_amount) * multiplier)
	return maxi(result, 1)
