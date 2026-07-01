extends SceneTree

const PanelScript := preload("res://scripts/ui/debug/BuildingUpgradeQaPanel.gd")
const FamilyRunnerScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRunner.gd")
const FamilyReportStoreScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaReportStore.gd")

var _failed := false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_qa_panel_v1] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var panel := PanelScript.new()
	get_root().add_child(panel)
	await process_frame

	var selector := panel.get("_family_selector") as OptionButton
	if selector == null:
		_fail("_family_selector не был создан")
		return
	if selector.item_count != 11:
		_fail("Ожидалось 11 пунктов в селекторе семей, получено %d" % selector.item_count)
		return

	var current_section := panel.get("_current_family_section") as Control
	if current_section == null:
		_fail("Начальная секция семейства не была создана")
		return

	panel.call("_on_family_selected", 1)
	await process_frame
	current_section = panel.get("_current_family_section") as Control
	if current_section == null:
		_fail("Секция после переключения семейства не была создана")
		return

	var results := FamilyRunnerScript.run_all_v1()
	if results.is_empty():
		_fail("run_all_v1 вернул пустой список результатов")
		return

	var saved := FamilyReportStoreScript.save_aggregate_report(results)
	if not saved:
		_fail("Не удалось сохранить агрегированный отчет V1")
		return

	var project_root := ProjectSettings.globalize_path("res://")
	project_root = project_root.trim_suffix("/").trim_suffix("\\")
	var aggregate_json := project_root.path_join("qa_reports/building_upgrade/_aggregate/latest.json")
	var aggregate_md := project_root.path_join("qa_reports/building_upgrade/_aggregate/latest.md")
	if not FileAccess.file_exists(aggregate_json):
		_fail("Не найден агрегированный JSON-отчет: %s" % aggregate_json)
		return
	if not FileAccess.file_exists(aggregate_md):
		_fail("Не найден агрегированный Markdown-отчет: %s" % aggregate_md)
		return

	print("[test_building_upgrade_qa_panel_v1] PASS")
	quit(0)
