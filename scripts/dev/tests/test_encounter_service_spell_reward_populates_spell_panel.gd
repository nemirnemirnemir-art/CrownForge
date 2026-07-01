extends SceneTree

const EncounterServiceScript := preload("res://scripts/encounters/EncounterService.gd")
const SpellPanelScene := preload("res://scenes/ui/spells/SpellPanel.tscn")


func _init() -> void:
	var spell_panel := SpellPanelScene.instantiate()
	if spell_panel == null:
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] failed to instantiate SpellPanel")
		quit(1)
		return

	get_root().add_child(spell_panel)
	call_deferred("_run_test", spell_panel)


func _run_test(spell_panel: Control) -> void:
	await process_frame

	var service := EncounterServiceScript.new()
	if service == null:
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] failed to create EncounterService")
		quit(1)
		return

	var encounter: Dictionary = service.build_encounter_by_id("dish_best_served_warm")
	if encounter.is_empty():
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] dish_best_served_warm encounter not found")
		quit(1)
		return

	var option: Dictionary = service.find_option(encounter, "praise_dish")
	if option.is_empty():
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] praise_dish option not found")
		quit(1)
		return

	if not service.apply_option(option):
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] apply_option must succeed for praise_dish")
		quit(1)
		return

	await process_frame

	if not _spell_panel_has_spell(spell_panel, "healing_pool"):
		push_error("[test_encounter_service_spell_reward_populates_spell_panel] healing_pool must appear in SpellPanel after encounter reward")
		quit(1)
		return

	print("[test_encounter_service_spell_reward_populates_spell_panel] PASS")
	quit(0)


func _spell_panel_has_spell(spell_panel: Control, spell_id: String) -> bool:
	if spell_panel == null:
		return false

	for i in range(9):
		var slot := spell_panel.get_node_or_null("GridContainer/SpellSlot%d" % (i + 1))
		if slot == null:
			continue
		if bool(slot.call("is_empty")):
			continue
		var config: Variant = slot.call("get_spell")
		if config != null and String(config.get("spell_id")) == spell_id:
			return true
	return false
