extends ColorRect
class_name VictoryPanel

@onready var title_label: Label = $TitleLabel


func show_victory() -> void:
	visible = true
	if title_label:
		title_label.text = "Вы победили"
