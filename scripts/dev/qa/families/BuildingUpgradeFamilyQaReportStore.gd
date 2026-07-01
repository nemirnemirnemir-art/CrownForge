extends RefCounted
class_name BuildingUpgradeFamilyQaReportStore

## Writes family QA reports to disk.
## JSON (machine-readable) + Markdown (human-readable).
## Mirrors to both user:// and res:// (project dir) so another AI can read them.
## Report paths are parameterized by family slug: qa_reports/building_upgrade/<family_slug>/

const RegistryScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRegistry.gd")
const RunnerScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRunner.gd")

const _BASE_DIR := "user://qa_reports/building_upgrade"
const _PROJECT_BASE_DIR := "qa_reports/building_upgrade"


## Ensure directories exist for a family slug.
static func ensure_dirs(family_slug: String) -> void:
	var user_dir := "%s/%s" % [_BASE_DIR, family_slug]
	var proj_dir := "%s/%s" % [_get_project_root(), family_slug]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(user_dir))
	DirAccess.make_dir_recursive_absolute(proj_dir)


## Save results for a specific family.
static func save_family_report(family_slug: String, results: Array[Dictionary]) -> bool:
	ensure_dirs(family_slug)
	var json_ok := _write_json_to_both(family_slug, "latest.json", results)
	var md_ok := _write_markdown_to_both(family_slug, "latest.md", results)
	var history_ok := _save_history(family_slug, results)
	return json_ok and md_ok and history_ok


## Save a single upgrade result.
static func save_single_result(family_slug: String, result: Dictionary) -> bool:
	ensure_dirs(family_slug)
	var upgrade_id: String = String(result.get("upgrade_id", "unknown"))
	var safe_id := upgrade_id.replace(":", "_")
	var file_name := "single_%s.json" % safe_id
	return _write_json_to_both(family_slug, file_name, result)


## Save aggregate report for all V1 families.
static func save_aggregate_report(results: Array[Dictionary]) -> bool:
	ensure_dirs("_aggregate")
	var json_ok := _write_json_to_both("_aggregate", "latest.json", results)
	var md_ok := _write_aggregate_markdown("_aggregate", "latest.md", results)
	var history_ok := _save_history("_aggregate", results)
	return json_ok and md_ok and history_ok


static func _save_history(family_slug: String, results: Array[Dictionary]) -> bool:
	var ts: String = Time.get_datetime_string_from_system(false, true).replace(":", "-")
	var file_name := "history_%s.json" % ts
	return _write_json_to_both(family_slug, file_name, results)


static func _write_json_to_both(family_slug: String, file_name: String, data: Variant) -> bool:
	var json_str := JSON.stringify(data, "\t")
	var user_path := "%s/%s/%s" % [ProjectSettings.globalize_path(_BASE_DIR), family_slug, file_name]
	var proj_path := "%s/%s/%s" % [_get_project_root(), family_slug, file_name]
	var user_ok := _write_string(user_path, json_str)
	var proj_ok := _write_string(proj_path, json_str)
	return user_ok and proj_ok


static func _write_markdown_to_both(family_slug: String, file_name: String, results: Array[Dictionary]) -> bool:
	var md := _build_family_markdown(family_slug, results)
	var user_path := "%s/%s/%s" % [ProjectSettings.globalize_path(_BASE_DIR), family_slug, file_name]
	var proj_path := "%s/%s/%s" % [_get_project_root(), family_slug, file_name]
	var user_ok := _write_string(user_path, md)
	var proj_ok := _write_string(proj_path, md)
	return user_ok and proj_ok


static func _write_aggregate_markdown(family_slug: String, file_name: String, results: Array[Dictionary]) -> bool:
	var md := _build_aggregate_markdown(results)
	var user_path := "%s/%s/%s" % [ProjectSettings.globalize_path(_BASE_DIR), family_slug, file_name]
	var proj_path := "%s/%s/%s" % [_get_project_root(), family_slug, file_name]
	var user_ok := _write_string(user_path, md)
	var proj_ok := _write_string(proj_path, md)
	return user_ok and proj_ok


