extends RefCounted
class_name ArtifactBuildingLifecycleBonuses

const IRON_HOE_ID := "iron_hoe"
const STARTER_RESOURCE_BUILDING_IDS := {
	"well": true,
	"tree": true,
	"grape_bushes": true,
	"small_wheat_field": true,
	"starter_clay_mine": true,
	"starter_crystal_mine": true,
	"starter_gold_mine": true,
	"starter_iron_mine": true,
}
const STARTER_MILITARY_BUILDING_IDS := {
	"small_peasants_hut": true,
}


func get_resource_building_durability(active: Dictionary, building_config: Variant, base_durability: int) -> int:
	var safe_base: int = max(-1, base_durability)
	if safe_base <= 0:
		return safe_base
	if not _has_iron_hoe(active):
		return safe_base
	if not _is_starter_resource_building(building_config):
		return safe_base
	return safe_base * 2


func get_military_building_unit_limit(active: Dictionary, building_config: Variant, base_limit: int) -> int:
	var safe_base: int = max(0, base_limit)
	if safe_base <= 0:
		return safe_base
	if not _has_iron_hoe(active):
		return safe_base
	if not _is_starter_military_building(building_config):
		return safe_base
	return safe_base * 2


func _has_iron_hoe(active: Dictionary) -> bool:
	if active.has(IRON_HOE_ID):
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("is_active"):
		return false
	return bool(artifact_core.call("is_active", IRON_HOE_ID))


func _is_starter_resource_building(building_config: Variant) -> bool:
	if _resolve_building_type(building_config) != int(BuildingConfig.BuildingType.RESOURCE):
		return false
	return STARTER_RESOURCE_BUILDING_IDS.has(_resolve_building_id(building_config))


func _is_starter_military_building(building_config: Variant) -> bool:
	if _resolve_building_type(building_config) != int(BuildingConfig.BuildingType.MILITARY):
		return false
	return STARTER_MILITARY_BUILDING_IDS.has(_resolve_building_id(building_config))


func _resolve_building_id(building_config: Variant) -> String:
	if building_config is BuildingConfig:
		return String((building_config as BuildingConfig).building_id).strip_edges().to_lower()
	if building_config is Dictionary:
		return String((building_config as Dictionary).get("building_id", "")).strip_edges().to_lower()
	if building_config != null:
		var raw_building_id: Variant = building_config.get("building_id")
		if raw_building_id != null:
			return String(raw_building_id).strip_edges().to_lower()
	return ""


func _resolve_building_type(building_config: Variant) -> int:
	if building_config is BuildingConfig:
		return int((building_config as BuildingConfig).building_type)
	if building_config is Dictionary:
		return int((building_config as Dictionary).get("building_type", -1))
	if building_config != null:
		var raw_building_type: Variant = building_config.get("building_type")
		if raw_building_type != null:
			return int(raw_building_type)
	return -1
