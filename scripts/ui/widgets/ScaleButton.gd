extends TextureButton
class_name ScaleButton

@export var pressed_scale: float = 1.15
@export var hover_brightness: float = 1.2
@export var anim_duration: float = 0.1
@export var equip_icon: Texture2D = null
@export var destroy_icon: Texture2D = null
@export var fight_icon: Texture2D = null
@export var auto_icon: Texture2D = null

var _base_scale: Vector2
var _base_modulate: Color

@onready var active_border: ReferenceRect = $ActiveBorder

func _ready() -> void:
	# Ensure pivot is center for correct scaling
	pivot_offset = size / 2
	_base_scale = scale
	_base_modulate = modulate
	
	# Connect signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	
	# Ensure size updates pivot
	resized.connect(_on_resized)

func set_active_border(active: bool) -> void:
	if active_border:
		active_border.visible = active

func _on_resized() -> void:
	pivot_offset = size / 2

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(_base_modulate.r * hover_brightness, _base_modulate.g * hover_brightness, _base_modulate.b * hover_brightness, _base_modulate.a), anim_duration)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", _base_modulate, anim_duration)

func _on_button_down() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", _base_scale * pressed_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", _base_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
