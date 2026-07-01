extends SceneTree

const EncounterServiceScript := preload("res://scripts/encounters/EncounterService.gd")


func _init() -> void:
	var service := EncounterServiceScript.new()
	if service == null:
		push_error("[test_encounter_service_triggers_building_upgrade_action] failed to create EncounterService")
		quit(1)
		return

	call_deferred("_run_test", service)


func _run_test(service: Node) -> void:
	var encounter := service.call("build_encounter_by_id", "dish_best_served_warm") as Dictionary
	if encounter.is_empty():
		push_error("[test_encounter_service_triggers_building_upgrade_action] dish_best_served_warm encounter not found")
		quit(1)
		return

	var option := service.call("find_option", encounter, "fake_allergy") as Dictionary
	if option.is_empty():
		push_error("[test_encounter_service_triggers_building_upgrade_action] fake_allergy option not found")
		quit(1)
		return

	if not bool(service.call("apply_option", option)):
		push_error("[test_encounter_service_triggers_building_upgrade_action] apply_option must succeed for fake_allergy")
		quit(1)
		return

	if not service.has_method("consume_pending_ui_actions"):
		push_error("[test_encounter_service_triggers_building_upgrade_action] EncounterService must expose consume_pending_ui_actions()")
		quit(1)
		return

	var pending: Array = service.call("consume_pending_ui_actions")
	if pending.is_empty():
		push_error("[test_encounter_service_triggers_building_upgrade_action] expected non-empty pending UI actions")
		quit(1)
		return

	if not pending.has("open_reward_menu_advanced_production"):
		push_error("[test_encounter_service_triggers_building_upgrade_action] expected advanced-production action, got %s" % str(pending))
		quit(1)
		return

	print("[test_encounter_service_triggers_building_upgrade_action] PASS")
	quit(0)
