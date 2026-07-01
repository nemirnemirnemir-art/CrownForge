extends Control
class_name WaveEnemyHUD

## HUD: показывает атакующих врагов в правом верхнем углу во время волны.
## Каждая строка: [фоновый фрейм] + [лицо врага] + xN

const EnemyPortraitScene: PackedScene = preload("res://scenes/ui/components/EnemyPortrait.tscn")
const BG_FRAME_TEX: Texture2D = preload("res://assets/ui/class_ui/main_screen_under_enemy_face.png")

const ENTRY_SIZE: float = 54.0
const FACE_SIZE: float = 44.0

var _vbox: VBoxContainer = null

func _get_singleton(node_name: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)

func _ready() -> void:
	_build_layout()
	_connect_signals()
	visible = false

func _build_layout() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -190.0
	offset_top = 58.0
	offset_right = -8.0
	offset_bottom = 700.0
	grow_horizontal = GROW_DIRECTION_BEGIN
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 200

	_vbox = VBoxContainer.new()
	_vbox.name = "VBox"
	_vbox.anchor_left = 0.0
	_vbox.anchor_right = 1.0
	_vbox.anchor_top = 0.0
	_vbox.anchor_bottom = 0.0
	_vbox.offset_right = 0.0
	_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_vbox)

func _connect_signals() -> void:
	var event_bus := _get_singleton("EventBus")
	if event_bus == null:
		return
	if event_bus.has_signal("wave_started_with_mobs") and not event_bus.wave_started_with_mobs.is_connected(_on_wave_started):
		event_bus.wave_started_with_mobs.connect(_on_wave_started)
	if event_bus.has_signal("wave_completed") and not event_bus.wave_completed.is_connected(_on_wave_completed):
		event_bus.wave_completed.connect(_on_wave_completed)

func _on_wave_started(_wave_number: int, mob_counts: Dictionary) -> void:
	_clear_entries()
	if mob_counts.is_empty():
		visible = false
		return
	for enemy_id in mob_counts.keys():
		var count: int = int(mob_counts[enemy_id])
		if count <= 0:
			continue
		_vbox.add_child(_build_entry(String(enemy_id), count))
	visible = _vbox.get_child_count() > 0

func _on_wave_completed(_wave_number: int) -> void:
	_clear_entries()
	visible = false

func _clear_entries() -> void:
	if _vbox == null:
		return
	for child in _vbox.get_children():
		child.queue_free()

func _build_entry(enemy_id: String, count: int) -> Control:
	var hbox := HBoxContainer.new()
	hbox.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)

	var frame_container := Control.new()
	frame_container.custom_minimum_size = Vector2(ENTRY_SIZE, ENTRY_SIZE)
	frame_container.mouse_filter = MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = BG_FRAME_TEX
	bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	frame_container.add_child(bg)

	var face_tex := _get_face_texture(enemy_id)
	if face_tex:
		var face := TextureRect.new()
		face.texture = face_tex
		face.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = MOUSE_FILTER_IGNORE
		face.z_index = 1
		var m: float = (ENTRY_SIZE - FACE_SIZE) * 0.5
		face.anchor_left = 0.0
		face.anchor_top = 0.0
		face.anchor_right = 1.0
		face.anchor_bottom = 1.0
		face.offset_left = m
		face.offset_top = m
		face.offset_right = -m
		face.offset_bottom = -m
		frame_container.add_child(face)

	hbox.add_child(frame_container)

	var count_label := Label.new()
	count_label.text = "x%d" % count
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.custom_minimum_size = Vector2(0, ENTRY_SIZE)
	count_label.mouse_filter = MOUSE_FILTER_IGNORE
	count_label.add_theme_font_size_override("font_size", 20)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	count_label.add_theme_constant_override("shadow_offset_x", 2)
	count_label.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(count_label)

	return hbox

func _get_face_texture(enemy_id: String) -> Texture2D:
	if EnemyPortraitScene == null:
		return null
	var portrait := EnemyPortraitScene.instantiate()
	if portrait == null:
		return null
	if portrait.has_method("set_enemy_portrait"):
		portrait.set_enemy_portrait(enemy_id)
	var tex: Texture2D = null
	if portrait is TextureRect:
		tex = (portrait as TextureRect).texture
	portrait.queue_free()
	return tex
