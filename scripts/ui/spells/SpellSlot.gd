extends Control

## Individual spell slot - displays spell icon and stack count

signal slot_pressed(slot_index: int)
signal slot_hover_started(slot_index: int, config: SpellConfig, slot_rect: Rect2)
signal slot_hover_ended(slot_index: int)

@export var slot_index: int = 0

@onready var panel: Panel = $Panel
@onready var icon_rect: TextureRect = $Panel/IconRect
@onready var count_label: Label = $Panel/CountLabel

const SLOT_SIZE: float = 76.5

var spell_stack: Array[SpellConfig] = []
var _drag_highlight_active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_display()

func add_spell(config: SpellConfig) -> bool:
	if spell_stack.size() >= config.max_stacks:
		return false
	
	spell_stack.append(config)
	_update_display()
	return true

func remove_spell() -> SpellConfig:
	if spell_stack.is_empty():
		return null
	
	var config: SpellConfig = spell_stack.pop_back()
	_update_display()
	return config

func get_spell() -> SpellConfig:
	if spell_stack.is_empty():
		return null
	return spell_stack.back()

func is_empty() -> bool:
	return spell_stack.is_empty()

func get_stack_count() -> int:
	return spell_stack.size()

func _update_display() -> void:
	if not is_node_ready():
		return
	
	if spell_stack.is_empty():
		icon_rect.texture = null
		icon_rect.visible = false
		count_label.visible = false
	else:
		var config: SpellConfig = spell_stack.back()
		icon_rect.texture = config.get_icon_or_placeholder()
		icon_rect.visible = true
		
		if spell_stack.size() > 1:
			count_label.text = str(spell_stack.size())
			count_label.visible = true
		else:
			count_label.visible = false

func set_highlight(active: bool) -> void:
	_drag_highlight_active = active
	if panel:
		if active:
			# Bright green border effect
			panel.modulate = Color(0.5, 1.0, 0.5, 1.0)
		else:
			panel.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _gui_input(event: InputEvent) -> void:
	if spell_stack.is_empty():
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[SpellSlot %d] Left mouse PRESSED, emitting slot_pressed" % slot_index)
			slot_pressed.emit(slot_index)
			accept_event()

func _on_mouse_entered() -> void:
	if spell_stack.is_empty():
		return
	var config := get_spell()
	if config == null:
		return
	slot_hover_started.emit(slot_index, config, get_global_rect())

func _on_mouse_exited() -> void:
	slot_hover_ended.emit(slot_index)
