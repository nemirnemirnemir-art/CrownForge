extends CanvasLayer
class_name BuildingUpgradeQaPanel

## Hidden QA workbench for building upgrade verification.
## Toggle with F11. Uses family selector dropdown to show one family at a time.
## Reports are saved to qa_reports/building_upgrade/<family_slug>/ on each run.

const QaRunnerScript := preload("res://scripts/dev/qa/BuildingUpgradeQaRunner.gd")
const QaReportStoreScript := preload("res://scripts/dev/qa/BuildingUpgradeQaReportStore.gd")
const MagicDamageQaSectionScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageQaSection.gd")
const FamilyRegistryScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRegistry.gd")
const FamilySectionScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaSection.gd")
const FamilyRunnerScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaRunner.gd")
const FamilyReportStoreScript := preload("res://scripts/dev/qa/families/BuildingUpgradeFamilyQaReportStore.gd")

var _panel: PanelContainer
var _family_selector: OptionButton
var _family_section_container: Control
var _current_family_section: Control = null
var _status_label: Label
var _last_results: Array[Dictionary] = []
var _run_failed_btn: Button


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_process_input(true)
    layer = 101  # above DebugSpawnMenu (layer 100)
    _build_ui()
    visible = false


func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_F11:
            visible = not visible


func _build_ui() -> void:
    _panel = PanelContainer.new()
    _panel.custom_minimum_size = Vector2(950.0, 1100.0)
    _panel.anchor_left = 0.0
    _panel.anchor_top = 0.0
    _panel.anchor_right = 0.0
    _panel.anchor_bottom = 0.0
    _panel.offset_left = 10.0
    _panel.offset_top = 10.0
    _panel.offset_right = 960.0
    _panel.offset_bottom = 1110.0
    add_child(_panel)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.08, 0.12, 0.96)
    style.border_color = Color(0.4, 0.4, 0.5)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    _panel.add_theme_stylebox_override("panel", style)

    var main_vbox := VBoxContainer.new()
    main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _panel.add_child(main_vbox)

    # Title bar
    var title_bar := PanelContainer.new()
    var title_style := StyleBoxFlat.new()
    title_style.bg_color = Color(0.2, 0.2, 0.3, 1.0)
    title_style.set_corner_radius_all(4)
    title_bar.add_theme_stylebox_override("panel", title_style)
    main_vbox.add_child(title_bar)

    var title := Label.new()
    title.text = "BUILDING UPGRADE QA (F11)"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title_bar.add_child(title)

    main_vbox.add_child(HSeparator.new())

    # ── Family selector row ──
    var selector_row := HBoxContainer.new()
    selector_row.custom_minimum_size = Vector2(0.0, 56.0)
    main_vbox.add_child(selector_row)

    var selector_label := Label.new()
    selector_label.text = "Family: "
    selector_label.add_theme_font_size_override("font_size", 24)
    selector_row.add_child(selector_label)

    _family_selector = OptionButton.new()
    _family_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _family_selector.custom_minimum_size = Vector2(0.0, 48.0)
    _family_selector.add_theme_font_size_override("font_size", 22)
    _populate_family_selector()
    _family_selector.item_selected.connect(_on_family_selected)
    selector_row.add_child(_family_selector)

    main_vbox.add_child(HSeparator.new())

    # ── Family section container (shows one section at a time) ──
    _family_section_container = VBoxContainer.new()
    _family_section_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _family_section_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main_vbox.add_child(_family_section_container)

    # Load initial family section
    _load_family_section(0)

    main_vbox.add_child(HSeparator.new())

    # ── Aggregate controls row ──
    var aggregate_row := HBoxContainer.new()
    aggregate_row.custom_minimum_size = Vector2(0.0, 64.0)
    main_vbox.add_child(aggregate_row)

    var run_all_v1_btn := Button.new()
    run_all_v1_btn.text = "Run All V1 Families"
    run_all_v1_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    run_all_v1_btn.custom_minimum_size = Vector2(0.0, 56.0)
    run_all_v1_btn.add_theme_font_size_override("font_size", 22)
    run_all_v1_btn.pressed.connect(_on_run_all_v1)
    aggregate_row.add_child(run_all_v1_btn)

    var run_legacy_btn := Button.new()
    run_legacy_btn.text = "Run All 141 (Legacy)"
    run_legacy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    run_legacy_btn.custom_minimum_size = Vector2(0.0, 56.0)
    run_legacy_btn.add_theme_font_size_override("font_size", 22)
    run_legacy_btn.pressed.connect(_on_run_legacy)
    aggregate_row.add_child(run_legacy_btn)

    main_vbox.add_child(HSeparator.new())

    # Status line
    _status_label = Label.new()
    _status_label.text = "Ready. Select a family and run tests."
    _status_label.add_theme_font_size_override("font_size", 24)
    _status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    main_vbox.add_child(_status_label)


