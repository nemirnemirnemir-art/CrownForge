extends TextureButton

signal hire_requested(hero_id: String)

var _hero_id: String = ""
var _hero_name: String = ""
var _cost: float = 0.0

var _is_focused: bool = false

func setup(hero_id: String, hero_name: String, cost: float, _icon_path: String) -> void:
	_hero_id = hero_id
	_hero_name = hero_name
	_cost = cost

	set_meta("hero_id", _hero_id)

	tooltip_text = "%s\n%d G" % [hero_name, int(cost)]

	if FileAccess.file_exists(_icon_path):
		var tex: Texture2D = load(_icon_path)
		if tex:
			texture_normal = tex
			texture_hover = tex
			texture_pressed = tex

func _ready() -> void:
	pressed.connect(_on_hire_pressed)

func _on_hire_pressed() -> void:
	# print("[HeroHireItem] Button pressed for hero: %s" % _hero_id)
	hire_requested.emit(_hero_id)

func get_hero_id() -> String:
	return _hero_id

func set_focused(focused: bool) -> void:
	_is_focused = focused
	modulate = Color(1, 1, 0.8, 1) if _is_focused else Color(1, 1, 1, 1)

func update_status(_is_hired: bool, _can_afford: bool) -> void:
	tooltip_text = "%s\n%d G" % [_hero_name, int(_cost)]
	disabled = not _can_afford
