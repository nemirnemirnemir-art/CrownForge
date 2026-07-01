extends RefCounted
class_name MapSlotSpecialRuntime


func persist_special_runtime_state(
	current_building_id: String,
	slot_index: int,
	town_core,
	special_handler: RefCounted,
	request_save: bool = false
) -> void:
	if current_building_id == "":
		return
	if town_core == null or not town_core.has_method("set_building_slot_state"):
		return
	if special_handler == null or not special_handler.has_method("get_runtime_state"):
		return
	town_core.set_building_slot_state(current_building_id, slot_index, special_handler.call("get_runtime_state"), request_save)


func restore_special_runtime_state(
	building_id: String,
	slot_index: int,
	town_core,
	special_handler: RefCounted
) -> void:
	if building_id == "":
		return
	if town_core == null or not town_core.has_method("get_building_slot_state"):
		return
	if special_handler == null or not special_handler.has_method("load_runtime_state"):
		return
	var state: Variant = town_core.get_building_slot_state(building_id, slot_index)
	if state is Dictionary and not state.is_empty():
		special_handler.call("load_runtime_state", state)
