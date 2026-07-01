extends RefCounted
class_name BuildingUpgradeSlotQuery


func normalize_building_id(building_id: String) -> String:
	return String(building_id).strip_edges().to_lower()


func get_slot_by_index(slots: Array, slot_index: int) -> Node:
	if slot_index < 0:
		return null
	for slot in slots:
		if slot == null:
			continue
		var raw_slot_index: Variant = slot.get("slot_index")
		if raw_slot_index == null:
			continue
		if int(raw_slot_index) == slot_index:
			return slot
	return null


func get_slot_building_id(slots: Array, slot_index: int) -> String:
	var slot := get_slot_by_index(slots, slot_index)
	if slot == null:
		return ""
	var raw_building_id: Variant = slot.get("current_building_id")
	if raw_building_id == null:
		return ""
	return normalize_building_id(String(raw_building_id))


func is_slot_building(slot, building_id: String) -> bool:
	if slot == null:
		return false
	if not (slot is Object):
		return false
	var raw_building_id: Variant = slot.get("current_building_id")
	if raw_building_id == null:
		return false
	return normalize_building_id(String(raw_building_id)) == normalize_building_id(building_id)


func is_slot_effectively_vzor_active(slot) -> bool:
	if slot == null:
		return false
	if not (slot is Object):
		return false
	if slot.has_method("is_effectively_vzor_active"):
		return bool(slot.call("is_effectively_vzor_active"))
	return false


func get_slot_special_handler(slot) -> RefCounted:
	if slot == null:
		return null
	if not (slot is Object):
		return null
	if slot.has_method("get_special_handler"):
		var raw_handler: Variant = slot.call("get_special_handler")
		if raw_handler is RefCounted:
			return raw_handler as RefCounted
	return null


func count_built_buildings(slots: Array, building_id: String) -> int:
	var target_id := normalize_building_id(building_id)
	var count := 0
	for slot in slots:
		if is_slot_building(slot, target_id):
			count += 1
	return count


func count_active_buildings(slots: Array, building_id: String) -> int:
	var target_id := normalize_building_id(building_id)
	var count := 0
	for slot in slots:
		if not is_slot_building(slot, target_id):
			continue
		if not is_slot_effectively_vzor_active(slot):
			continue
		count += 1
	return count


func get_active_hospital_morale_bonus(slots: Array) -> int:
	var total := 0
	for slot in slots:
		if not is_slot_building(slot, "hospital"):
			continue
		var handler := get_slot_special_handler(slot)
		if handler == null or not handler.has_method("get_morale_bonus"):
			continue
		total += int(handler.call("get_morale_bonus"))
	return total


func get_concert_morale_bonus(slots: Array) -> int:
	var total := 0
	for slot in slots:
		if not is_slot_building(slot, "concert"):
			continue
		var handler := get_slot_special_handler(slot)
		if handler == null or not handler.has_method("get_morale_bonus"):
			continue
		total += int(handler.call("get_morale_bonus"))
	return total
