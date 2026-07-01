extends Control

signal pressed(slot_index: int)
signal hover_started(slot_index: int)
signal hover_ended(slot_index: int)

@export var slot_index: int = 0
@export var slot_size: Vector2 = Vector2(68.0, 68.0)
@export_range(1.0, 3.0, 0.05) var icon_scale_multiplier: float = 1.0

@onready var panel: Panel = $Panel
@onready var icon_rect: TextureRect = $Panel/IconRect
@onready var state_overlay: ColorRect = $Panel/StateOverlay
@onready var cooldown_label: Label = $Panel/CooldownLabel

var _config: SpellConfig = null
var _empty_texture: Texture2D = null
var _disabled: bool = false
var _cooldown_left: float = 0.0
var _passive_shape: bool = false

func _ready() -> void:
	_apply_layout()
	_refresh()
	tooltip_text = ""
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func configure(new_slot_index: int, new_slot_size: Vector2, new_icon_scale_multiplier: float, empty_texture: Texture2D, use_passive_shape: bool = false) -> void:
	slot_index = new_slot_index
	slot_size = new_slot_size
	icon_scale_multiplier = new_icon_scale_multiplier
	_empty_texture = empty_texture
	_passive_shape = use_passive_shape
	if is_node_ready():
		_apply_layout()
		_refresh()

func set_spell(config: SpellConfig) -> void:
	_config = config
	if is_node_ready():
		_refresh()

func clear_spell() -> void:
	_config = null
	if is_node_ready():
		_refresh()

func set_disabled_state(disabled_state: bool) -> void:
	_disabled = disabled_state
	if is_node_ready():
		_refresh()

func set_cooldown_left(seconds_left: float) -> void:
	_cooldown_left = maxf(0.0, seconds_left)
	if is_node_ready():
		_refresh()

func get_spell_id() -> String:
	if _config == null:
		return ""
	return String(_config.spell_id)

func get_spell_config() -> SpellConfig:
	return _config

func _apply_layout() -> void:
	custom_minimum_size = slot_size
	if panel:
		panel.custom_minimum_size = slot_size
	if icon_rect == null:
		return
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _config == null:
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.offset_left = 5.0
		icon_rect.offset_top = 5.0
		icon_rect.offset_right = -5.0
		icon_rect.offset_bottom = -5.0
		return
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var base_padding := 5.0
	if _passive_shape:
		base_padding = 3.0
	var extra_x := maxf(0.0, slot_size.x * (icon_scale_multiplier - 1.0) * 0.5)
	var extra_y := maxf(0.0, slot_size.y * (icon_scale_multiplier - 1.0) * 0.5)
	icon_rect.offset_left = base_padding - extra_x
	icon_rect.offset_top = base_padding - extra_y
	icon_rect.offset_right = -base_padding + extra_x
	icon_rect.offset_bottom = -base_padding + extra_y

func _refresh() -> void:
	if not is_node_ready():
		return
	_apply_layout()
	if _config == null:
		icon_rect.texture = _empty_texture
		icon_rect.visible = _empty_texture != null
		if state_overlay:
			state_overlay.visible = false
		if cooldown_label:
			cooldown_label.visible = false
		return
	icon_rect.texture = _config.get_icon_or_placeholder()
	icon_rect.visible = true
	if icon_rect:
		if _disabled:
			icon_rect.modulate = Color(0.45, 0.45, 0.45, 1.0)
		else:
			icon_rect.modulate = Color.WHITE
	if state_overlay:
		state_overlay.visible = _disabled or _cooldown_left > 0.0
	if cooldown_label:
		cooldown_label.visible = _cooldown_left > 0.0
		if _cooldown_left > 0.0:
			cooldown_label.text = str(int(ceili(_cooldown_left)))
		else:
			cooldown_label.text = ""

func _gui_input(event: InputEvent) -> void:
	if _config == null:
		return
	if _disabled or _cooldown_left > 0.0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(slot_index)
		accept_event()

func _on_mouse_entered() -> void:
	if _config != null:
		hover_started.emit(slot_index)

func _on_mouse_exited() -> void:
	hover_ended.emit(slot_index)
