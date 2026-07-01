extends RefCounted
class_name DebugBuildingUpgradesModule

## Debug module for bulk-unlocking building upgrades.
## Only works in debug mode (not release_mode_enabled).
## Hotkeys: E = unlock available, R = unlock all in game

const BuildingPresentationDataScript = preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")

var _buildings_core: Node = null
var _unlocked_count: int = 0
var _buildings_processed: Dictionary = {}


func setup(buildings_core: Node) -> void:
	if not buildings_core:
		push_error("[DebugBuildingUpgradesModule] buildings_core is null")
		return
	_buildings_core = buildings_core


## Unlock all UNAVAILABLE upgrades (E key)
## - Recipes: buildings player has but hasn't built yet
## - Built: buildings on map that don't have all upgrades yet
func unlock_all_available_upgrades() -> void:
	if not _buildings_core:
		print("[DebugBuildingUpgrades] ERROR: buildings_core not initialized")
		return
	
	_unlocked_count = 0
	_buildings_processed.clear()
	
	# Get all building IDs from the canonical source
	var all_building_ids: Array[String] = _get_all_building_ids()
	
	for building_id in all_building_ids:
		_unlock_available_upgrades_for_building(building_id)
	
	_log_results("AVAILABLE UPGRADES", all_building_ids.size())


## Unlock ALL upgrades in game (R key) - ~193 upgrades
## Unlocks every possible upgrade for every building, regardless of state
func unlock_all_upgrades_in_game() -> void:
	if not _buildings_core:
		print("[DebugBuildingUpgrades] ERROR: buildings_core not initialized")
		return
	
	_unlocked_count = 0
	_buildings_processed.clear()
	
	# Get building presentation data (canonical list of all buildings)
	var building_catalog: Dictionary = _get_building_presentation_data()
	
	for building_id in building_catalog.keys():
		_unlock_all_upgrades_for_building(building_id)
	
	_log_results("ALL UPGRADES IN GAME", building_catalog.size())


# --- PRIVATE HELPERS ---

func _get_all_building_ids() -> Array[String]:
	## Get union of:
	## 1. Player inventory (recipes)
	## 2. Built buildings on map
	## For now, return all buildings from presentation data
	var result: Array[String] = []
	var catalog: Dictionary = _get_building_presentation_data()
	for bid in catalog.keys():
		result.append(bid)
	return result


func _get_building_presentation_data() -> Dictionary:
	## Get canonical building list from BuildingPresentationData
	## Returns dict with building_id as key
	var catalog: Dictionary = {}
	
	# Access the DATA constant from BuildingPresentationData
	var data_const: Dictionary = BuildingPresentationDataScript.DATA if BuildingPresentationDataScript.DATA else {}
	
	for building_id: String in data_const.keys():
		catalog[building_id] = data_const[building_id]
	
	return catalog


func _unlock_available_upgrades_for_building(building_id: String) -> void:
	## Unlock only the upgrades that don't exist yet for this building
	var catalog: Dictionary = _get_building_presentation_data()
	var building_data: Variant = catalog.get(building_id)
	
	if building_data == null:
		return
	
	var upgrades: Variant = building_data.get("upgrades", []) if building_data is Dictionary else []
	if upgrades.is_empty():
		return
	
	_buildings_processed[building_id] = {
		"count": 0,
		"upgrades": []
	}
	
	# Unlock each upgrade level that hasn't been unlocked yet
	for upgrade_index: int in range(upgrades.size() if upgrades is Array else 0):
		var upgrade_id: String = "%s:%d" % [building_id, upgrade_index]
		
		# Only unlock if not already unlocked
		if not _buildings_core.has_building_upgrade(building_id, upgrade_id):
			_buildings_core.unlock_building_upgrade(building_id, upgrade_id)
			_unlocked_count += 1
			_buildings_processed[building_id]["upgrades"].append(upgrade_id)
			_buildings_processed[building_id]["count"] += 1


func _unlock_all_upgrades_for_building(building_id: String) -> void:
	## Unlock ALL upgrade levels for this building (even if already unlocked)
	var catalog: Dictionary = _get_building_presentation_data()
	var building_data: Variant = catalog.get(building_id)
	
	if building_data == null:
		return
	
	var upgrades: Variant = building_data.get("upgrades", []) if building_data is Dictionary else []
	if upgrades.is_empty():
		return
	
	_buildings_processed[building_id] = {
		"count": 0,
		"upgrades": []
	}
	
	# Unlock every upgrade level unconditionally
	for upgrade_index: int in range(upgrades.size() if upgrades is Array else 0):
		var upgrade_id: String = "%s:%d" % [building_id, upgrade_index]
		
		# Check if not already unlocked before incrementing counter
		if not _buildings_core.has_building_upgrade(building_id, upgrade_id):
			_buildings_core.unlock_building_upgrade(building_id, upgrade_id)
			_unlocked_count += 1
		
		_buildings_processed[building_id]["upgrades"].append(upgrade_id)
		_buildings_processed[building_id]["count"] += 1


func _log_results(mode_label: String, building_count: int) -> void:
	## Pretty print results to console
	var sep: String = "=".repeat(70)
	print("\n" + sep)
	print("[DebugBuildingUpgrades] %s UNLOCKED" % mode_label)
	print(sep)
	print("Total buildings processed: %d" % building_count)
	print("Total upgrades unlocked: %d" % _unlocked_count)
	print()
	
	# Print per-building details (only if any upgrades were unlocked)
	var details_printed: int = 0
	for building_id: String in _buildings_processed.keys():
		var data: Dictionary = _buildings_processed[building_id]
		if data["count"] > 0:
			var upgrades_str: String = ", ".join(data["upgrades"] as Array[String])
			print("  %-30s: %d upgrades (%s)" % [building_id, data["count"], upgrades_str])
			details_printed += 1
	
	if details_printed == 0:
		print("  (no new upgrades to unlock)")
	
	print(sep + "\n")
