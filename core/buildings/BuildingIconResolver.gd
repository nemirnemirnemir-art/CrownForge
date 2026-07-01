extends RefCounted
class_name BuildingIconResolver

const ICONS_DIR := "res://assets/environment/buildings"

var _icon_path_by_key: Dictionary = {}
var _icons_scanned: bool = false


func scan_building_icons() -> Dictionary:
	if _icons_scanned:
		return _icon_path_by_key.duplicate(true)

	_icons_scanned = true
	_icon_path_by_key.clear()

	var dir := DirAccess.open(ICONS_DIR)
	if dir == null:
		return _icon_path_by_key.duplicate(true)

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var lower := file_name.to_lower()
			if lower.ends_with(".png") or lower.ends_with(".webp") or lower.ends_with(".jpg") or lower.ends_with(".jpeg"):
				var base := file_name.get_basename()
				var key := normalize_key(base)
				if key != "":
					_icon_path_by_key[key] = "%s/%s" % [ICONS_DIR, file_name]
		file_name = dir.get_next()
	dir.list_dir_end()

	return _icon_path_by_key.duplicate(true)


func normalize_key(value: String) -> String:
	var key := value.strip_edges().to_lower()
	key = key.replace(" ", "_")
	key = key.replace("-", "_")
	while key.find("__") != -1:
		key = key.replace("__", "_")
	return key


func try_assign_icon_if_missing(config: BuildingConfig, icon_path_by_key: Dictionary = {}) -> void:
	if config == null:
		return
	if config.icon != null:
		return

	var resolved_lookup := icon_path_by_key
	if resolved_lookup.is_empty():
		resolved_lookup = scan_building_icons()
	if resolved_lookup.is_empty():
		return

	var id_key := normalize_key(config.building_id)
	var name_key := normalize_key(config.display_name)

	var path := ""
	if id_key != "" and resolved_lookup.has(id_key):
		path = String(resolved_lookup[id_key])
	elif name_key != "" and resolved_lookup.has(name_key):
		path = String(resolved_lookup[name_key])

	if path == "":
		return

	var texture := load(path)
	if texture is Texture2D:
		config.icon = texture
