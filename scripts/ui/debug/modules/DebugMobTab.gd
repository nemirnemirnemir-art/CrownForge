extends RefCounted
class_name DebugMobTab

const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

const HEART_ICON_PATH := "res://assets/ui/status_icons/heart.png"
const ATTACK_ICON_PATH := "res://assets/ui/status_icons/attack.png"

func build_ui(parent: Control, mob_scenes: Dictionary, spawn_homeseeker_callback: Callable, spawn_minotaur_callback: Callable, spawn_dragon_callback: Callable, spawn_mob_callback: Callable, clear_mobs_callback: Callable) -> void:
    var mob_label = Label.new()
    mob_label.text = "MOBS (%d)" % mob_scenes.size()
    mob_label.add_theme_font_size_override("font_size", 22)
    parent.add_child(mob_label)

    var mob_container = VBoxContainer.new()
    mob_container.add_theme_constant_override("separation", 8)
    parent.add_child(mob_container)

    mob_container.add_child(_build_action_row("Homeseeker Boss", "homeseekerboss", 2000.0, -1.0, spawn_homeseeker_callback))
    mob_container.add_child(_build_action_row("Minotaur Boss", "minotaurboss", 2000.0, -1.0, spawn_minotaur_callback))
    mob_container.add_child(_build_action_row("Dragon", "dragon", 10000.0, -1.0, spawn_dragon_callback))

    var mob_names: Array[String] = []
    for mob_name in mob_scenes.keys():
        mob_names.append(String(mob_name))
    mob_names.sort()
    for mob_name in mob_names:
        var packed_scene := mob_scenes.get(mob_name) as PackedScene
        mob_container.add_child(_build_mob_row(mob_name, packed_scene, spawn_mob_callback))

    var clear_btn = Button.new()
    clear_btn.text = "Clear All Mobs"
    clear_btn.pressed.connect(clear_mobs_callback)
    parent.add_child(clear_btn)

    parent.add_child(HSeparator.new())

func _build_mob_row(mob_name: String, packed_scene: PackedScene, spawn_mob_callback: Callable) -> Control:
    var preview: Texture2D = null
    var hp: float = -1.0
    var damage: float = -1.0
    if packed_scene != null:
        var instance := packed_scene.instantiate()
        if instance is Node:
            var node := instance as Node
            preview = _extract_mob_preview(node)
            hp = _extract_mob_hp(node)
            damage = _extract_mob_damage(node)
            node.queue_free()
    return _build_action_row(_format_name(mob_name), mob_name, hp, damage, spawn_mob_callback.bind(mob_name), preview)

func _build_action_row(display_name: String, face_id: String, hp: float, damage: float, callback: Callable, preview: Texture2D = null) -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 52)
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 10)

    var face := TextureRect.new()
    face.custom_minimum_size = Vector2(72, 72)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.texture = preview if preview != null else UnitFaceLibraryScript.get_mob_face_texture(face_id)
    row.add_child(face)

    var name_label := Label.new()
    name_label.text = display_name
    name_label.custom_minimum_size = Vector2(190, 0)
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 18)
    row.add_child(name_label)

    row.add_child(_build_stat_chip(HEART_ICON_PATH, _format_stat_value(hp)))
    row.add_child(_build_stat_chip(ATTACK_ICON_PATH, _format_stat_value(damage)))

    var spawn_btn := Button.new()
    spawn_btn.text = "Spawn"
    spawn_btn.custom_minimum_size = Vector2(88, 38)
    spawn_btn.focus_mode = Control.FOCUS_NONE
    spawn_btn.pressed.connect(callback)
    row.add_child(spawn_btn)

    return row

func _extract_mob_preview(node: Node) -> Texture2D:
    var walk := node.get_node_or_null("AnimWalk") as AnimatedSprite2D
    if walk and walk.sprite_frames and walk.sprite_frames.has_animation(walk.animation) and walk.sprite_frames.get_frame_count(walk.animation) > 0:
        return walk.sprite_frames.get_frame_texture(walk.animation, 0)
    var attack := node.get_node_or_null("AnimAttack") as AnimatedSprite2D
    if attack and attack.sprite_frames and attack.sprite_frames.has_animation(attack.animation) and attack.sprite_frames.get_frame_count(attack.animation) > 0:
        return attack.sprite_frames.get_frame_texture(attack.animation, 0)
    var sprite := node.get_node_or_null("AnimationSprite2D") as AnimatedSprite2D
    if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(sprite.animation) and sprite.sprite_frames.get_frame_count(sprite.animation) > 0:
        return sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
    return null

func _extract_mob_hp(node: Node) -> float:
    var health := node.get_node_or_null("Components/Health")
    if health == null:
        return -1.0
    if "fixed_max_health" in health and float(health.get("fixed_max_health")) > 0.0:
        return float(health.get("fixed_max_health"))
    if "base_max_health" in health:
        return float(health.get("base_max_health"))
    return -1.0

func _extract_mob_damage(node: Node) -> float:
    if "mob_damage" in node:
        return float(node.get("mob_damage"))
    return -1.0

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

func _format_name(raw_name: String) -> String:
    return raw_name.replace("_", " ")

func _format_stat_value(value: float) -> String:
    if value < 0.0:
        return "?"
    if abs(value - round(value)) <= 0.01:
        return str(int(round(value)))
    return String.num(value, 1)
