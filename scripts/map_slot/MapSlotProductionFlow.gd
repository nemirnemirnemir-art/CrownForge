extends RefCounted
class_name MapSlotProductionFlow


func tick_regular_building(ui, production, delta: float, current_building_id: String, building_config) -> Dictionary:
	if production == null:
		return {}
	var result: Dictionary = production.tick(delta, current_building_id, building_config)
	if bool(result.get("is_producing", false)):
		if ui:
			var cycle := float(result.get("cycle_time", building_config.cycle_time if building_config else production._current_cycle))
			ui.update_progress(float(result.get("progress_ratio", 0.0)), cycle)
	elif ui:
		ui.hide_progress()
	return result


func tick_market(ui, market, delta: float) -> Dictionary:
	if market == null:
		return {}
	var result: Dictionary = market.tick(delta)
	if bool(result.get("is_trading", false)):
		if ui:
			var cycle: float = float(market.CYCLE_TIME)
			if market.has_method("_get_effective_cycle_time"):
				cycle = float(market.call("_get_effective_cycle_time"))
			ui.update_progress(float(result.get("progress_ratio", 0.0)), cycle)
	elif ui:
		ui.hide_progress()
	return result


func recover_runtime(ui, production, current_building_id: String, building_config) -> Dictionary:
	if current_building_id == "" or production == null or building_config == null:
		return {}
	var result: Dictionary = production.recover_runtime_state(building_config)
	if bool(result.get("is_producing", false)):
		if ui:
			var cycle := float(result.get("cycle_time", building_config.cycle_time))
			ui.update_progress(float(result.get("progress_ratio", 0.0)), cycle)
	elif ui:
		ui.hide_progress()
	return result
