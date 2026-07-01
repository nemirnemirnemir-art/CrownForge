extends SceneTree

const SpellPanelScene := preload("res://scenes/ui/spells/SpellPanel.tscn")
const MIN_TOOLTIP_WIDTH: float = 500.0
const MIN_TITLE_FONT_SIZE: int = 28
const MIN_DESCRIPTION_FONT_SIZE: int = 22
const MIN_HORIZONTAL_MARGIN: int = 18
const MIN_VERTICAL_MARGIN: int = 14
const MIN_CONTENT_SEPARATION: int = 8

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_spell_panel_tooltip_readability_runtime] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var panel := SpellPanelScene.instantiate() as Control
	if panel == null:
		_fail("failed to instantiate SpellPanel")
		return

	root.add_child(panel)
	await process_frame
	await process_frame

	var slot := panel.get_node_or_null("GridContainer/SpellSlot1") as Control
	if slot == null:
		_fail("SpellSlot1 not found")
		return

	var config := SpellConfig.new()
	config.spell_id = "readability_spell"
	config.spell_name = "Readability Spell"
	config.description = "A deliberately long tooltip description that must remain easy to read in runtime, with enough width, padding, and font size to avoid cramped wrapping."

	var slot_rect := slot.get_global_rect()
	slot.emit_signal("slot_hover_started", 0, config, slot_rect)
	await process_frame
	await process_frame

	var tooltip := panel.get_node_or_null("SpellTooltip") as PanelContainer
	if tooltip == null:
		_fail("SpellTooltip node missing")
		return
	if not tooltip.visible:
		_fail("SpellTooltip must be visible on hover")
		return
	if tooltip.size.x < MIN_TOOLTIP_WIDTH:
		_fail("tooltip width %.1f is below minimum %.1f" % [tooltip.size.x, MIN_TOOLTIP_WIDTH])
		return

	var margin := tooltip.get_node_or_null("Margin") as MarginContainer
	var vbox := tooltip.get_node_or_null("Margin/VBox") as VBoxContainer
	var title := tooltip.get_node_or_null("Margin/VBox/Title") as Label
	var description := tooltip.get_node_or_null("Margin/VBox/Description") as Label
	if margin == null or vbox == null or title == null or description == null:
		_fail("tooltip content nodes missing")
		return

	if title.get_theme_font_size("font_size") < MIN_TITLE_FONT_SIZE:
		_fail("title font size %d is below minimum %d" % [title.get_theme_font_size("font_size"), MIN_TITLE_FONT_SIZE])
		return
	if description.get_theme_font_size("font_size") < MIN_DESCRIPTION_FONT_SIZE:
		_fail("description font size %d is below minimum %d" % [description.get_theme_font_size("font_size"), MIN_DESCRIPTION_FONT_SIZE])
		return

	if margin.get_theme_constant("margin_left") < MIN_HORIZONTAL_MARGIN or margin.get_theme_constant("margin_right") < MIN_HORIZONTAL_MARGIN:
		_fail("horizontal tooltip padding is too small")
		return
	if margin.get_theme_constant("margin_top") < MIN_VERTICAL_MARGIN or margin.get_theme_constant("margin_bottom") < MIN_VERTICAL_MARGIN:
		_fail("vertical tooltip padding is too small")
		return
	if vbox.get_theme_constant("separation") < MIN_CONTENT_SEPARATION:
		_fail("tooltip content separation is too small")
		return

	slot.emit_signal("slot_hover_ended", 0)
	await process_frame
	if tooltip.visible:
		_fail("SpellTooltip must hide after hover end")
		return

	print("[test_spell_panel_tooltip_readability_runtime] PASS")
	quit(0)
