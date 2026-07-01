extends RefCounted
class_name BuildingUpgradeQaReportStore

## QA report persistence for building upgrade verification.
## Writes to user://qa_reports/building_upgrade/.
## Separate from game save — does not touch save.json.

const _BASE_DIR := "user://qa_reports/building_upgrade"
const _HISTORY_DIR := "user://qa_reports/building_upgrade/history"
const _LATEST_JSON := "user://qa_reports/building_upgrade/latest.json"
const _LATEST_FAILED_JSON := "user://qa_reports/building_upgrade/latest_failed.json"
const _LATEST_MD := "user://qa_reports/building_upgrade/latest.md"
const _PROJECT_REPORT_DIR := "qa_reports/building_upgrade"
const _PROJECT_HISTORY_DIR := "qa_reports/building_upgrade/history"


static func ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_BASE_DIR)
	)
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_HISTORY_DIR)
	)
	DirAccess.make_dir_recursive_absolute(get_project_report_dir_absolute())
	DirAccess.make_dir_recursive_absolute(_get_project_history_dir_absolute())


static func save_latest(results: Array[Dictionary]) -> bool:
	ensure_dirs()
	var user_ok := _write_json(_LATEST_JSON, results)
	var project_ok := _write_project_json("latest.json", results)
	return user_ok and project_ok


static func save_latest_failed(results: Array[Dictionary]) -> bool:
	ensure_dirs()
	var failed: Array[Dictionary] = []
	for entry in results:
		if entry.get("status", "") != "PASS":
			failed.append(entry)
	var user_ok := _write_json(_LATEST_FAILED_JSON, failed)
	var project_ok := _write_project_json("latest_failed.json", failed)
	return user_ok and project_ok


static func save_history(results: Array[Dictionary]) -> bool:
	ensure_dirs()
	var ts: String = Time.get_datetime_string_from_system(false, true)
	ts = ts.replace(":", "-")
	var path := _HISTORY_DIR + "/" + ts + ".json"
	var user_ok := _write_json(path, results)
	var project_ok := _write_json(_get_project_history_dir_absolute().path_join(ts + ".json"), results)
	return user_ok and project_ok


static func save_markdown(results: Array[Dictionary]) -> bool:
	ensure_dirs()
	var ts: String = Time.get_datetime_string_from_system(false, true)

	var total := results.size()
	var pass_count := 0
	var fail_count := 0
	var manual_count := 0
	for entry in results:
		var s: String = entry.get("status", "")
		if s == "PASS":
			pass_count += 1
		elif s.begins_with("FAIL"):
			fail_count += 1
		else:
			manual_count += 1

	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Building Upgrade QA Report")
	lines.append("Generated: " + ts)
	lines.append("")
	lines.append("## Summary")
	lines.append("- Total: " + str(total))
	lines.append("- PASS: " + str(pass_count))
	lines.append("- FAIL: " + str(fail_count))
	lines.append("- MANUAL: " + str(manual_count))
	lines.append("")
	lines.append("## Results")
	lines.append("")
	lines.append("| upgrade_id | family | status | target | before | after | expected | reason |")
	lines.append("|-----------|--------|--------|--------|--------|-------|----------|--------|")

	for entry in results:
		var uid: String = str(entry.get("upgrade_id", ""))
		var family: String
		if entry.has("family_name"):
			family = str(entry.get("family_name", ""))
		else:
			family = str(entry.get("family", ""))
		var status: String = str(entry.get("status", ""))
		var target := _escape_md_cell(str(entry.get("target", "")))
		var before := _escape_md_cell(_format_value(entry.get("before", null)))
		var after := _escape_md_cell(_format_value(entry.get("after", null)))
		var expected := _escape_md_cell(_format_value(entry.get("expected", null)))
		var reason := _escape_md_cell(str(entry.get("reason", "")))
		lines.append("| " + uid + " | " + family + " | " + status + " | " + target + " | " + before + " | " + after + " | " + expected + " | " + reason + " |")

	lines.append("")
	var content := "\n".join(lines)
	var user_ok := _write_string(_LATEST_MD, content)
	var project_ok := _write_project_string("latest.md", content)
	return user_ok and project_ok


static func load_latest() -> Array:
	return _read_json(_LATEST_JSON)


static func load_latest_failed() -> Array:
	return _read_json(_LATEST_FAILED_JSON)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

static func get_project_report_dir_absolute() -> String:
	var project_root := ProjectSettings.globalize_path("res://")
	project_root = project_root.trim_suffix("/")
	project_root = project_root.trim_suffix("\\")
	return project_root.path_join(_PROJECT_REPORT_DIR)


static func _get_project_history_dir_absolute() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\").path_join(_PROJECT_HISTORY_DIR)


static func _write_project_json(file_name: String, data: Variant) -> bool:
	return _write_json(get_project_report_dir_absolute().path_join(file_name), data)


static func _write_project_string(file_name: String, data: String) -> bool:
	return _write_string(get_project_report_dir_absolute().path_join(file_name), data)


static func _write_json(path: String, data: Variant) -> bool:
	var json_string := JSON.stringify(data)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_string)
	file.close()
	return true


static func _write_string(path: String, data: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(data)
	file.close()
	return true


static func _read_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return []
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return []
	if json.data is Array:
		return json.data
	return []


static func _format_value(value: Variant) -> String:
	if value == null:
		return "null"
	if value is Dictionary or value is Array:
		return JSON.stringify(value)
	return str(value)


static func _escape_md_cell(text: String) -> String:
	return text.replace("\n", "<br>").replace("|", "\\|")
