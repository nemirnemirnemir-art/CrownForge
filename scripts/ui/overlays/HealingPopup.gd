extends Node2D

@export var amount: int = 0
@export var duration: float = 1.0

@onready var label: Label = $Label
@onready var icon: TextureRect = $Icon

func _ready() -> void:
	label.add_theme_font_size_override("font_size", 21)
	label.text = "+%d" % amount
	
	# Animation - двигается только на 25 пикселей вверх
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 25, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func setup(val: int) -> void:
	amount = val
	if label: label.add_theme_font_size_override("font_size", 21)
	if label: label.text = "+%d" % amount
