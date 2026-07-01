extends Node

## ForgePanelUI module
## Manages UI updates and status labels

var _cores_label: Label
var _status_label: Label
var _destroy_button: Button

func initialize(cores_label: Label, status_label: Label, destroy_button: Button) -> void:
	_cores_label = cores_label
	_status_label = status_label
	_destroy_button = destroy_button

func update_forge_label() -> void:
	var cores = EconomyCore.get_forge_cores() if EconomyCore else 0
	_cores_label.text = "Forge Cores: %d" % cores

func update_buttons(selected_index: int) -> void:
	_destroy_button.disabled = selected_index == -1

func update_status_color() -> void:
	if _status_label:
		_status_label.add_theme_color_override("font_color", Color(1, 1, 1))

func set_status_text(text: String) -> void:
	if _status_label:
		_status_label.text = text

