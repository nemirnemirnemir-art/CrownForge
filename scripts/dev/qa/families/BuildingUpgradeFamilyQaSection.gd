extends RefCounted
class_name BuildingUpgradeFamilyQaSection

## Generic section builder for family-based QA testing in the F11 panel.
## Builds a section with per-upgrade buttons for a given family.
## Used by the family selector in BuildingUpgradeQaPanel.

const AuditMatrixScript := preload("res://scripts/dev/audit/BuildingUpgradeAuditMatrix.gd")
const RegistryScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRegistry.gd")
const RunnerScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRunner.gd")
const ReportStoreScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaReportStore.gd")


## Build and return a section for a specific family by slug.
## The section contains: header, run-all button, per-entry buttons, results label.
static func build_section(family_slug: String, tree: SceneTree) -> VBoxContainer:
	var family := RegistryScript.get_family_by_slug(family_slug)
	if family.is_empty():
		return _build_error_section("Unknown family: %s" % family_slug)
	
	var family_id := int(family.get("family_id", -1))
	var family_label: String = String(family.get("label", family_slug))
	var entries := AuditMatrixScript.get_entries_by_family(family_id)
	
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Section header
	var header_panel := PanelContainer.new()
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.2, 0.25, 0.35, 1.0)
	header_style.set_corner_radius_all(4)
	header_panel.add_theme_stylebox_override("panel", header_style)
	section.add_child(header_panel)
	
	var header_label := Label.new()
	header_label.text = "%s (%d entries)" % [family_label.to_upper(), entries.size()]
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 28)
	header_panel.add_child(header_label)
	
	# Results display area (created early, added at end)
	var results_label := Label.new()
	results_label.name = "FamilyResults_%s" % family_slug
	results_label.text = "Ready. Press a button to run tests."
	results_label.add_theme_font_size_override("font_size", 22)
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	
	# Run All button
	var run_all_btn := Button.new()
	run_all_btn.text = "Run All %d Entries" % entries.size()
	run_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_all_btn.custom_minimum_size = Vector2(0.0, 56.0)
	run_all_btn.add_theme_font_size_override("font_size", 22)
	run_all_btn.pressed.connect(_on_run_all.bind(family_slug, results_label, tree))
	section.add_child(run_all_btn)
	
	section.add_child(HSeparator.new())
	
	# Per-entry buttons in a scrollable container
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 300.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	section.add_child(scroll)
	
	var entries_vbox := VBoxContainer.new()
	entries_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries_vbox)
	
	for entry: Dictionary in entries:
		var upgrade_id: String = String(entry.get("upgrade_id", ""))
		var expected: Dictionary = entry.get("expected", {})
		var btn_text := _format_entry_button_text(upgrade_id, expected)
		
		var btn := Button.new()
		btn.text = btn_text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 44.0)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_run_single.bind(family_slug, upgrade_id, results_label, tree))
		entries_vbox.add_child(btn)
	
	section.add_child(HSeparator.new())
	
	# Results label at bottom
	section.add_child(results_label)
	
	return section


static func _build_error_section(message: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	section.add_child(label)
	return section


static func _format_entry_button_text(upgrade_id: String, expected: Dictionary) -> String:
	# Create a short description from expected values
	var parts: PackedStringArray = PackedStringArray()
	parts.append(upgrade_id)
	
	if expected.has("multiplier"):
		parts.append("x%.2f" % float(expected["multiplier"]))
	if expected.has("bonus"):
		parts.append("+%d" % int(expected["bonus"]))
	if expected.has("bonus_flat"):
		parts.append("+%d morale" % int(expected["bonus_flat"]))
	if expected.has("bonus_per_building"):
		parts.append("+%d/bldg" % int(expected["bonus_per_building"]))
	if expected.has("unit"):
		parts.append(String(expected["unit"]))
	if expected.has("class"):
		parts.append(String(expected["class"]))
	if expected.has("type"):
		parts.append(String(expected["type"]))
	if expected.has("hp_mult"):
		parts.append("HP x%.2f" % float(expected["hp_mult"]))
	if expected.has("dmg_mult"):
		parts.append("DMG x%.2f" % float(expected["dmg_mult"]))
	
	return " | ".join(parts)


static func _on_run_all(family_slug: String, results_label: Label, tree: SceneTree) -> void:
	results_label.text = "Running all entries for %s..." % family_slug
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	await tree.process_frame
	
	var results := RunnerScript.run_family_by_slug(family_slug)
	
	# Save reports to disk
	ReportStoreScript.save_family_report(family_slug, results)
	
	# Display results
	_display_results(results, results_label, family_slug)


static func _on_run_single(family_slug: String, upgrade_id: String, results_label: Label, tree: SceneTree) -> void:
	results_label.text = "Running: %s..." % upgrade_id
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	await tree.process_frame
	
	var result := RunnerScript.run_single(upgrade_id)
	
	# Save single result
	ReportStoreScript.save_single_result(family_slug, result)
	
	# Display
	_display_results([result], results_label, family_slug)


static func _display_results(results: Array, results_label: Label, family_slug: String) -> void:
	var lines: PackedStringArray = PackedStringArray()
	var typed_results: Array[Dictionary] = []
	for r in results:
		typed_results.append(r as Dictionary)
	var summary := RunnerScript.get_summary(typed_results)
	
	for r in results:
		var result: Dictionary = r as Dictionary
		var status: String = String(result.get("status", ""))
		var upgrade_id: String = String(result.get("upgrade_id", ""))
		var target: String = String(result.get("target", ""))
		var reason: String = String(result.get("reason", ""))
		
		var icon: String
		match status:
			"PASS":
				icon = "PASS"
			"LOGIC_PASS":
				icon = "LOGIC"
			_:
				icon = status if status.begins_with("FAIL") else "MANUAL"
		
		lines.append("[%s] %s" % [icon, upgrade_id])
		if target != "":
			lines.append("  target: %s" % target)
		
		var before: Variant = result.get("before", null)
		var after: Variant = result.get("after", null)
		if before != null or after != null:
			lines.append("  %s -> %s" % [_format_value(before), _format_value(after)])
		
		if reason != "":
			lines.append("  reason: %s" % reason)
		lines.append("")
	
	if results.size() > 1:
		lines.append("--- %d PASS / %d LOGIC / %d FAIL / %d MANUAL ---" % [
			summary.pass, summary.logic_pass, summary.fail, summary.manual
		])
		lines.append("Reports saved to qa_reports/building_upgrade/%s/" % family_slug)
	
	results_label.text = "\n".join(lines)
	
	if summary.all_pass:
		results_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	elif summary.fail > 0:
		results_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		results_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))


static func _format_value(value: Variant) -> String:
	if value == null:
		return "-"
	if value is Dictionary:
		var d := value as Dictionary
		# Try to extract useful values
		if d.has("maxHp") or d.has("damage"):
			var hp := float(d.get("maxHp", -1.0))
			var dmg := float(d.get("damage", -1.0))
			var parts: PackedStringArray = PackedStringArray()
			if hp >= 0.0:
				parts.append("HP:%.0f" % hp)
			if dmg >= 0.0:
				parts.append("DMG:%.0f" % dmg)
			return "{%s}" % ", ".join(parts)
		return JSON.stringify(d)
	if value is Array:
		return JSON.stringify(value)
	if value is float:
		return "%.4f" % value
	return str(value)
