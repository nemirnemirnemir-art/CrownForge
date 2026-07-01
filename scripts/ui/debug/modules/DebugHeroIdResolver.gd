extends RefCounted
class_name DebugHeroIdResolver

## Collects and normalizes hero IDs from barracks building configs
## and an optional extra-heroes list.

const BuildingConfigScript = preload("res://core/buildings/BuildingConfig.gd")
const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

func get_hero_ids(barracks_dirs: Array[String], extra_ids: Array[String]) -> Array[String]:
	var hero_ids: Array[String] = []
	var seen: Dictionary = {}
	for unit_id in _collect_units_from_barracks(barracks_dirs):
		var normalized := HeroSceneRegistryScript.resolve_unit_id(String(unit_id))
		if normalized == "" or normalized == "heroonfield":
			continue
		if seen.has(normalized) or not HeroSceneRegistryScript.has_scene(normalized):
			continue
		seen[normalized] = true
		hero_ids.append(normalized)
	for extra_id in extra_ids:
		var normalized := HeroSceneRegistryScript.resolve_unit_id(String(extra_id))
		if normalized == "" or seen.has(normalized):
			continue
		if not HeroSceneRegistryScript.has_scene(normalized):
			continue
		seen[normalized] = true
		hero_ids.append(normalized)
	hero_ids.sort()
	return hero_ids

func build_hero_scene_map(hero_ids: Array[String]) -> Dictionary:
	var map: Dictionary = {}
	for unit_id in hero_ids:
		var scene := HeroSceneRegistryScript.load_scene(unit_id)
		if scene != null:
			map[unit_id] = scene
	return map

func _collect_units_from_barracks(barracks_dirs: Array[String]) -> Array[String]:
	var unit_ids: Array[String] = []
	for dir_path in barracks_dirs:
		_append_units_from_dir(unit_ids, dir_path)
	return unit_ids

func _append_units_from_dir(unit_ids: Array[String], dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".tres"):
			var resource_path := "%s/%s" % [dir_path, file_name]
			var cfg := load(resource_path) as BuildingConfig
			if cfg != null and cfg.building_type == BuildingConfigScript.BuildingType.MILITARY:
				var unit_id := HeroSceneRegistryScript.resolve_unit_id(String(cfg.produced_unit_id))
				if unit_id != "" and not unit_ids.has(unit_id):
					unit_ids.append(unit_id)
		file_name = dir.get_next()
	dir.list_dir_end()
