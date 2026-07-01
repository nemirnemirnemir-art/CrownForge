extends RefCounted
class_name MapSlotRecoveryFlow


func recover_after_encounter_pause(
	current_building_id: String,
	building_registry,
	ui,
	production,
	production_flow,
	anim_vzor: AnimatedSprite2D,
	vzor_state_flow,
	apply_mine_visual_state: Callable
) -> bool:
	if current_building_id == "":
		return false

	var touched := false
	var building_config = null
	if building_registry:
		building_config = building_registry.get_building(current_building_id)

	if building_config and production and building_config.building_type != BuildingConfig.BuildingType.SPECIAL and current_building_id != "market":
		var result: Dictionary = production_flow.recover_runtime(ui, production, current_building_id, building_config) if production_flow else production.recover_runtime_state(building_config)
		if bool(result.get("is_producing", false)):
			touched = true
		elif ui == null:
			pass

	if anim_vzor and anim_vzor.visible and vzor_state_flow and vzor_state_flow.is_effectively_vzor_active():
		if anim_vzor.sprite_frames and String(anim_vzor.animation) != "" and not anim_vzor.is_playing():
			anim_vzor.play(anim_vzor.animation)
			touched = true

	if apply_mine_visual_state.is_valid():
		apply_mine_visual_state.call()
	return touched
