extends ColorRect
class_name GameOverPanel

signal restart_requested

@onready var restart_button: Button = $RestartButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	restart_requested.emit()
