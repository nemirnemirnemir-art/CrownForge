extends RefCounted
class_name MapSlotMiscFlow


func on_research_mode_requested(mode: int, special_handler: RefCounted, persist_runtime_state: Callable, update_research_visuals: Callable, research_table_ui) -> void:
	if special_handler and special_handler.has_method("set_mode"):
		special_handler.call("set_mode", mode)
	if persist_runtime_state.is_valid():
		persist_runtime_state.call()
	if update_research_visuals.is_valid():
		update_research_visuals.call()
	if research_table_ui and special_handler and special_handler.has_method("get_mode"):
		if research_table_ui.has_method("setup_options") and special_handler.has_method("get_ui_options"):
			research_table_ui.call("setup_options", special_handler.call("get_ui_options"), int(special_handler.call("get_mode")))
		elif research_table_ui.has_method("setup"):
			research_table_ui.call("setup", int(special_handler.call("get_mode")))
		research_table_ui.visible = false


func replace_current_building(building_id: String, set_building_callback: Callable, save_core) -> void:
	if set_building_callback.is_valid():
		set_building_callback.call(building_id)
	if save_core and save_core.has_method("request_save"):
		save_core.request_save()
