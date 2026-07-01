extends Node2D

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

## Reliable resource popup
## Values are set via initialize() and applied in _ready()

@export var duration: float = 1.2
@export var rise_distance: float = 65.0

var _amount: int = 40 # Hard default to prevent +0
var _icon_texture: Texture2D = null

func initialize(icon: Texture2D, value: int, start_pos: Vector2) -> void:
	_amount = value if value > 0 else 40
	_icon_texture = icon
	global_position = start_pos
	z_index = 600

func _ready() -> void:
	z_index = 600
	_update_ui()
	_animate()

func _update_ui() -> void:
	var label = get_node_or_null("Label") as Label
	var icon_sprite = get_node_or_null("Icon") as Sprite2D
	
	if label:
		# Triple-safety: NEVER show +0. Default to 40 if anything is wrong.
		var val_to_show = _amount
		if val_to_show <= 0: val_to_show = 40
		
		# Added prefix for clear debugging
		label.text = "+%d Wood" % val_to_show
		label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.4))
		label.add_theme_constant_override("outline_size", 6)
	
	if icon_sprite:
		if _icon_texture:
			icon_sprite.texture = _icon_texture
			icon_sprite.visible = true
		else:
			var tex := PathRegistryScript.load_resource_icon("wood", {"wood": "wood_1"})
			icon_sprite.texture = tex
			icon_sprite.visible = (tex != null)

func _animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	
	modulate.a = 1.0
	scale = Vector2(0.3, 0.3)
	
	tween.tween_property(self, "position:y", position.y - rise_distance, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)
	
	var st := create_tween()
	st.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	st.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	await tween.finished
	queue_free()
