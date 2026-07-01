extends Control

## Spell panel UI - manages 9 spell slots with configurable visibility

signal spell_cast_requested(config: SpellConfig, target_pos: Vector2)
signal spell_targeting_started(config: SpellConfig)
signal spell_targeting_cancelled()

@export_range(1, 9) var active_slots: int = 6  ## Number of visible slots (configurable in inspector)

@onready var grid: GridContainer = $GridContainer
var slots: Array[Control] = []

var _dragging_slot: int = -1
var _active_spell_config: SpellConfig = null
var _spell_tooltip: PanelContainer = null
var _spell_tooltip_title: Label = null
var _spell_tooltip_description: Label = null

const SPELL_TOOLTIP_MARGIN: float = 12.0
const SPELL_TOOLTIP_SCREEN_PADDING: float = 8.0
const SPELL_TOOLTIP_MIN_WIDTH: float = 560.0
const SPELL_TOOLTIP_PADDING_X: int = 20
const SPELL_TOOLTIP_PADDING_Y: int = 16
const SPELL_TOOLTIP_CONTENT_SEPARATION: int = 10
const SPELL_TOOLTIP_TITLE_FONT_SIZE: int = 30
const SPELL_TOOLTIP_DESCRIPTION_FONT_SIZE: int = 24

func _ready() -> void:
	add_to_group("spell_panel")
	set_process_unhandled_input(true)
	_ensure_spell_tooltip()
	
	# Collect all slot references
	for i in range(9):
		var slot: Control = grid.get_node_or_null("SpellSlot" + str(i + 1))
		if slot:
			slots.append(slot)
			slot.slot_index = i
			slot.slot_pressed.connect(_on_slot_pressed)
			if slot.has_signal("slot_hover_started"):
				slot.slot_hover_started.connect(_on_slot_hover_started)
			if slot.has_signal("slot_hover_ended"):
				slot.slot_hover_ended.connect(_on_slot_hover_ended)
		else:
			slots.append(null)
	
	_update_slot_visibility()

func _update_slot_visibility() -> void:
	for i in range(slots.size()):
		if slots[i]:
			slots[i].visible = (i < active_slots)

func add_spell(config: SpellConfig) -> bool:
	if not config:
		return false
	
	# Try to stack with existing spell of same type
	for slot in slots:
		if slot and slot.visible and not slot.is_empty():
			var existing: SpellConfig = slot.get_spell()
			if existing and existing.spell_id == config.spell_id:
				if slot.add_spell(config):
					return true
	
	# Find first empty visible slot
	for slot in slots:
		if slot and slot.visible and slot.is_empty():
			return slot.add_spell(config)
	
	# All slots full - spell is discarded
	# print("[SpellPanel] All slots full, spell discarded: %s" % config.spell_id)
	return false

func _on_slot_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	
	var slot: Control = slots[slot_index]
	if not slot or slot.is_empty():
		return
	
	# If already targeting this slot, cancel it
	if _dragging_slot == slot_index:
		_cancel_targeting()
		return
		
	# Cancel any existing targeting
	if _active_spell_config:
		_cancel_targeting()
	_hide_spell_tooltip()
	
	_dragging_slot = slot_index
	_active_spell_config = slot.get_spell()
	print("[SpellPanel] Targeting started for slot %d, spell %s" % [slot_index, _active_spell_config.spell_id if _active_spell_config else "null"])
	
	slot.set_highlight(true)
	
	if _active_spell_config:
		spell_targeting_started.emit(_active_spell_config)

func _unhandled_input(event: InputEvent) -> void:
	if not _active_spell_config:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print("[SpellPanel] Right click detected, cancelling targeting")
			_cancel_targeting()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			print("[SpellPanel] Left click detected, processing cast")
			_handle_cast_click()
			get_viewport().set_input_as_handled()

func _handle_cast_click() -> void:
	if _dragging_slot == -1 or not _active_spell_config:
		return
	
	# Check if mouse is in UI zone (bottom 35% of screen) - cancel cast and return spell
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var ui_zone_threshold: float = viewport_size.y * 0.65  # Top 65% is valid, bottom 35% is UI zone
	
	if mouse_pos.y > ui_zone_threshold:
		# Mouse is in UI zone - don't cast, spell stays in slot
		print("[SpellPanel] Spell cast cancelled - clicked in UI zone")
		_cancel_targeting()
		return
	
	# Cast spell at mouse position (pass viewport coords, GameScene will convert)
	print("[SpellPanel] Emitting spell_cast_requested")
	spell_cast_requested.emit(_active_spell_config, mouse_pos)
	_hide_spell_tooltip()
	
	# Emitting cancelled so targeting visual UI is properly removed
	spell_targeting_cancelled.emit()
	
	# Remove spell from slot
	if _dragging_slot >= 0 and _dragging_slot < slots.size():
		var slot: Control = slots[_dragging_slot]
		if slot:
			slot.set_highlight(false)
			slot.remove_spell()
	
	_dragging_slot = -1
	_active_spell_config = null

