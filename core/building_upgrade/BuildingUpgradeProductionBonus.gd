extends RefCounted
class_name BuildingUpgradeProductionBonus

## Handles bonus resource/effect hooks that fire on production cycle completion.
## Called from MapSlotProduction after a production cycle completes.

# Each entry: {upgrade_id, chance (0.0-1.0), resource_id, amount}
# Special entries use "effect" key instead of "resource_id"
const BONUS_MAP: Dictionary = {
	"gold_mine": [
		{"upgrade_id": "gold_mine:0", "chance": 0.5, "resource_id": "gold", "amount": 2},
	],
	"wheat_field": [
		{"upgrade_id": "wheat_field:1", "chance": 0.25, "resource_id": "gold", "amount": 1},
	],
	"fishermans_hut": [
		{"upgrade_id": "fishermans_hut:1", "chance": 0.5, "resource_id": "meat", "amount": 2},
	],
	"winery": [
		{"upgrade_id": "winery:1", "chance": 0.5, "resource_id": "wine", "amount": 1},
	],
	"fuel_pump": [
		{"upgrade_id": "fuel_pump:1", "chance": 0.2, "resource_id": "_random", "amount": 1},
	],
	"clay_mine": [
		{"upgrade_id": "clay_mine:0", "chance": 0.1, "effect": "repair_castle", "amount": 1},
	],
}

const ALL_RESOURCES: Array[String] = [
	"water", "gold", "wood", "clay", "iron_ore", "steel", "wheat", "flour",
	"meat", "grapes", "wine", "oil", "crystal"
]


static func process_production_bonuses(
	building_id: String,
	has_upgrade_func: Callable,
	add_resource_func: Callable,
	repair_castle_func: Callable
) -> Array[Dictionary]:
	## Returns array of bonus results for animation/popup purposes.
	## Each result: {"resource_id": String, "amount": int} or {"effect": String, "amount": int}
	var results: Array[Dictionary] = []
	var entries: Variant = BONUS_MAP.get(building_id, [])
	if not (entries is Array):
		return results
	for raw_entry: Variant in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry := raw_entry as Dictionary
		var upgrade_id := String(entry.get("upgrade_id", ""))
		if upgrade_id == "" or not has_upgrade_func.call(building_id, upgrade_id):
			continue
		var chance := float(entry.get("chance", 0.0))
		if randf() > chance:
			continue
		var amount := int(entry.get("amount", 0))
		if amount <= 0:
			continue
		var effect_key := String(entry.get("effect", ""))
		if effect_key == "repair_castle":
			repair_castle_func.call(amount)
			results.append({"effect": "repair_castle", "amount": amount})
			continue
		var resource_id := String(entry.get("resource_id", ""))
		if resource_id == "_random":
			resource_id = ALL_RESOURCES[randi() % ALL_RESOURCES.size()]
		if resource_id != "":
			add_resource_func.call(resource_id, amount)
			results.append({"resource_id": resource_id, "amount": amount})
	return results
