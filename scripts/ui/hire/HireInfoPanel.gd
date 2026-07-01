extends PanelContainer
class_name HireInfoPanel

@onready var info_label: Label = $HireInfoLabel

func set_text(text: String) -> void:
	if info_label:
		info_label.text = text
