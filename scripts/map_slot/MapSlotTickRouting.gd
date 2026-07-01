extends RefCounted
class_name MapSlotTickRouting


func tick_active_building(current_building_id: String, tree_paused: bool, tick_manager, delta: float, tick_callback: Callable) -> void:
	if current_building_id == "":
		return
	if tree_paused:
		return
	var scaled_delta: float = delta
	if tick_manager != null:
		scaled_delta = float(tick_manager.get_scaled_delta(delta))
	if scaled_delta <= 0.0:
		return
	if not tick_callback.is_null():
		tick_callback.call(scaled_delta)


func tick_passive_special_building(current_building_id: String, king_vzor_active: bool, external_vzor_sources: Dictionary, passive_ids, tree_paused: bool, tick_manager, delta: float, tick_callback: Callable) -> void:
	if king_vzor_active:
		return
	if not external_vzor_sources.is_empty():
		return
	if not passive_ids.has(current_building_id):
		return
	tick_active_building(current_building_id, tree_paused, tick_manager, delta, tick_callback)


func dispatch_production_tick(
	building_id: String,
	ui,
	production,
	market,
	production_flow,
	special_flow,
	special_handler: RefCounted,
	basic_construction_ui,
	building_registry,
	delta: float,
	update_durability_cb: Callable,
	handle_resource_depletion_cb: Callable,
	persist_special_state_cb: Callable,
	update_basic_construction_cb: Callable,
	is_research_selector_cb: Callable,
	debug_direct_vzor: bool,
	slot_index: int
) -> Dictionary:
	if building_id == "":
		if ui != null:
			ui.hide_progress()
		return {}

	if building_id == "market":
		if market != null and production_flow != null:
			production_flow.tick_market(ui, market, delta)
		return {}

	if production == null:
		return {}

	var building_config: BuildingConfig = null
	if building_registry != null:
		building_config = building_registry.get_building(building_id)

	if building_config != null and building_config.building_type == BuildingConfig.BuildingType.SPECIAL:
		var special_result: Dictionary = {}
		if special_flow != null:
			special_result = special_flow.tick_special(
				ui, special_handler, building_config, building_id,
				basic_construction_ui, persist_special_state_cb,
				update_basic_construction_cb, is_research_selector_cb,
				debug_direct_vzor, delta
			)
		if debug_direct_vzor and building_id in ["tesla_tower", "monument_to_the_kings_gaze"] and not special_result.is_empty():
			print("[MapSlot][SpecialTick] slot=%d building=%s producing=%s progress=%.3f completed=%s cycle=%.3f" % [
				slot_index,
				building_id,
				str(bool(special_result.get("is_producing", false))),
				float(special_result.get("progress_ratio", 0.0)),
				str(bool(special_result.get("completed", false))),
				float(special_result.get("cycle_time", building_config.cycle_time)),
			])
		return {}

	var result: Dictionary
	if production_flow != null:
		result = production_flow.tick_regular_building(ui, production, delta, building_id, building_config)
	else:
		result = production.tick(delta, building_id, building_config)

	if result.get("completed", false):
		if not update_durability_cb.is_null():
			update_durability_cb.call()
		if not handle_resource_depletion_cb.is_null():
			handle_resource_depletion_cb.call(building_config)

	return result