static func _build_family_markdown(family_slug: String, results: Array[Dictionary]) -> String:
	var family := RegistryScript.get_family_by_slug(family_slug)
	var label: String = family.get("label", family_slug) if not family.is_empty() else family_slug
	var ts: String = Time.get_datetime_string_from_system(false, true)
	var summary := RunnerScript.get_summary(results)
	
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# %s QA Report" % label)
	lines.append("Generated: %s" % ts)
	lines.append("")
	lines.append("## Summary")
	lines.append("- Total: %d" % summary.total)
	lines.append("- PASS: %d" % summary.pass)
	lines.append("- LOGIC_PASS: %d" % summary.logic_pass)
	lines.append("- FAIL: %d" % summary.fail)
	lines.append("- MANUAL: %d" % summary.manual)
	lines.append("")
	lines.append("## Results")
	lines.append("")
	lines.append("| Upgrade ID | Status | Target | Before | After | Expected |")
	lines.append("|------------|--------|--------|--------|-------|----------|")
	
	for r: Dictionary in results:
		var uid: String = _escape_md(String(r.get("upgrade_id", "")))
		var status: String = String(r.get("status", ""))
		var target: String = _escape_md(String(r.get("target", "")))
		var before: String = _format_value(r.get("before", null))
		var after: String = _format_value(r.get("after", null))
		var expected: String = _format_value(r.get("expected", null))
		lines.append("| %s | %s | %s | %s | %s | %s |" % [uid, status, target, before, after, expected])
	
	if summary.fail > 0:
		lines.append("")
		lines.append("## Failures")
		lines.append("")
		for r: Dictionary in results:
			var status: String = String(r.get("status", ""))
			if status.begins_with("FAIL"):
				lines.append("- **%s**: %s" % [r.get("upgrade_id", ""), r.get("reason", "")])
	
	lines.append("")
	return "\n".join(lines)


static func _build_aggregate_markdown(results: Array[Dictionary]) -> String:
	var ts: String = Time.get_datetime_string_from_system(false, true)
	var total_summary := RunnerScript.get_summary(results)
	
	# Group by family
	var by_family: Dictionary = {}
	for r: Dictionary in results:
		var slug: String = String(r.get("family_slug", "unknown"))
		if not by_family.has(slug):
			by_family[slug] = []
		(by_family[slug] as Array).append(r)
	
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# V1 Families Aggregate QA Report")
	lines.append("Generated: %s" % ts)
	lines.append("")
	lines.append("## Overall Summary")
	lines.append("- Total: %d" % total_summary.total)
	lines.append("- PASS: %d" % total_summary.pass)
	lines.append("- LOGIC_PASS: %d" % total_summary.logic_pass)
	lines.append("- FAIL: %d" % total_summary.fail)
	lines.append("- MANUAL: %d" % total_summary.manual)
	lines.append("- All Pass: %s" % ("YES" if total_summary.all_pass else "NO"))
	lines.append("")
	lines.append("## Per-Family Summary")
	lines.append("")
	lines.append("| Family | Total | Pass | Logic Pass | Fail | Manual |")
	lines.append("|--------|-------|------|------------|------|--------|")
	
	for slug: String in by_family.keys():
		var family := RegistryScript.get_family_by_slug(slug)
		var label: String = family.get("label", slug) if not family.is_empty() else slug
		var family_results: Array = by_family[slug]
		var typed_results: Array[Dictionary] = []
		for r in family_results:
			typed_results.append(r as Dictionary)
		var family_summary := RunnerScript.get_summary(typed_results)
		lines.append("| %s | %d | %d | %d | %d | %d |" % [
			label, family_summary.total, family_summary.pass, family_summary.logic_pass,
			family_summary.fail, family_summary.manual
		])
	
	if total_summary.fail > 0:
		lines.append("")
		lines.append("## All Failures")
		lines.append("")
		for r: Dictionary in results:
			var status: String = String(r.get("status", ""))
			if status.begins_with("FAIL"):
				lines.append("- **%s** (%s): %s" % [
					r.get("upgrade_id", ""),
					r.get("family_label", ""),
					r.get("reason", "")
				])
	
	lines.append("")
	return "\n".join(lines)


static func _write_string(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_warning("[BuildingUpgradeFamilyQaReportStore] Could not write: %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(content)
	file.close()
	return true


static func _get_project_root() -> String:
	var root := ProjectSettings.globalize_path("res://")
	root = root.trim_suffix("/").trim_suffix("\\")
	return root.path_join(_PROJECT_BASE_DIR)


static func _escape_md(text: String) -> String:
	return text.replace("\n", " ").replace("|", "\\|")


static func _format_value(value: Variant) -> String:
	if value == null:
		return "-"
	if value is Dictionary or value is Array:
		var json := JSON.stringify(value)
		if json.length() > 30:
			json = json.substr(0, 27) + "..."
		return _escape_md(json)
	return _escape_md(str(value))
