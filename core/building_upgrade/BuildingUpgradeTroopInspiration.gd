extends RefCounted
class_name BuildingUpgradeTroopInspiration

## Handles flat 10% troop class buffs from production buildings.
## Each buff is binary: either active (any building has the upgrade) or not.
## Does NOT stack per building count.

# Map: building_id -> {upgrade_id, troop_class_name}
# troop_class_name matches UnitConfig.UnitClass enum names
const INSPIRATION_MAP: Dictionary = {
	"iron_mine": {"upgrade_id": "iron_mine:0", "troop_class": "WARRIOR"},
	"animal_farm": {"upgrade_id": "animal_farm:1", "troop_class": "RIDER"},
	"forge": {"upgrade_id": "forge:1", "troop_class": "RANGED"},
	"mill": {"upgrade_id": "mill:1", "troop_class": "FLYING"},
	"execution_ground": {"upgrade_id": "execution_ground:1", "troop_class": "GRUNT"},
	"kings_statue": {"upgrade_id": "kings_statue:1", "troop_class": "CHAMPION"},
}

const INSPIRATION_BONUS: float = 0.10


static func get_active_inspirations(has_building_upgrade_func: Callable) -> Array[Dictionary]:
	## Returns list of active troop inspirations.
	## Each: {"troop_class": String, "bonus": float}
	var results: Array[Dictionary] = []
	for building_id: String in INSPIRATION_MAP:
		var entry: Dictionary = INSPIRATION_MAP[building_id]
		var upgrade_id := String(entry.get("upgrade_id", ""))
		if upgrade_id == "":
			continue
		if not has_building_upgrade_func.call(building_id, upgrade_id):
			continue
		results.append({
			"troop_class": String(entry.get("troop_class", "")),
			"bonus": INSPIRATION_BONUS,
		})
	return results


static func get_troop_class_damage_multiplier(troop_class_name: String, has_building_upgrade_func: Callable) -> float:
	## Returns the damage multiplier for a specific troop class based on active inspirations.
	for building_id: String in INSPIRATION_MAP:
		var entry: Dictionary = INSPIRATION_MAP[building_id]
		if String(entry.get("troop_class", "")) != troop_class_name:
			continue
		var upgrade_id := String(entry.get("upgrade_id", ""))
		if upgrade_id != "" and has_building_upgrade_func.call(building_id, upgrade_id):
			return 1.0 + INSPIRATION_BONUS
	return 1.0


static func get_troop_class_hp_multiplier(troop_class_name: String, has_building_upgrade_func: Callable) -> float:
	## Returns the HP multiplier for a specific troop class based on active inspirations.
	return get_troop_class_damage_multiplier(troop_class_name, has_building_upgrade_func)
