extends SceneTree

const EncounterMenuScene := preload("res://scenes/ui/encounters/EncounterMenu.tscn")

var _selected_encounter_id: String = ""
var _selected_option_id: String = ""


func _init() -> void:
	var menu := EncounterMenuScene.instantiate()
	if menu == null:
		push_error("[test_encounter_menu_disables_unavailable_options] failed to instantiate EncounterMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: Control) -> void:
	if not menu.has_signal("option_selected"):
		push_error("[test_encounter_menu_disables_unavailable_options] EncounterMenu must expose option_selected signal")
		quit(1)
		return

	menu.option_selected.connect(_on_option_selected)

	var encounter := {
		"id": "test_encounter",
		"title": "Test Encounter",
		"options": [
			{
				"id": "locked",
				"label": "Locked Option",
				"effects_text": "+30 wood",
				"effects_rows": [
					{
						"icon_path": "res://assets/items/resources/wood_1.png",
						"text": "+30 wood"
					}
				],
				"enabled": false,
				"requirements_text": "Need 50 wine",
				"requirements_rows": [
					{
						"icon_path": "res://assets/items/resources/wine.png",
						"text": "Need 50 wine",
						"met": false
					}
				]
			},
			{
				"id": "open",
				"label": "Open Option",
				"effects_text": "+120 gold",
				"effects_rows": [
					{
						"icon_path": "res://assets/items/resources/gold_4.png",
						"text": "+120 gold"
					}
				],
				"enabled": true
			}
		]
	}

	menu.open(encounter)
	await process_frame

	var options_box := menu.get_node_or_null("Root/Panel/Margin/Options") as VBoxContainer
	if options_box == null:
		push_error("[test_encounter_menu_disables_unavailable_options] options container not found")
		quit(1)
		return

	if options_box.get_child_count() != 2:
		push_error("[test_encounter_menu_disables_unavailable_options] expected 2 option buttons, got %d" % options_box.get_child_count())
		quit(1)
		return

	var locked_button := options_box.get_child(0) as Button
	var open_button := options_box.get_child(1) as Button
	if locked_button == null or open_button == null:
		push_error("[test_encounter_menu_disables_unavailable_options] option nodes must be Button")
		quit(1)
		return

	if not locked_button.disabled:
		push_error("[test_encounter_menu_disables_unavailable_options] locked option button must be disabled")
		quit(1)
		return

	if locked_button.text.find("+30 wood") == -1:
		push_error("[test_encounter_menu_disables_unavailable_options] locked option button must show effects text")
		quit(1)
		return

	if _count_icons(locked_button) <= 0:
		push_error("[test_encounter_menu_disables_unavailable_options] locked option button must render at least one icon")
		quit(1)
		return

	if open_button.disabled:
		push_error("[test_encounter_menu_disables_unavailable_options] open option button must be enabled")
		quit(1)
		return

	if open_button.text.find("+120 gold") == -1:
		push_error("[test_encounter_menu_disables_unavailable_options] open option button must show effects text")
		quit(1)
		return

	if _count_icons(open_button) <= 0:
		push_error("[test_encounter_menu_disables_unavailable_options] open option button must render at least one icon")
		quit(1)
		return

	open_button.emit_signal("pressed")
	await process_frame

	if _selected_encounter_id != "test_encounter" or _selected_option_id != "open":
		push_error("[test_encounter_menu_disables_unavailable_options] option_selected emitted wrong payload: %s/%s" % [_selected_encounter_id, _selected_option_id])
		quit(1)
		return

	if menu.visible:
		push_error("[test_encounter_menu_disables_unavailable_options] menu must hide after option selection")
		quit(1)
		return

	print("[test_encounter_menu_disables_unavailable_options] PASS")
	quit(0)


func _on_option_selected(encounter_id: String, option_id: String) -> void:
	_selected_encounter_id = encounter_id
	_selected_option_id = option_id


func _count_icons(root: Node) -> int:
	var count := 0
	if root is TextureRect:
		var icon := root as TextureRect
		if icon.texture != null:
			count += 1
	for child in root.get_children():
		count += _count_icons(child)
	return count
