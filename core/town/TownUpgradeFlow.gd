extends RefCounted
class_name TownUpgradeFlow


func try_upgrade_building(buildings, bonuses, perks, building_id: String, emit_building_upgraded: Callable) -> bool:
	if not buildings.try_upgrade_building(building_id):
		return false
	bonuses.invalidate_cache()
	var level: int = buildings.get_building_level(building_id)
	perks.check_unlocked_perks(building_id, level)
	if emit_building_upgraded.is_valid():
		emit_building_upgraded.call(building_id, level)
	return true


func debug_set_building_level(buildings, bonuses, perks, building_id: String, target_level: int, emit_building_upgraded: Callable, save_core = null) -> bool:
	if buildings == null:
		return false
	if target_level < 0:
		target_level = 0
	var current_level: int = buildings.get_building_level(building_id)
	if current_level == 0 and not buildings.get_buildings().has(building_id):
		return false
	if current_level == target_level:
		if save_core and save_core.has_method("request_save"):
			save_core.request_save()
		return true
	buildings.set_building_level(building_id, target_level)
	bonuses.invalidate_cache()
	perks.check_unlocked_perks(building_id, target_level)
	if emit_building_upgraded.is_valid():
		emit_building_upgraded.call(building_id, target_level)
	if save_core and save_core.has_method("request_save"):
		save_core.request_save()
	return true
