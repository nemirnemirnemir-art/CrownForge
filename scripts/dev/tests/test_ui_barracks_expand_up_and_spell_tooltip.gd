extends SceneTree

const BarracksTroopMenuScene := preload("res://scenes/ui/town/BarracksTroopMenu.tscn")
const SpellPanelScene := preload("res://scenes/ui/spells/SpellPanel.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var barracks := BarracksTroopMenuScene.instantiate() as PanelContainer
	if barracks == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] failed to instantiate BarracksTroopMenu")
		quit(1)
		return

	get_root().add_child(barracks)
	barracks.global_position = Vector2(700.0, 620.0)
	await process_frame

	if not barracks.has_method("_toggle_panel"):
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] _toggle_panel not found")
		quit(1)
		return

	barracks.call("_toggle_panel")
	await process_frame

	var header := barracks.get_node_or_null("Root/Header") as Control
	var panel := barracks.get_node_or_null("Root/Panel") as Control
	if header == null or panel == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] header/panel missing")
		quit(1)
		return

	if not panel.visible:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] panel must be visible after expand")
		quit(1)
		return

	var header_rect := header.get_global_rect()
	var panel_rect := panel.get_global_rect()
	if panel_rect.position.y + panel_rect.size.y > header_rect.position.y - 1.0:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] expanded panel must open upward")
		quit(1)
		return

	var spell_panel := SpellPanelScene.instantiate() as Control
	if spell_panel == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] failed to instantiate SpellPanel")
		quit(1)
		return

	get_root().add_child(spell_panel)
	await process_frame

	var slot := spell_panel.get_node_or_null("GridContainer/SpellSlot1") as Control
	if slot == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] SpellSlot1 missing")
		quit(1)
		return

	if not slot.has_method("add_spell"):
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] SpellSlot1 missing add_spell")
		quit(1)
		return

	var cfg := SpellConfig.new()
	cfg.spell_id = "test_spell"
	cfg.spell_name = "Test Spell"
	cfg.description = "Test spell description"
	slot.call("add_spell", cfg)

	if not slot.has_signal("slot_hover_started") or not slot.has_signal("slot_hover_ended"):
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] SpellSlot must expose hover signals")
		quit(1)
		return

	var slot_rect := slot.get_global_rect()
	slot.emit_signal("slot_hover_started", 0, cfg, slot_rect)
	await process_frame

	var tooltip := spell_panel.get_node_or_null("SpellTooltip") as PanelContainer
	if tooltip == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] SpellTooltip node missing")
		quit(1)
		return

	if not tooltip.visible:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] SpellTooltip must be visible on hover")
		quit(1)
		return

	var title := tooltip.get_node_or_null("Margin/VBox/Title") as Label
	var description := tooltip.get_node_or_null("Margin/VBox/Description") as Label
	if title == null or description == null:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] tooltip labels missing")
		quit(1)
		return

	if title.text != cfg.spell_name:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] tooltip title mismatch")
		quit(1)
		return

	if description.text != cfg.description:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] tooltip description mismatch")
		quit(1)
		return

	if tooltip.global_position.x >= slot_rect.position.x:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] tooltip must appear to the left of slot")
		quit(1)
		return

	slot.emit_signal("slot_hover_ended", 0)
	await process_frame
	if tooltip.visible:
		push_error("[test_ui_barracks_expand_up_and_spell_tooltip] tooltip must hide after hover end")
		quit(1)
		return

	print("[test_ui_barracks_expand_up_and_spell_tooltip] PASS")
	quit(0)
