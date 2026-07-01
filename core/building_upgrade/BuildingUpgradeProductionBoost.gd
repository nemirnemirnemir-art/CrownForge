extends RefCounted
class_name BuildingUpgradeProductionBoost

## Returns the production speed multiplier for a building based on its upgrades.
## Called from MapSlotProduction during tick to adjust cycle time.

# Map of building_id -> {upgrade_id: multiplier}
const PRODUCTION_BOOST_MAP: Dictionary = {
	"vineyard": {"vineyard:1": 1.3},
	"market": {"market:1": 1.25},
	"sawmill": {"sawmill:0": 1.25},
	"clay_mine": {"clay_mine:1": 1.35},
	"crystal_mine": {"crystal_mine:1": 1.3},
	"gold_mine": {"gold_mine:1": 1.25},
	"iron_mine": {"iron_mine:1": 1.3},
	"wheat_field": {"wheat_field:0": 1.3},
	"animal_farm": {"animal_farm:0": 1.3},
	"fishermans_hut": {"fishermans_hut:0": 1.3},
	"fuel_pump": {"fuel_pump:0": 1.3},
	"winery": {"winery:0": 1.3},
}

const EFFICIENT_PROCESSING_MAP: Dictionary = {
	"forge": "forge:0",
	"mill": "mill:0",
}


static func get_production_multiplier(building_id: String, has_upgrade_func: Callable) -> float:
	var entry: Variant = PRODUCTION_BOOST_MAP.get(building_id, {})
	if not (entry is Dictionary):
		return 1.0
	var boost_map := entry as Dictionary
	var multiplier := 1.0
	for upgrade_id: String in boost_map:
		if has_upgrade_func.call(building_id, upgrade_id):
			multiplier *= float(boost_map[upgrade_id])
	return multiplier


static func get_efficient_processing_multiplier(building_id: String, has_upgrade_func: Callable) -> int:
	## Returns the amount multiplier for efficient processing upgrades.
	## 1 = normal, 2 = double input/output
	var upgrade_id: Variant = EFFICIENT_PROCESSING_MAP.get(building_id, "")
	if upgrade_id == "" or not (upgrade_id is String):
		return 1
	if has_upgrade_func.call(building_id, upgrade_id as String):
		return 2
	return 1
