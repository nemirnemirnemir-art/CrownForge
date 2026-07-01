extends RefCounted
class_name BuildingUpgradeRegistryFlow


func normalize_building_id(building_id: String) -> String:
	return String(building_id).strip_edges().to_lower()


func extract_building_id_from_upgrade(upgrade_id: String) -> String:
	var normalized := String(upgrade_id).strip_edges().to_lower()
	if normalized == "":
		return ""
	var parts := normalized.split(":", false, 1)
	if parts.is_empty():
		return ""
	return normalize_building_id(String(parts[0]))


func stringify_upgrade_array(raw: Variant) -> Array[String]:
	var arr: Array[String] = []
	if raw is Array:
		for value in raw:
			var text := String(value).strip_edges().to_lower()
			if text != "" and not arr.has(text):
				arr.append(text)
	return arr


func get_building_upgrades(state: Dictionary, building_id: String) -> Array[String]:
	var key := normalize_building_id(building_id)
	return stringify_upgrade_array(state.get(key, []))


func has_building_upgrade(state: Dictionary, building_id: String, upgrade_id: String) -> bool:
	var target_building_id := normalize_building_id(building_id)
	if target_building_id == "":
		target_building_id = extract_building_id_from_upgrade(upgrade_id)
	if target_building_id == "":
		return false
	var normalized_upgrade_id := String(upgrade_id).strip_edges().to_lower()
	if normalized_upgrade_id == "":
		return false
	return get_building_upgrades(state, target_building_id).has(normalized_upgrade_id)


func unlock_building_upgrade(state: Dictionary, building_id: String, upgrade_id: String, emit_changed: Callable, request_save: Callable) -> void:
	var target_building_id := normalize_building_id(building_id)
	if target_building_id == "":
		target_building_id = extract_building_id_from_upgrade(upgrade_id)
	var normalized_upgrade_id := String(upgrade_id).strip_edges().to_lower()
	if target_building_id == "" or normalized_upgrade_id == "":
		return
	var arr := get_building_upgrades(state, target_building_id)
	var changed := false
	if not arr.has(normalized_upgrade_id):
		arr.append(normalized_upgrade_id)
		changed = true
	state[target_building_id] = arr
	if changed:
		if emit_changed.is_valid():
			emit_changed.call(target_building_id, mini(arr.size(), 3))
		if request_save.is_valid():
			request_save.call()


func get_save_data(api_version: int, state: Dictionary) -> Dictionary:
	return {"api_version": api_version, "unlocked_by_building": state.duplicate(true)}


func load_save_data(data: Dictionary) -> Dictionary:
	var state: Dictionary = {}
	var raw_global: Variant = data.get("unlocked_by_building", null)
	if raw_global is Dictionary:
		for building_id_value in (raw_global as Dictionary).keys():
			var building_id := normalize_building_id(String(building_id_value))
			if building_id == "":
				continue
			var arr := stringify_upgrade_array((raw_global as Dictionary)[building_id_value])
			if not arr.is_empty():
				state[building_id] = arr
		if not state.is_empty() or not data.has("upgrades_by_slot"):
			return state
	var raw_slot_data: Variant = data.get("upgrades_by_slot", {})
	if raw_slot_data is Dictionary:
		for upgrades_value in (raw_slot_data as Dictionary).values():
			var arr := stringify_upgrade_array(upgrades_value)
			for upgrade_id in arr:
				var building_id := extract_building_id_from_upgrade(upgrade_id)
				if building_id == "":
					continue
				var building_arr := get_building_upgrades(state, building_id)
				if not building_arr.has(upgrade_id):
					building_arr.append(upgrade_id)
				state[building_id] = building_arr
	return state
