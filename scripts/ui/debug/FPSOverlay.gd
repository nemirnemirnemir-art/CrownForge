extends Control
class_name FPSOverlay

@onready var fps_label: Label = $Label

func _process(_delta: float) -> void:
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
