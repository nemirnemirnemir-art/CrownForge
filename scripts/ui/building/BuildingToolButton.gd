extends Button
class_name BuildingToolButton

@export var tool_id: String = ""
@export var tool_name: String = ""
@export var tool_color: Color = Color.WHITE

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label

func setup(p_id: String, p_name: String, p_color: Color) -> void:
	tool_id = p_id
	tool_name = p_name
	tool_color = p_color
	
	name = tool_id.capitalize() + "Tool"
	tooltip_text = tool_name
	
	var style := get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if style:
		style.bg_color = Color(0.2, 0.1, 0.1, 0.8)
		add_theme_stylebox_override("normal", style)
	
	if label:
		label.visible = false # Hide the letter label
	
	_sync_icon()

func _ready() -> void:
	_sync_icon()

func _sync_icon() -> void:
	if icon_rect:
		if icon:
			icon_rect.texture = icon
			icon = null
			return
		if icon_rect.texture:
			return
	_apply_fallback_icon()

func _apply_fallback_icon() -> void:
	if not icon_rect:
		return
	var grad := Gradient.new()
	grad.colors = [tool_color, tool_color * 0.7]
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 32
	tex.height = 32
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	icon_rect.texture = tex
