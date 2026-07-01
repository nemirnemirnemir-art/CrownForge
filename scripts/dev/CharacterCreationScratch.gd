extends Control
class_name CharacterCreationScratch

const HERO_CREATION_BACKGROUND := preload("res://assets/Characher_Creation/hero_creation_background.png")
const FREE_POINTS_BACKGROUND := preload("res://assets/Characher_Creation/free_points_background.png")
const HERO_STATS_BACKGROUND := preload("res://assets/Characher_Creation/hero_stats_background.png")
const LEFT_MINUS_TEXTURE := preload("res://assets/Characher_Creation/left_minus.png")
const LEFT_LOCK_TEXTURE := preload("res://assets/Characher_Creation/left_lock.png")
const RIGHT_PLUS_TEXTURE := preload("res://assets/Characher_Creation/right_plus.png")
const RIGHT_LOCK_TEXTURE := preload("res://assets/Characher_Creation/right_lock.png")
const NUMBER_BACKGROUND_TEXTURE := preload("res://assets/Characher_Creation/number_of_stats.png")
const POWER_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Power.png")
const SPEED_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Speed.png")
const THINKING_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Thinking.png")
const LUCKY_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Lucky.png")
const HEATH_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Heath.png")
const CHARISMA_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Charisma.png")
const CROWN_TEXTURE := preload("res://assets/Characher_Creation/Kings Stats/Crown.png")

const STAT_MIN := 1
const STAT_MAX := 12
const STAT_DEFAULT := 6
const FREE_POINTS_DEFAULT := 6
const STAT_ICON_SIZE := 100.0
const BUTTON_SIZE := Vector2(72, 72)
const NUMBER_SIZE := Vector2(92, 64)
const STAT_DEFS := [
	{"id": "power", "texture": POWER_TEXTURE},
	{"id": "speed", "texture": SPEED_TEXTURE},
	{"id": "thinking", "texture": THINKING_TEXTURE},
	{"id": "lucky", "texture": LUCKY_TEXTURE},
	{"id": "heath", "texture": HEATH_TEXTURE},
	{"id": "charisma", "texture": CHARISMA_TEXTURE},
	{"id": "crown", "texture": CROWN_TEXTURE},
]

var free_points: int = FREE_POINTS_DEFAULT
var stat_values: Dictionary = {}
var _rows_by_stat: Dictionary = {}

var _background_rect: TextureRect
var _free_points_rect: TextureRect
var _free_points_label: Label
var _stats_rect: TextureRect
var _panel_margin: MarginContainer
var _rows_container: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_initialize_stats()
	_refresh_ui()
	if not resized.is_connected(_layout_ui):
		resized.connect(_layout_ui)
	_layout_ui()

func _build_ui() -> void:
	_background_rect = TextureRect.new()
	_background_rect.name = "HeroCreationBackground"
	_background_rect.texture = HERO_CREATION_BACKGROUND
	_background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_background_rect)

	_stats_rect = TextureRect.new()
	_stats_rect.name = "HeroStatsBackground"
	_stats_rect.texture = HERO_STATS_BACKGROUND
	_stats_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stats_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_stats_rect)

	_panel_margin = MarginContainer.new()
	_panel_margin.name = "PanelMargin"
	_panel_margin.anchor_right = 1.0
	_panel_margin.anchor_bottom = 1.0
	_panel_margin.offset_left = 54.0
	_panel_margin.offset_top = 42.0
	_panel_margin.offset_right = -54.0
	_panel_margin.offset_bottom = -42.0
	_stats_rect.add_child(_panel_margin)

	_rows_container = VBoxContainer.new()
	_rows_container.name = "Rows"
	_rows_container.anchor_right = 1.0
	_rows_container.anchor_bottom = 1.0
	_rows_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_rows_container.add_theme_constant_override("separation", 6)
	_panel_margin.add_child(_rows_container)

	_free_points_rect = TextureRect.new()
	_free_points_rect.name = "FreePointsBackground"
	_free_points_rect.texture = FREE_POINTS_BACKGROUND
	_free_points_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_free_points_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_free_points_rect)

	_free_points_label = Label.new()
	_free_points_label.name = "FreePointsLabel"
	_free_points_label.anchor_right = 1.0
	_free_points_label.anchor_bottom = 1.0
	_free_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_free_points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_free_points_label.add_theme_font_size_override("font_size", 34)
	_free_points_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.02, 1.0))
	_free_points_label.add_theme_color_override("font_outline_color", Color(1, 0.96, 0.8, 1.0))
	_free_points_label.add_theme_constant_override("outline_size", 6)
	_free_points_rect.add_child(_free_points_label)

	for stat_def in STAT_DEFS:
		_create_stat_row(String(stat_def["id"]), stat_def["texture"])

func _initialize_stats() -> void:
	free_points = FREE_POINTS_DEFAULT
	stat_values.clear()
	for stat_def in STAT_DEFS:
		stat_values[String(stat_def["id"])] = STAT_DEFAULT

