extends GridContainer
class_name BuildingCategoryFilter

signal category_selected(category: int)

const CATEGORY_COLORS := {
	0: Color("#4A90D9"),  # Basic Production - Blue
	1: Color("#7B68EE"),  # Established Production - Purple
	2: Color("#32CD32"),  # Advanced Production - Green
	3: Color("#CD853F"),  # Levy Barracks - Brown
	4: Color("#DAA520"),  # Veteran Barracks - Gold
	5: Color("#DC143C"),  # Elite Barracks - Crimson
	6: Color("#4682B4"),  # Kingdom Infrastructure - Steel
	7: Color("#708090"),  # Other - Slate
	99: Color("#FF4500"), # Seals - OrangeRed
	-1: Color("#FFFFFF"), # ALL - White
}

const CATEGORY_LABELS := {
	0: "BP",
	1: "EP",
	2: "AP",
	3: "LB",
	4: "VB",
	5: "EB",
	6: "KI",
	7: "OT",
	99: "SE",
	-1: "ALL",
}

var _current_category: int = -1
var _buttons: Dictionary = {}

func _ready() -> void:
	columns = 3
	custom_minimum_size = Vector2(100, 100)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)
	
	_create_buttons()
	_update_button_states()

func _create_buttons() -> void:
	for category in [-1, 0, 1, 2, 3, 4, 5, 6, 7, 99]:
		var btn := Button.new()
		btn.text = CATEGORY_LABELS[category]
		btn.custom_minimum_size = Vector2(32, 32)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.toggle_mode = true
		
		# Base styling
		var style := StyleBoxFlat.new()
		style.bg_color = CATEGORY_COLORS[category]
		style.set_corner_radius_all(3)
		style.shadow_size = 1
		style.shadow_offset = Vector2(1, 1)
		btn.add_theme_stylebox_override("normal", style)
		
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = CATEGORY_COLORS[category].lightened(0.2)
		hover_style.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = CATEGORY_COLORS[category].darkened(0.2)
		pressed_style.set_corner_radius_all(3)
		pressed_style.border_width_left = 1
		pressed_style.border_width_top = 1
		pressed_style.border_width_right = 1
		pressed_style.border_width_bottom = 1
		pressed_style.border_color = Color.WHITE
		btn.add_theme_stylebox_override("pressed", pressed_style)
		
		btn.add_theme_stylebox_override("disabled", pressed_style) 
		
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 1)
		btn.add_theme_font_size_override("font_size", 10)
		
		btn.pressed.connect(_on_button_pressed.bind(category))
		add_child(btn)
		_buttons[category] = btn

func _on_button_pressed(category: int) -> void:
	# Avoid redundant clicks
	if _current_category == category:
		_buttons[category].button_pressed = true
		return
		
	_current_category = category
	_update_button_states()
	category_selected.emit(category)

func _update_button_states() -> void:
	for cat in _buttons:
		var btn: Button = _buttons[cat]
		btn.button_pressed = (cat == _current_category)

func get_current_category() -> int:
	return _current_category
