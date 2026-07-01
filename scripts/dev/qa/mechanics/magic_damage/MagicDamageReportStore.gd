extends RefCounted
class_name MagicDamageReportStore

## Writes magic damage QA reports to disk.
## JSON (machine-readable) + Markdown (human-readable).
## Mirrors to both user:// and res:// (project dir) so another AI can read them.

const _BASE_DIR := "user://qa_reports/mechanics/magic_damage"
const _PROJECT_REPORT_DIR := "qa_reports/mechanics/magic_damage"


static func ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_BASE_DIR)
	)
	DirAccess.make_dir_recursive_absolute(_get_project_dir())


## Save all results as latest.json + latest.md (overwrites previous).
static func save_report(results: Array[Dictionary]) -> bool:
	ensure_dirs()
	var json_ok := _write_json_to_both("latest.json", results)
	var md_ok := _write_markdown_to_both("latest.md", results)
	var history_ok := _save_history(results)
	return json_ok and md_ok and history_ok


## Save a single scenario result (appends/updates latest_single.json).
static func save_single_result(result: Dictionary) -> bool:
	ensure_dirs()
	var scenario_id: String = String(result.get("scenario_id", "unknown"))
	var file_name := "single_%s.json" % scenario_id
	return _write_json_to_both(file_name, result)


static func _save_history(results: Array[Dictionary]) -> bool:
	var ts: String = Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var file_name := "history_%s.json" % ts
	return _write_json_to_both(file_name, results)


static func _write_markdown_to_both(file_name: String, results: Array[Dictionary]) -> bool:
	var md := _build_markdown(results)
	var user_ok := _write_string(ProjectSettings.globalize_path(_BASE_DIR).path_join(file_name), md)
	var proj_ok := _write_string(_get_project_dir().path_join(file_name), md)
	return user_ok and proj_ok


static func _build_markdown(results: Array[Dictionary]) -> String:
	var ts: String = Time.get_datetime_string_from_system(false, true)
	var total := results.size()
	var pass_count := 0
	var fail_count := 0
	for r: Dictionary in results:
		if String(r.get("status", "")) == "PASS":
			pass_count += 1
		else:
			fail_count += 1

	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Magic Damage QA Report")
	lines.append("Generated: " + ts)
	lines.append("")
	lines.append("## Stacking Rule")
	lines.append("All spell damage bonuses stack **additively** from a 100%% base.")
	lines.append("Base meteorite damage: %.0f" % float(results[0].get("base_damage", 110.0)) if results.size() > 0 else "110")
	lines.append("")
	lines.append("## Summary")
	lines.append("- Total: %d" % total)
	lines.append("- PASS: %d" % pass_count)
	lines.append("- FAIL: %d" % fail_count)
	lines.append("")
	lines.append("## Results")
	lines.append("")
	lines.append("| Scenario | Status | Expected Mult | Actual Mult | Expected Dmg | Actual Dmg | Notes |")
	lines.append("|----------|--------|--------------|-------------|-------------|------------|-------|")

	for r: Dictionary in results:
		var sid: String = str(r.get("label", r.get("scenario_id", "")))
		var status: String = str(r.get("status", ""))
		var exp_m: String = "%.4f" % float(r.get("expected_multiplier", 0.0))
		var act_m: String = "%.4f" % float(r.get("actual_multiplier", 0.0))
		var exp_d: String = "%.1f" % float(r.get("expected_damage", 0.0))
		var act_d: String = "%.1f" % float(r.get("actual_damage", 0.0))
		var notes: String = _escape_md(str(r.get("notes", "")))
		lines.append("| %s | %s | %s | %s | %s | %s | %s |" % [sid, status, exp_m, act_m, exp_d, act_d, notes])

	if fail_count > 0:
		lines.append("")
		lines.append("## Failures")
		lines.append("")
		for r: Dictionary in results:
			if String(r.get("status", "")) != "PASS":
				lines.append("- **%s**: %s" % [str(r.get("label", "")), str(r.get("reason", ""))])

	lines.append("")
	return "\n".join(lines)


static func _write_json_to_both(file_name: String, data: Variant) -> bool:
	var json_str := JSON.stringify(data, "\t")
	var user_ok := _write_string(ProjectSettings.globalize_path(_BASE_DIR).path_join(file_name), json_str)
	var proj_ok := _write_string(_get_project_dir().path_join(file_name), json_str)
	return user_ok and proj_ok


static func _write_string(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_warning("[MagicDamageReportStore] Could not write: %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(content)
	file.close()
	return true


static func _get_project_dir() -> String:
	var root := ProjectSettings.globalize_path("res://")
	root = root.trim_suffix("/").trim_suffix("\\")
	return root.path_join(_PROJECT_REPORT_DIR)


static func _escape_md(text: String) -> String:
	return text.replace("\n", " ").replace("|", "\\|")
