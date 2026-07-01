extends RefCounted
class_name BuildingUpgradeDeathReward

## Grants resources when specific units die, based on building upgrades.
## Called from building_upgrade_core when EventBus.hero_died fires.

# unit_id -> {building_id, upgrade_id, resource_id, amount}
const DEATH_REWARD_MAP: Dictionary = {
	"peasant": {"building_id": "peasants_hut", "upgrade_id": "peasants_hut:1", "resource_id": "gold", "amount": 2},
	"gnome": {"building_id": "gnome_dome", "upgrade_id": "gnome_dome:0", "resource_id": "gold", "amount": 5},
	"barbarian": {"building_id": "barbarian_tent", "upgrade_id": "barbarian_tent:0", "resource_id": "metal", "amount": 8},
}


static func get_death_reward(unit_id: String, has_upgrade_func: Callable) -> Dictionary:
	var entry: Variant = DEATH_REWARD_MAP.get(unit_id, {})
	if not (entry is Dictionary):
		return {}
	var reward := entry as Dictionary
	if reward.is_empty():
		return {}
	var building_id: String = reward.get("building_id", "")
	var upgrade_id: String = reward.get("upgrade_id", "")
	if building_id == "" or upgrade_id == "":
		return {}
	if not has_upgrade_func.call(building_id, upgrade_id):
		return {}
	return {"resource_id": String(reward.get("resource_id", "")), "amount": int(reward.get("amount", 0))}
