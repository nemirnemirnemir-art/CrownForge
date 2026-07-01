extends Control
class_name OptionsSlider

signal value_changed(new_value: int)

@export var title: String = "Volume"
@export var min_value: int = 0
@export var max_value: int = 100
@export var current_value: int = 50:
	set(v):
		current_value = clampi(v, min_value, max_value)
		_update_visuals()

@export var tick_delay_initial: float = 0.4
@export var tick_delay_min: float = 0.05

@onready var _title_label: Label = $Title
@onready var _value_label: Label = $ValueLabel
@onready var _fill_rect: TextureRect = $Track/FillClip/Fill
@onready var _fill_clip: Control = $Track/FillClip

var _hold_dir: int = 0
var _hold_timer: float = 0.0
var _current_tick_delay: float = 0.0
var _tick_multiplier: int = 1

func _ready() -> void:
	if _title_label:
		_title_label.text = title
	_update_visuals()

func _process(delta: float) -> void:
	if _hold_dir != 0:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_apply_step(_hold_dir * _tick_multiplier)
			_tick_multiplier = mini(_tick_multiplier * 2, 20)
			_current_tick_delay = maxf(tick_delay_min, _current_tick_delay * 0.75)
			_hold_timer = _current_tick_delay

func _update_visuals() -> void:
	if _value_label:
		_value_label.text = str(current_value)
	if _fill_clip and _fill_rect:
		var ratio := float(current_value - min_value) / float(max_value - min_value)
		_fill_clip.size.x = _fill_rect.size.x * ratio

func _apply_step(amount: int) -> void:
	var old_val := current_value
	current_value += amount
	if current_value != old_val:
		value_changed.emit(current_value)

func _start_hold(dir: int) -> void:
	_hold_dir = dir
	_apply_step(dir)
	_tick_multiplier = 1
	_current_tick_delay = tick_delay_initial
	_hold_timer = _current_tick_delay

func _stop_hold() -> void:
	_hold_dir = 0

func _on_left_button_down() -> void:
	_start_hold(-1)

func _on_left_button_up() -> void:
	_stop_hold()

func _on_right_button_down() -> void:
	_start_hold(1)

func _on_right_button_up() -> void:
	_stop_hold()

func _on_track_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var ratio := clampf(mb.position.x / $Track.size.x, 0.0, 1.0)
			var new_val := min_value + int(round(ratio * (max_value - min_value)))
			if new_val != current_value:
				current_value = new_val
				value_changed.emit(current_value)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			var ratio := clampf(mm.position.x / $Track.size.x, 0.0, 1.0)
			var new_val := min_value + int(round(ratio * (max_value - min_value)))
			if new_val != current_value:
				current_value = new_val
				value_changed.emit(current_value)