func _cancel_targeting() -> void:
	print("[SpellPanel] _cancel_targeting called")
	if _dragging_slot == -1 or not _active_spell_config:
		return
	var slot: Control = slots[_dragging_slot]
	if slot:
		slot.set_highlight(false)
	_hide_spell_tooltip()
	_dragging_slot = -1
	_active_spell_config = null
	spell_targeting_cancelled.emit()

func _ensure_spell_tooltip() -> void:
	if _spell_tooltip != null and is_instance_valid(_spell_tooltip):
		return

	_spell_tooltip = PanelContainer.new()
	_spell_tooltip.name = "SpellTooltip"
	_spell_tooltip.visible = false
	_spell_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_tooltip.top_level = true
	_spell_tooltip.z_index = 400
	_spell_tooltip.custom_minimum_size = Vector2(SPELL_TOOLTIP_MIN_WIDTH, 0.0)
	add_child(_spell_tooltip)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.9, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.18, 0.18, 0.18, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	_spell_tooltip.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", SPELL_TOOLTIP_PADDING_X)
	margin.add_theme_constant_override("margin_top", SPELL_TOOLTIP_PADDING_Y)
	margin.add_theme_constant_override("margin_right", SPELL_TOOLTIP_PADDING_X)
	margin.add_theme_constant_override("margin_bottom", SPELL_TOOLTIP_PADDING_Y)
	_spell_tooltip.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", SPELL_TOOLTIP_CONTENT_SEPARATION)
	margin.add_child(vbox)

	_spell_tooltip_title = Label.new()
	_spell_tooltip_title.name = "Title"
	_spell_tooltip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_spell_tooltip_title.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0))
	_spell_tooltip_title.add_theme_font_size_override("font_size", SPELL_TOOLTIP_TITLE_FONT_SIZE)
	vbox.add_child(_spell_tooltip_title)

	_spell_tooltip_description = Label.new()
	_spell_tooltip_description.name = "Description"
	_spell_tooltip_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_spell_tooltip_description.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12, 1.0))
	_spell_tooltip_description.add_theme_font_size_override("font_size", SPELL_TOOLTIP_DESCRIPTION_FONT_SIZE)
	vbox.add_child(_spell_tooltip_description)

func _on_slot_hover_started(_slot_index: int, config: SpellConfig, slot_rect: Rect2) -> void:
	if config == null:
		_hide_spell_tooltip()
		return
	_show_spell_tooltip(config, slot_rect)

func _on_slot_hover_ended(_slot_index: int) -> void:
	_hide_spell_tooltip()

func _show_spell_tooltip(config: SpellConfig, slot_rect: Rect2) -> void:
	_ensure_spell_tooltip()
	if _spell_tooltip == null:
		return

	_spell_tooltip_title.text = config.spell_name if config.spell_name != "" else config.spell_id.capitalize().replace("_", " ")
	_spell_tooltip_description.text = config.description if config.description != "" else "No description available yet."

	_spell_tooltip.reset_size()
	var tooltip_size := _spell_tooltip.get_combined_minimum_size()
	if tooltip_size == Vector2.ZERO:
		tooltip_size = _spell_tooltip.custom_minimum_size
	_spell_tooltip.size = tooltip_size

	var pos := Vector2(
		slot_rect.position.x - tooltip_size.x - SPELL_TOOLTIP_MARGIN,
		slot_rect.position.y + (slot_rect.size.y - tooltip_size.y) * 0.5
	)

	var viewport_size := get_viewport().get_visible_rect().size
	pos.x = clampf(pos.x, SPELL_TOOLTIP_SCREEN_PADDING, maxf(SPELL_TOOLTIP_SCREEN_PADDING, viewport_size.x - tooltip_size.x - SPELL_TOOLTIP_SCREEN_PADDING))
	pos.y = clampf(pos.y, SPELL_TOOLTIP_SCREEN_PADDING, maxf(SPELL_TOOLTIP_SCREEN_PADDING, viewport_size.y - tooltip_size.y - SPELL_TOOLTIP_SCREEN_PADDING))

	_spell_tooltip.global_position = pos
	_spell_tooltip.visible = true

func _hide_spell_tooltip() -> void:
	if _spell_tooltip and is_instance_valid(_spell_tooltip):
		_spell_tooltip.visible = false
