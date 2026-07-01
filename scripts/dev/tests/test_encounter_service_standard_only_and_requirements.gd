extends SceneTree

const EncounterServiceScript := preload("res://scripts/encounters/EncounterService.gd")


func _init() -> void:
	var service := EncounterServiceScript.new()
	if service == null:
		push_error("[test_encounter_service_standard_only_and_requirements] failed to create EncounterService")
		quit(1)
		return

	call_deferred("_run_test", service)


func _run_test(service: Node) -> void:
	var resource_core := get_root().get_node_or_null("/root/ResourceCore")
	if resource_core == null:
		push_error("[test_encounter_service_standard_only_and_requirements] ResourceCore autoload is missing")
		quit(1)
		return

	var standard_ids: Array[String] = service.get_standard_encounter_ids()
	if standard_ids.size() != 25:
		push_error("[test_encounter_service_standard_only_and_requirements] expected 25 standard encounter ids, got %d" % standard_ids.size())
		quit(1)
		return

	for i in range(120):
		var encounter: Dictionary = service.build_random_encounter()
		var encounter_id := String(encounter.get("id", ""))
		if encounter_id == "":
			push_error("[test_encounter_service_standard_only_and_requirements] random encounter must have non-empty id")
			quit(1)
			return
		if not standard_ids.has(encounter_id):
			push_error("[test_encounter_service_standard_only_and_requirements] non-standard encounter returned: %s" % encounter_id)
			quit(1)
			return

	resource_core.call("reset")

	var invitation: Dictionary = service.build_encounter_by_id("invitation")
	if invitation.is_empty():
		push_error("[test_encounter_service_standard_only_and_requirements] invitation encounter not found")
		quit(1)
		return

	var local_hunt: Dictionary = service.find_option(invitation, "local_hunt")
	if local_hunt.is_empty():
		push_error("[test_encounter_service_standard_only_and_requirements] local_hunt option not found")
		quit(1)
		return

	if not service.apply_option(local_hunt):
		push_error("[test_encounter_service_standard_only_and_requirements] apply_option must succeed for local_hunt")
		quit(1)
		return

	var pending: Array = service.call("consume_pending_ui_actions")
	var basic_count := 0
	for raw_action in pending:
		if String(raw_action) == "open_reward_menu_base_production":
			basic_count += 1

	if basic_count != 2:
		push_error("[test_encounter_service_standard_only_and_requirements] local_hunt must queue two base production rewards, got %s" % str(pending))
		quit(1)
		return

	if not pending.has("spawn_enemy:wall_buster:20"):
		push_error("[test_encounter_service_standard_only_and_requirements] local_hunt must queue wall_buster attack, got %s" % str(pending))
		quit(1)
		return

	print("[test_encounter_service_standard_only_and_requirements] PASS")
	quit(0)
