extends SceneTree

const EncounterServiceScript := preload("res://scripts/encounters/EncounterService.gd")


func _init() -> void:
	var service := EncounterServiceScript.new()
	if service == null:
		push_error("[test_encounter_service_exposes_effects_text] failed to create EncounterService")
		quit(1)
		return

	call_deferred("_run_test", service)


func _run_test(service: Node) -> void:
	var encounter: Dictionary = service.build_encounter_by_id("drought")
	if encounter.is_empty():
		push_error("[test_encounter_service_exposes_effects_text] drought encounter not found")
		quit(1)
		return

	var option: Dictionary = service.find_option(encounter, "noble_granaries")
	if option.is_empty():
		push_error("[test_encounter_service_exposes_effects_text] noble_granaries option not found")
		quit(1)
		return

	var effects_text := String(option.get("effects_text", ""))
	if effects_text == "":
		push_error("[test_encounter_service_exposes_effects_text] effects_text must be non-empty")
		quit(1)
		return

	if effects_text.find("250") == -1 or effects_text.to_lower().find("wheat") == -1:
		push_error("[test_encounter_service_exposes_effects_text] effects_text must include 250 wheat, got: %s" % effects_text)
		quit(1)
		return

	var effect_rows_var: Variant = option.get("effects_rows", [])
	if not (effect_rows_var is Array):
		push_error("[test_encounter_service_exposes_effects_text] effects_rows must be an Array")
		quit(1)
		return

	var effect_rows: Array = effect_rows_var
	if effect_rows.is_empty():
		push_error("[test_encounter_service_exposes_effects_text] effects_rows must be non-empty")
		quit(1)
		return

	var first_row := effect_rows[0] as Dictionary
	if first_row.is_empty() or String(first_row.get("icon_path", "")) == "":
		push_error("[test_encounter_service_exposes_effects_text] first effects row must include icon_path")
		quit(1)
		return

	var reward_encounter: Dictionary = service.build_encounter_by_id("blazing_orb")
	if reward_encounter.is_empty():
		push_error("[test_encounter_service_exposes_effects_text] blazing_orb encounter not found")
		quit(1)
		return

	var reward_option: Dictionary = service.find_option(reward_encounter, "heat_bathhouse")
	if reward_option.is_empty():
		push_error("[test_encounter_service_exposes_effects_text] heat_bathhouse option not found")
		quit(1)
		return

	var reward_rows_var: Variant = reward_option.get("effects_rows", [])
	if not (reward_rows_var is Array):
		push_error("[test_encounter_service_exposes_effects_text] reward preview rows must be an Array")
		quit(1)
		return

	var reward_rows: Array = reward_rows_var
	if reward_rows.size() < 2:
		push_error("[test_encounter_service_exposes_effects_text] heat_bathhouse must expose reward and failure preview rows")
		quit(1)
		return

	var reward_text := String(reward_option.get("effects_text", ""))
	if reward_text.find("Building Upgrade") == -1 or reward_text.find("x2") == -1 or reward_text.find("75%") == -1:
		push_error("[test_encounter_service_exposes_effects_text] heat_bathhouse must preview Building Upgrade x2 (75%%), got: %s" % reward_text)
		quit(1)
		return

	if reward_text.find("nothing") == -1 and reward_text.find("Nothing") == -1:
		push_error("[test_encounter_service_exposes_effects_text] heat_bathhouse must preview the no-reward branch, got: %s" % reward_text)
		quit(1)
		return

	print("[test_encounter_service_exposes_effects_text] PASS")
	quit(0)
