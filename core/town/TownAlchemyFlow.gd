extends RefCounted
class_name TownAlchemyFlow


func update_and_autosave(alchemy_craft, save_core) -> void:
	if alchemy_craft and alchemy_craft.update() and save_core and save_core.has_method("request_save"):
		save_core.request_save()


func get_alchemy_potion_defs(alchemy_craft) -> Dictionary:
	if not alchemy_craft:
		return {}
	return alchemy_craft.get_potion_defs()


func get_alchemy_queue(alchemy_craft, save_core) -> Array[Dictionary]:
	update_and_autosave(alchemy_craft, save_core)
	if not alchemy_craft:
		return []
	return alchemy_craft.get_queue()


func get_alchemy_active_remaining_sec(alchemy_craft, save_core) -> int:
	update_and_autosave(alchemy_craft, save_core)
	if not alchemy_craft:
		return 0
	return alchemy_craft.get_active_remaining_sec()


func try_enqueue_alchemy(alchemy_craft, save_core, potion_id: String) -> bool:
	update_and_autosave(alchemy_craft, save_core)
	if not alchemy_craft:
		return false
	var ok: bool = alchemy_craft.try_enqueue(potion_id)
	if ok and save_core and save_core.has_method("request_save"):
		save_core.request_save()
	return ok


func try_cancel_alchemy(alchemy_craft, save_core, index: int) -> bool:
	update_and_autosave(alchemy_craft, save_core)
	if not alchemy_craft:
		return false
	var ok: bool = alchemy_craft.try_cancel(index)
	if ok and save_core and save_core.has_method("request_save"):
		save_core.request_save()
	return ok
