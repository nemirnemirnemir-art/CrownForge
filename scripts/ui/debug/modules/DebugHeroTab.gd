extends RefCounted
class_name DebugHeroTab

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const HEART_ICON_PATH := "res://assets/ui/status_icons/heart.png"
const ATTACK_ICON_PATH := "res://assets/ui/status_icons/attack.png"

func build_ui(parent: Control, hero_ids: Array, spawn_callback: Callable, spawn_25_callback: Callable, spawn_skeleton_callback: Callable) -> void:
    var hero_label = Label.new()
    hero_label.text = "HEROES (%d)" % hero_ids.size()
    hero_label.add_theme_font_size_override("font_size", 22)
    parent.add_child(hero_label)

    var hero_container = VBoxContainer.new()
    hero_container.add_theme_constant_override("separation", 8)
    parent.add_child(hero_container)

    for hero_name in hero_ids:
        hero_container.add_child(_build_hero_row(String(hero_name), spawn_callback))

    var spawn_25_crossbowmen_btn = Button.new()
    spawn_25_crossbowmen_btn.text = "Spawn 25 Crossbowmen"
    spawn_25_crossbowmen_btn.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
    spawn_25_crossbowmen_btn.pressed.connect(spawn_25_callback)
    hero_container.add_child(spawn_25_crossbowmen_btn)

    var spawn_skeleton_btn = Button.new()
    spawn_skeleton_btn.text = "Spawn SmallBones (Permanent)"
    spawn_skeleton_btn.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
    spawn_skeleton_btn.pressed.connect(spawn_skeleton_callback)
    hero_container.add_child(spawn_skeleton_btn)

    parent.add_child(HSeparator.new())

func _build_hero_row(hero_id: String, spawn_callback: Callable) -> Control:
    var cfg := PathRegistryScript.load_unit_config(hero_id) as UnitConfig
    var display_name := _get_display_name(hero_id, cfg)

    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 52)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 10)

    var face := TextureRect.new()
    face.custom_minimum_size = Vector2(72, 72)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.texture = UnitFaceLibraryScript.get_face_texture(hero_id, display_name)
    row.add_child(face)

    var name_label := Label.new()
    name_label.text = display_name
    name_label.custom_minimum_size = Vector2(190, 0)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 18)
    row.add_child(name_label)

    row.add_child(_build_stat_chip(HEART_ICON_PATH, _format_stat_value(cfg.hp if cfg != null else -1.0)))
    row.add_child(_build_stat_chip(ATTACK_ICON_PATH, _format_stat_value(cfg.dps if cfg != null else -1.0)))

    var spawn_btn := Button.new()
    spawn_btn.text = "Spawn"
    spawn_btn.custom_minimum_size = Vector2(88, 38)
    spawn_btn.focus_mode = Control.FOCUS_NONE
    spawn_btn.pressed.connect(spawn_callback.bind(hero_id))
    row.add_child(spawn_btn)

    return row

func _build_stat_chip(icon_path: String, value_text: String) -> Control:
    var holder := PanelContainer.new()
    holder.custom_minimum_size = Vector2(86, 34)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.0, 0.0, 0.0, 0.35)
    style.set_corner_radius_all(5)
    holder.add_theme_stylebox_override("panel", style)

    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 5)
    holder.add_child(row)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(18, 18)
    icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists(icon_path):
        icon.texture = load(icon_path) as Texture2D
    row.add_child(icon)

    var value := Label.new()
    value.text = value_text
    value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    value.add_theme_font_size_override("font_size", 16)
    row.add_child(value)

    return holder

func _get_display_name(hero_id: String, cfg: UnitConfig) -> String:
    if cfg != null and cfg.display_name != "":
        return cfg.display_name
    return hero_id.replace("_", " ").capitalize()

func _format_stat_value(value: float) -> String:
    if value < 0.0:
        return "?"
    if abs(value - round(value)) <= 0.01:
        return str(int(round(value)))
    return String.num(value, 1)
