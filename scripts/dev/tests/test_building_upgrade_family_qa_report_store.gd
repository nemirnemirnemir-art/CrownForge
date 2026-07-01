extends SceneTree

## Headless regression test for BuildingUpgradeFamilyQaReportStore.
## Run with: godot --headless --script scripts/dev/tests/test_building_upgrade_family_qa_report_store.gd

const ReportStoreScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaReportStore.gd")

var _failed := false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_building_upgrade_family_qa_report_store] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	# Test 1: ensure_dirs creates directory
	ReportStoreScript.ensure_dirs("_test_family")
	# If we got here without error, directory creation worked

	# Test 2: save_family_report creates files
	var test_results: Array[Dictionary] = [
		{
			"upgrade_id": "test:0",
			"building_id": "test",
			"upgrade_index": 0,
			"family_id": 0,
			"family_slug": "_test_family",
			"family_label": "Test Family",
			"status": "PASS",
			"target": "test.target",
			"before": 1.0,
			"after": 2.0,
			"expected": 2.0,
			"reason": "",
			"ran_at": "2024-01-01T00:00:00",
		}
	]

	var success := ReportStoreScript.save_family_report("_test_family", test_results)
	if not success:
		_fail("save_family_report returned false")
		return

	# Check if files exist
	var project_root := ProjectSettings.globalize_path("res://")
	project_root = project_root.trim_suffix("/").trim_suffix("\\")
	var json_path := project_root.path_join("qa_reports/building_upgrade/_test_family/latest.json")
	var md_path := project_root.path_join("qa_reports/building_upgrade/_test_family/latest.md")

	if not FileAccess.file_exists(json_path):
		_fail("latest.json not created at %s" % json_path)
		return
	if not FileAccess.file_exists(md_path):
		_fail("latest.md not created at %s" % md_path)
		return

	# Verify JSON content is valid
	var json_file := FileAccess.open(json_path, FileAccess.READ)
	if json_file == null:
		_fail("Could not open latest.json for reading")
		return
	var json_str := json_file.get_as_text()
	json_file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_str)
	if parse_result != OK:
		_fail("latest.json contains invalid JSON")
		return

	var data: Array = json.data
	if data.is_empty():
		_fail("latest.json is empty array")
		return

	print("[test_building_upgrade_family_qa_report_store] PASS — 2 tests passed")
	quit(0)
