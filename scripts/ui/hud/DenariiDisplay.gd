extends HBoxContainer
class_name DenariiDisplay

@export var icon_texture: Texture2D

@onready var _icon: TextureRect = $Icon
@onready var _value_label: Label = $ValueLabel

func _ready() -> void:
	if icon_texture != null and _icon:
		_icon.texture = icon_texture
	if EventBus and EventBus.has_signal("gold_changed"):
		EventBus.gold_changed.connect(_on_gold_changed)
	_update_value()

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
	_update_value()

func _update_value() -> void:
	if _value_label == null:
		return
	var val := 0
	if EconomyCore:
		val = int(EconomyCore.get_gold())
	_value_label.text = str(val)
