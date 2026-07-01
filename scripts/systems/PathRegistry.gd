class_name PathRegistry
extends RefCounted

const CANON_RESOURCE_ICON_DIR := "res://assets/items/resources/icons"
const LEGACY_RESOURCE_ICON_DIR := "res://assets/items/resources"
const CANON_SPELL_CONFIG_DIR := "res://resources/spells/configs"
const LEGACY_SPELL_CONFIG_DIR := "res://data/spells/configs"
const CANON_UNIT_CONFIG_DIR := "res://data/units"
const LEGACY_UNIT_CONFIG_DIR := "res://resources/units/configs"
const RESOURCE_ICON_ALIASES := {}

const UNIT_CONFIG_ALIASES := {
	"small": "small_bones",
	"smallbones": "small_bones",
}


static func get_resource_icon_dirs() -> Array[String]:
	var dirs: Array[String] = []
	if DirAccess.open(CANON_RESOURCE_ICON_DIR) != null:
		dirs.append(CANON_RESOURCE_ICON_DIR)
	if DirAccess.open(LEGACY_RESOURCE_ICON_DIR) != null:
		dirs.append(LEGACY_RESOURCE_ICON_DIR)
	return dirs


static func get_spell_config_dirs() -> Array[String]:
	var dirs: Array[String] = []
	if DirAccess.open(CANON_SPELL_CONFIG_DIR) != null:
		dirs.append(CANON_SPELL_CONFIG_DIR)
	if DirAccess.open(LEGACY_SPELL_CONFIG_DIR) != null:
		dirs.append(LEGACY_SPELL_CONFIG_DIR)
	return dirs


static func get_unit_config_dirs() -> Array[String]:
	var dirs: Array[String] = []
	if DirAccess.open(CANON_UNIT_CONFIG_DIR) != null:
		dirs.append(CANON_UNIT_CONFIG_DIR)
	if DirAccess.open(LEGACY_UNIT_CONFIG_DIR) != null:
		dirs.append(LEGACY_UNIT_CONFIG_DIR)
	return dirs


static func resolve_resource_icon_path(resource_id: String, file_map: Dictionary = {}) -> String:
	var normalized_id := String(resource_id).strip_edges().to_lower()
	if normalized_id == "":
		return ""

	var file_base := String(file_map.get(normalized_id, normalized_id)).strip_edges().to_lower()
	if file_base != "":
		var exact_path := _resolve_exact_png(file_base)
		if exact_path != "":
			return exact_path

	if file_base != normalized_id:
		var exact_by_id := _resolve_exact_png(normalized_id)
		if exact_by_id != "":
			return exact_by_id

	var alias_base := String(RESOURCE_ICON_ALIASES.get(normalized_id, "")).strip_edges().to_lower()
	if alias_base != "":
		var exact_by_alias := _resolve_exact_png(alias_base)
		if exact_by_alias != "":
			return exact_by_alias

	return _resolve_fuzzy_png(normalized_id)


static func load_resource_icon(resource_id: String, file_map: Dictionary = {}) -> Texture2D:
	var path := resolve_resource_icon_path(resource_id, file_map)
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func resolve_spell_config_path(spell_id: String) -> String:
	var normalized_id := String(spell_id).strip_edges().to_lower()
	if normalized_id == "":
		return ""

	for dir_path in get_spell_config_dirs():
		var path := "%s/%s.tres" % [dir_path, normalized_id]
		if ResourceLoader.exists(path):
			return path

	return ""


static func spell_config_exists(spell_id: String) -> bool:
	return resolve_spell_config_path(spell_id) != ""


static func load_spell_config(spell_id: String) -> Resource:
	var path := resolve_spell_config_path(spell_id)
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Resource


static func list_spell_config_ids(legendary_only: bool) -> Array[String]:
	var ids: Array[String] = []
	var seen: Dictionary = {}

	for dir_path in get_spell_config_dirs():
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var spell_id := file_name.trim_suffix(".tres")
				var is_legendary := spell_id.begins_with("legendary_")
				if legendary_only and not is_legendary:
					file_name = dir.get_next()
					continue
				if (not legendary_only) and is_legendary:
					file_name = dir.get_next()
					continue
				if not seen.has(spell_id):
					seen[spell_id] = true
					ids.append(spell_id)
			file_name = dir.get_next()
		dir.list_dir_end()

	ids.sort()
	return ids


static func resolve_unit_config_path(unit_id: String) -> String:
	var normalized_id := String(unit_id).strip_edges().to_lower()
	if normalized_id == "":
		return ""

	for candidate_id in _build_unit_id_candidates(normalized_id):
		for dir_path in get_unit_config_dirs():
			var path := "%s/%s.tres" % [dir_path, candidate_id]
			if ResourceLoader.exists(path):
				return path

	return ""


static func unit_config_exists(unit_id: String) -> bool:
	return resolve_unit_config_path(unit_id) != ""


static func load_unit_config(unit_id: String) -> Resource:
	var path := resolve_unit_config_path(unit_id)
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Resource


static func _resolve_exact_png(file_base: String) -> String:
	for dir_path in get_resource_icon_dirs():
		var exact_path := "%s/%s.png" % [dir_path, file_base]
		if ResourceLoader.exists(exact_path):
			return exact_path
	return ""


static func _resolve_fuzzy_png(resource_id: String) -> String:
	for dir_path in get_resource_icon_dirs():
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
				var lower_name := file_name.to_lower()
				if lower_name.begins_with(resource_id + "_") or lower_name == resource_id + ".png":
					dir.list_dir_end()
					return "%s/%s" % [dir_path, file_name]
			file_name = dir.get_next()
		dir.list_dir_end()

	return ""


static func _build_unit_id_candidates(normalized_id: String) -> Array[String]:
	var candidates: Array[String] = []
	var canonical_id := _resolve_unit_config_alias(normalized_id)
	_append_unique_string(candidates, canonical_id)
	_append_unique_string(candidates, normalized_id)

	if normalized_id.contains("_"):
		var parts := normalized_id.split("_", false)
		if not parts.is_empty():
			var prefix := String(parts[0]).strip_edges()
			if prefix != "":
				var canonical_prefix := _resolve_unit_config_alias(prefix)
				_append_unique_string(candidates, canonical_prefix)
				_append_unique_string(candidates, prefix)

	return candidates


static func _resolve_unit_config_alias(unit_id: String) -> String:
	return String(UNIT_CONFIG_ALIASES.get(unit_id, unit_id))


static func _append_unique_string(target: Array[String], value: String) -> void:
	if value == "":
		return
	if target.has(value):
		return
	target.append(value)
