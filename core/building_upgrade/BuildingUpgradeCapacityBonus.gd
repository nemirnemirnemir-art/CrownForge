extends RefCounted
class_name BuildingUpgradeCapacityBonus

## Returns the capacity bonus for a military building based on its upgrades.
## Called from MapSlotProduction and MapSlotMilitaryTracker to adjust max_units.

# Map of building_id -> {upgrade_id: bonus}
const CAPACITY_BONUS_MAP: Dictionary = {
	"peasants_hut": {"peasants_hut:0": 2},
	"archery": {"archery:1": 2},
	"gnome_dome": {"gnome_dome:2": 5},
	"hunters": {"hunters:1": 2},
	"madhouse": {"madhouse:1": 2},
	"militia_camp": {"militia_camp:1": 2},
	"slingers_tree": {"slingers_tree:0": 3},
	"swordsmen_barracks": {"swordsmen_barracks:1": 2},
	"whipmens_house": {"whipmens_house:0": 2},
	"academy_of_fire": {"academy_of_fire:2": 2},
	"academy_of_nature": {"academy_of_nature:0": 1},
	"firing_range": {"firing_range:1": 2},
	"geese_training_field": {"geese_training_field:0": 1},
	"hive": {"hive:0": 2},
	"longbowmens_camp": {"longbowmens_camp:2": 2},
	"paladins_campus": {"paladins_campus:0": 2},
	"pumpkin_field": {"pumpkin_field:0": 3},
	"stables": {"stables:1": 1},
	"ballista_factory": {"ballista_factory:1": 1},
	"catapult_factory": {"catapult_factory:0": 1},
	"hydra_pond": {"hydra_pond:1": 1},
	"academy_of_lightning": {"academy_of_lightning:0": 2},
}


static func get_capacity_bonus(building_id: String, has_upgrade_func: Callable) -> int:
	var entry: Variant = CAPACITY_BONUS_MAP.get(building_id, {})
	if not (entry is Dictionary):
		return 0
	var bonus_map := entry as Dictionary
	var bonus := 0
	for upgrade_id: String in bonus_map:
		if has_upgrade_func.call(building_id, upgrade_id):
			bonus += int(bonus_map[upgrade_id])
	return bonus
