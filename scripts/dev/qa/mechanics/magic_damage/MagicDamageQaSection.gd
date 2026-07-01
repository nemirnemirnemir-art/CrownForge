extends RefCounted
class_name MagicDamageQaSection

## Builds the MAGIC DAMAGE section for the F11 QA panel.
## Each scenario gets its own button so tests can be run individually.
## Also has a "Run All 6" button and a "Save Report" button.

const CatalogScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageScenarioCatalog.gd")
const RunnerScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageRunner.gd")
const ReportStoreScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageReportStore.gd")


## Build and return the complete section as a VBoxContainer.
## The caller (BuildingUpgradeQaPanel) adds this to its main layout.
static func build_section(tree: SceneTree) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Section header
	var header_panel := PanelContainer.new()
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(0.3, 0.15, 0.4, 1.0)
	header_style.set_corner_radius_all(4)
	header_panel.add_theme_stylebox_override("panel", header_style)
	section.add_child(header_panel)

	var header_label := Label.new()
	header_label.text = "MAGIC DAMAGE TESTER"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 32)
	header_panel.add_child(header_label)

	# Results display area
	var results_label := Label.new()
	results_label.name = "MagicDamageResults"
	results_label.text = "Ready. Press a button to run a scenario."
	results_label.add_theme_font_size_override("font_size", 24)
	results_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))

	# "Run All 6" button
	var run_all_btn := Button.new()
	run_all_btn.text = "Run All 6 Scenarios"
	run_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_all_btn.custom_minimum_size = Vector2(0.0, 64.0)
	run_all_btn.add_theme_font_size_override("font_size", 24)
	run_all_btn.pressed.connect(_on_run_all.bind(results_label, tree))
	section.add_child(run_all_btn)

	section.add_child(HSeparator.new())

	# Per-scenario buttons
	var scenarios := CatalogScript.get_all_scenarios()
	for scenario: Dictionary in scenarios:
		var sid: String = String(scenario.get("id", ""))
		var label_text: String = String(scenario.get("label", sid))
		var expected_mult: float = float(scenario.get("expected_multiplier", 1.0))
		var expected_dmg: float = float(scenario.get("expected_damage", 110.0))

		var btn := Button.new()
		btn.text = "%s  [expect x%.2f = %.0f dmg]" % [label_text, expected_mult, expected_dmg]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0.0, 56.0)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_run_single.bind(sid, results_label, tree))
		section.add_child(btn)

	section.add_child(HSeparator.new())

	# Results label (added after buttons so it appears at the bottom)
	section.add_child(results_label)

	return section


static func _on_run_all(results_label: Label, tree: SceneTree) -> void:
	results_label.text = "Running all 6 scenarios..."
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	# Yield a frame so the UI updates before the blocking probe work
	await tree.process_frame

	var results := RunnerScript.run_all()

	# Save reports to disk
	ReportStoreScript.save_report(results)

	# Display results
	_display_results(results, results_label)


static func _on_run_single(scenario_id: String, results_label: Label, tree: SceneTree) -> void:
	results_label.text = "Running: %s..." % scenario_id
	results_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	await tree.process_frame

	var result := RunnerScript.run_scenario(scenario_id)

	# Save single result
	ReportStoreScript.save_single_result(result)

	# Display
	_display_results([result], results_label)


static func _display_results(results: Array, results_label: Label) -> void:
	var lines: PackedStringArray = PackedStringArray()
	var all_pass := true

	for r in results:
		var result: Dictionary = r as Dictionary
		var status: String = String(result.get("status", ""))
		var label_text: String = String(result.get("label", result.get("scenario_id", "")))
		var actual_m: float = float(result.get("actual_multiplier", 0.0))
		var expected_m: float = float(result.get("expected_multiplier", 0.0))
		var actual_d: float = float(result.get("actual_damage", 0.0))
		var expected_d: float = float(result.get("expected_damage", 0.0))

		var icon: String = "PASS" if status == "PASS" else "FAIL"
		if status != "PASS":
			all_pass = false

		lines.append("[%s] %s" % [icon, label_text])
		lines.append("  mult: %.4f (expect %.4f)  dmg: %.1f (expect %.1f)" % [
			actual_m, expected_m, actual_d, expected_d
		])
		var reason: String = String(result.get("reason", ""))
		if reason != "":
			lines.append("  reason: %s" % reason)
		lines.append("")

	if results.size() > 1:
		var pass_count := 0
		for r in results:
			if String((r as Dictionary).get("status", "")) == "PASS":
				pass_count += 1
		lines.append("--- %d/%d PASS ---" % [pass_count, results.size()])
		lines.append("Reports saved to qa_reports/mechanics/magic_damage/")

	results_label.text = "\n".join(lines)
	if all_pass:
		results_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
	else:
		results_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
