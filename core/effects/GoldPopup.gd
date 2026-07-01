extends Node2D

@export var amount: int = 0
@export var duration: float = 1.0

@onready var label: Label = $Label

func _ready() -> void:
	label.add_theme_font_size_override("font_size", 21)
	label.text = "+%d" % amount
	
	# Animation - float horizontally and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	# Move horizontally 8 pixels (approx 1/3 of previous 25)
	tween.tween_property(self, "position:x", position.x + 8, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func setup(val: int) -> void:
	amount = val
	if label: label.add_theme_font_size_override("font_size", 21)
	if label: label.text = "+%d" % amount