func _create_stat_row(stat_id: String, icon_texture: Texture2D) -> void:
	var row := HBoxContainer.new()
	row.name = "%s_Row" % stat_id.capitalize()
	row.custom_minimum_size = Vector2(0, 100)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	_rows_container.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon_texture
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(STAT_ICON_SIZE, STAT_ICON_SIZE)
	row.add_child(icon_rect)

	var left_button := TextureButton.new()
	left_button.name = "MinusButton"
	left_button.ignore_texture_size = true
	left_button.custom_minimum_size = BUTTON_SIZE
	left_button.texture_normal = LEFT_MINUS_TEXTURE
	left_button.texture_hover = LEFT_MINUS_TEXTURE
	left_button.texture_pressed = LEFT_MINUS_TEXTURE
	left_button.texture_disabled = LEFT_LOCK_TEXTURE
	left_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	left_button.focus_mode = Control.FOCUS_NONE
	left_button.pressed.connect(_on_minus_pressed.bind(stat_id))
	row.add_child(left_button)

	var number_holder := Control.new()
	number_holder.name = "NumberHolder"
	number_holder.custom_minimum_size = NUMBER_SIZE
	row.add_child(number_holder)

	var number_bg := TextureRect.new()
	number_bg.name = "NumberBackground"
	number_bg.anchor_right = 1.0
	number_bg.anchor_bottom = 1.0
	number_bg.texture = NUMBER_BACKGROUND_TEXTURE
	number_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	number_bg.stretch_mode = TextureRect.STRETCH_SCALE
	number_holder.add_child(number_bg)

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.anchor_right = 1.0
	value_label.anchor_bottom = 1.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 28)
	value_label.add_theme_color_override("font_color", Color(0.16, 0.08, 0.02, 1.0))
	value_label.add_theme_color_override("font_outline_color", Color(1, 0.96, 0.8, 1.0))
	value_label.add_theme_constant_override("outline_size", 5)
	number_holder.add_child(value_label)

	var right_button := TextureButton.new()
	right_button.name = "PlusButton"
	right_button.ignore_texture_size = true
	right_button.custom_minimum_size = BUTTON_SIZE
	right_button.texture_normal = RIGHT_PLUS_TEXTURE
	right_button.texture_hover = RIGHT_PLUS_TEXTURE
	right_button.texture_pressed = RIGHT_PLUS_TEXTURE
	right_button.texture_disabled = RIGHT_LOCK_TEXTURE
	right_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	right_button.focus_mode = Control.FOCUS_NONE
	right_button.pressed.connect(_on_plus_pressed.bind(stat_id))
	row.add_child(right_button)

	_rows_by_stat[stat_id] = {
		"label": value_label,
		"minus_button": left_button,
		"plus_button": right_button,
	}

func _layout_ui() -> void:
	if _background_rect:
		_background_rect.position = Vector2.ZERO
		_background_rect.size = size

	if _free_points_rect:
		_free_points_rect.position = Vector2(28, 24)
		_free_points_rect.size = Vector2(250, 92)

	if _stats_rect:
		var panel_width := clampf(size.x * 0.72, 820.0, 1180.0)
		var panel_height := clampf(size.y * 0.84, 760.0, 940.0)
		_stats_rect.size = Vector2(panel_width, panel_height)
		_stats_rect.position = Vector2((size.x - panel_width) * 0.5, maxf(110.0, (size.y - panel_height) * 0.5 + 28.0))

func _on_minus_pressed(stat_id: String) -> void:
	var current := int(stat_values.get(stat_id, STAT_DEFAULT))
	if current <= STAT_MIN:
		return
	stat_values[stat_id] = current - 1
	free_points += 1
	_refresh_ui()

func _on_plus_pressed(stat_id: String) -> void:
	var current := int(stat_values.get(stat_id, STAT_DEFAULT))
	if current >= STAT_MAX:
		return
	if free_points <= 0:
		return
	stat_values[stat_id] = current + 1
	free_points -= 1
	_refresh_ui()

func _refresh_ui() -> void:
	if _free_points_label:
		_free_points_label.text = str(free_points)
	for stat_def in STAT_DEFS:
		var stat_id := String(stat_def["id"])
		if not _rows_by_stat.has(stat_id):
			continue
		var row_data: Dictionary = _rows_by_stat[stat_id]
		var current := int(stat_values.get(stat_id, STAT_DEFAULT))
		var value_label := row_data.get("label") as Label
		var minus_button := row_data.get("minus_button") as TextureButton
		var plus_button := row_data.get("plus_button") as TextureButton
		if value_label:
			value_label.text = str(current)
		if minus_button:
			minus_button.disabled = current <= STAT_MIN
		if plus_button:
			plus_button.disabled = current >= STAT_MAX or free_points <= 0
