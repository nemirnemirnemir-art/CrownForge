extends Resource
class_name BuildingUpgradeData

const BuildingPresentationDataScript := preload("res://scripts/ui/town/buildings/BuildingPresentationData.gd")
const BuildingUpgradeIconResolverScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd")
const UPGRADES := BuildingPresentationDataScript.DATA

static func get_upgrades(building_id: String) -> Array:
	return BuildingPresentationDataScript.get_upgrades(building_id)

static func has_upgrades(building_id: String) -> bool:
	return BuildingPresentationDataScript.has_upgrades(building_id)

static func get_upgrade_icon(building_id: String, upgrade_index: int) -> Texture2D:
	return BuildingUpgradeIconResolverScript.get_icon(building_id, upgrade_index)

static func has_upgrade_icon(building_id: String, upgrade_index: int) -> bool:
	return BuildingUpgradeIconResolverScript.has_icon(building_id, upgrade_index)