func _populate_family_selector() -> void:
    # Add magic damage as special first option
    _family_selector.add_item("Magic Damage (Custom)", 0)
    _family_selector.set_item_metadata(0, {"type": "magic_damage"})

    # Add V1 families from registry
    var families := FamilyRegistryScript.get_v1_families()
    for i: int in families.size():
        var family: Dictionary = families[i]
        var label: String = String(family.get("label", ""))
        var slug: String = String(family.get("slug", ""))
        var runtime_backed: bool = bool(family.get("runtime_backed", false))
        var suffix := " (Runtime)" if runtime_backed else " (Logic)"
        _family_selector.add_item(label + suffix, i + 1)
        _family_selector.set_item_metadata(i + 1, {"type": "family", "slug": slug})


func _on_family_selected(index: int) -> void:
    _load_family_section(index)


func _load_family_section(index: int) -> void:
    # Remove current section
    if _current_family_section != null:
        _family_section_container.remove_child(_current_family_section)
        _current_family_section.queue_free()
        _current_family_section = null

    var metadata: Dictionary = _family_selector.get_item_metadata(index) as Dictionary
    var section_type: String = String(metadata.get("type", ""))

    match section_type:
        "magic_damage":
            _current_family_section = MagicDamageQaSectionScript.build_section(get_tree())
        "family":
            var slug: String = String(metadata.get("slug", ""))
            _current_family_section = FamilySectionScript.build_section(slug, get_tree())
        _:
            var error_section := VBoxContainer.new()
            var error_label := Label.new()
            error_label.text = "Unknown section type"
            error_label.add_theme_font_size_override("font_size", 24)
            error_section.add_child(error_label)
            _current_family_section = error_section

    if _current_family_section != null:
        _family_section_container.add_child(_current_family_section)


func _on_run_all_v1() -> void:
    _status_label.text = "Running all V1 families..."
    _status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    await get_tree().process_frame

    var results := FamilyRunnerScript.run_all_v1()

    # Save aggregate report
    FamilyReportStoreScript.save_aggregate_report(results)

    # Get summary
    var summary := FamilyRunnerScript.get_summary(results)
    _status_label.text = "V1 Complete: %d PASS / %d LOGIC / %d FAIL / %d MANUAL — Reports: qa_reports/building_upgrade/_aggregate/" % [
        summary.pass, summary.logic_pass, summary.fail, summary.manual
    ]

    if summary.all_pass:
        _status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
    elif summary.fail > 0:
        _status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
    else:
        _status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))


func _on_run_legacy() -> void:
    _status_label.text = "Running all 141 entries (legacy)..."
    _status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
    await get_tree().process_frame

    _last_results = QaRunnerScript.run_all()
    _save_legacy_reports(_last_results)
    _update_legacy_status(_last_results)


func _save_legacy_reports(results: Array[Dictionary]) -> void:
    QaReportStoreScript.save_latest(results)
    QaReportStoreScript.save_latest_failed(results)
    QaReportStoreScript.save_history(results)
    QaReportStoreScript.save_markdown(results)


func _update_legacy_status(results: Array[Dictionary]) -> void:
    var pass_count := 0
    var fail_count := 0
    var manual_count := 0
    for result in results:
        var s: String = result.get("status", "")
        if s == "PASS":
            pass_count += 1
        elif s.begins_with("FAIL"):
            fail_count += 1
        else:
            manual_count += 1
    _status_label.text = "Legacy done: %d PASS  %d FAIL  %d MANUAL — res://qa_reports/building_upgrade/" % [
        pass_count, fail_count, manual_count
    ]

    if fail_count == 0 and manual_count == 0:
        _status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
    elif fail_count > 0:
        _status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
    else:
        _status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
