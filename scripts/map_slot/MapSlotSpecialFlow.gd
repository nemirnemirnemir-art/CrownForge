extends RefCounted
class_name MapSlotSpecialFlow


func tick_special(
	ui,
	special_handler: RefCounted,
	building_config,
	current_building_id: String,
	basic_construction_ui,
	persist_runtime_state: Callable,
	update_basic_construction_visuals: Callable,
	is_research_selector_building: Callable,
	_debug_special: bool,
	delta: float
) -> Dictionary:
	if special_handler and special_handler.has_method("tick"):
		var special_result: Dictionary = special_handler.tick(delta)
		if bool(special_result.get("is_producing", false)):
			if ui:
				var cycle: float = float(special_result.get("cycle_time", building_config.cycle_time))
				ui.update_progress(float(special_result.get("progress_ratio", 0.0)), cycle)
		elif ui:
			ui.hide_progress()

		var should_persist := false
		if is_research_selector_building.is_valid() and bool(is_research_selector_building.call()):
			should_persist = true
		elif current_building_id == "basic_construction":
			should_persist = true
		elif special_handler.has_method("get_runtime_state") and bool(special_result.get("completed", false)):
			should_persist = true
		if should_persist and persist_runtime_state.is_valid():
			persist_runtime_state.call(bool(special_result.get("completed", false)))

		if current_building_id == "basic_construction" and basic_construction_ui and basic_construction_ui.has_method("setup") and special_handler.has_method("is_ready"):
			basic_construction_ui.call("setup", bool(special_handler.call("is_ready")))
			if update_basic_construction_visuals.is_valid():
				update_basic_construction_visuals.call()
		return special_result

	if ui:
		ui.hide_progress()
	return {}
