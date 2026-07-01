extends Control
class_name SettingsMenu

signal close_requested
signal show_fps_changed(enabled: bool)

@onready var show_fps_button: Button = $CenterPanel/VBoxContainer/ShowFPSButton
@onready var return_button: Button = $CenterPanel/VBoxContainer/ReturnButton

func _ready() -> void:
	if show_fps_button:
		show_fps_button.toggle_mode = true
		if not show_fps_button.toggled.is_connected(_on_show_fps_toggled):
			show_fps_button.toggled.connect(_on_show_fps_toggled)

	if return_button:
		if not return_button.pressed.is_connected(_on_return_pressed):
			return_button.pressed.connect(_on_return_pressed)

func set_show_fps_enabled(enabled: bool) -> void:
	if show_fps_button:
		show_fps_button.button_pressed = enabled

func _on_show_fps_toggled(pressed: bool) -> void:
	show_fps_changed.emit(pressed)

func _on_return_pressed() -> void:
	close_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_requested.emit()
			get_viewport().set_input_as_handled()
