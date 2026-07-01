extends Node
class_name BarracksRowBuilder

const _TEX_WARRIOR := preload("res://assets/ui/class_ui/Warrior.png")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

var _placeholder_red: Texture2D = null
var _collector: BarracksUnitCollector = null

func initialize(collector: BarracksUnitCollector) -> void:
    _collector = collector
    _placeholder_red = _make_red_placeholder()

func build_unowned_tile(unit_id: String, count: int, on_dismiss: Callable, on_hover: Callable, on_unhover: Callable) -> Control:
    if count <= 0:
        return null

    var cfg := _collector.try_get_unit_config(unit_id)

    var vb := VBoxContainer.new()
    vb.name = "UnownedTile_%s" % unit_id
    vb.custom_minimum_size = Vector2(120, 120)
    vb.add_theme_constant_override("separation", 6)
    vb.alignment = BoxContainer.ALIGNMENT_CENTER

    var face := TextureRect.new()
    face.custom_minimum_size = Vector2(80, 80)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.texture = get_unit_face_or_placeholder(unit_id, cfg)
    face.mouse_filter = Control.MOUSE_FILTER_PASS
    face.mouse_entered.connect(func():
        on_hover.call(unit_id)
    )
    face.mouse_exited.connect(func():
        on_unhover.call()
    )
    vb.add_child(face)

    var bottom := HBoxContainer.new()
    bottom.add_theme_constant_override("separation", 6)
    bottom.alignment = BoxContainer.ALIGNMENT_CENTER
    vb.add_child(bottom)

    var count_label := Label.new()
    count_label.text = str(count)
    count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_outline(count_label, 48, 11)
    bottom.add_child(count_label)

    var dismiss_btn := Button.new()
    dismiss_btn.text = "x"
    dismiss_btn.custom_minimum_size = Vector2(44, 44)
    dismiss_btn.focus_mode = Control.FOCUS_NONE
    dismiss_btn.pressed.connect(func(): on_dismiss.call(unit_id))
    dismiss_btn.add_theme_color_override("font_outline_color", Color.BLACK)
    dismiss_btn.add_theme_constant_override("outline_size", 6)
    dismiss_btn.add_theme_font_size_override("font_size", 24)
    bottom.add_child(dismiss_btn)

    return vb

func build_barracks_row(unit_id: String, total: int, in_barracks: int, cap: int, active: int, in_battle: bool, callbacks: Dictionary) -> Control:
    if total <= 0 and cap <= 0:
        return null

    var cfg := _collector.try_get_unit_config(unit_id)

    var hb := HBoxContainer.new()
    hb.name = "Barracks_%s" % unit_id
    hb.custom_minimum_size = Vector2(0, 104)
    hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hb.add_theme_constant_override("separation", 12)

    var total_label := Label.new()
    total_label.text = str(total)
    total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_outline(total_label, 40, 8)
    hb.add_child(total_label)

    var face := TextureRect.new()
    face.custom_minimum_size = Vector2(80, 80)
    face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    face.texture = get_unit_face_or_placeholder(unit_id, cfg)
    face.mouse_filter = Control.MOUSE_FILTER_PASS
    face.mouse_entered.connect(func(): callbacks.on_hover.call(unit_id))
    face.mouse_exited.connect(callbacks.on_unhover)
    hb.add_child(face)

    var barracks_count_label := Label.new()
    barracks_count_label.text = "%d/%d" % [in_barracks, cap]
    barracks_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    barracks_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_outline(barracks_count_label, 51, 11)
    hb.add_child(barracks_count_label)

    var btn_left := Button.new()
    btn_left.text = "<"
    btn_left.custom_minimum_size = Vector2(66, 66)
    btn_left.focus_mode = Control.FOCUS_NONE
    btn_left.disabled = in_battle or (active <= 0) or (cap > 0 and in_barracks >= cap)
    btn_left.pressed.connect(func(): callbacks.on_move_to_barracks.call(unit_id))
    btn_left.add_theme_color_override("font_outline_color", Color.BLACK)
    btn_left.add_theme_constant_override("outline_size", 6)
    btn_left.add_theme_font_size_override("font_size", 30)
    hb.add_child(btn_left)

    var btn_right := Button.new()
    btn_right.text = ">"
    btn_right.custom_minimum_size = Vector2(66, 66)
    btn_right.focus_mode = Control.FOCUS_NONE
    var can_add_to_field: bool = true
    if callbacks.can_add_to_field.is_valid():
        can_add_to_field = bool(callbacks.can_add_to_field.call())
    btn_right.disabled = (in_barracks <= 0) or (not can_add_to_field)
    btn_right.pressed.connect(func(): callbacks.on_move_to_field.call(unit_id))
    btn_right.add_theme_color_override("font_outline_color", Color.BLACK)
    btn_right.add_theme_constant_override("outline_size", 6)
    btn_right.add_theme_font_size_override("font_size", 30)
    hb.add_child(btn_right)

    var active_label := Label.new()
    active_label.text = str(active)
    active_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _apply_outline(active_label, 40, 8)
    hb.add_child(active_label)

    if active > 0:
        var dismiss_btn := Button.new()
        dismiss_btn.text = "x"
        dismiss_btn.custom_minimum_size = Vector2(66, 66)
        dismiss_btn.focus_mode = Control.FOCUS_NONE
        dismiss_btn.pressed.connect(func(): callbacks.on_dismiss.call(unit_id))
        dismiss_btn.add_theme_color_override("font_outline_color", Color.BLACK)
        dismiss_btn.add_theme_constant_override("outline_size", 6)
        dismiss_btn.add_theme_font_size_override("font_size", 30)
        hb.add_child(dismiss_btn)

    return hb

func get_unit_face_or_placeholder(unit_id: String, cfg: UnitConfig) -> Texture2D:
    var display_name := _collector.get_unit_display_name(unit_id, cfg)
    var fallback := _TEX_WARRIOR if _TEX_WARRIOR != null else _placeholder_red
    return UnitFaceLibraryScript.get_face_texture(unit_id, display_name, fallback)

func _apply_outline(label: Label, font_size: int, outline_size: int) -> void:
    if label == null:
        return
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_outline_color", Color.BLACK)
    label.add_theme_constant_override("outline_size", outline_size)

func _make_red_placeholder() -> Texture2D:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(Color(1.0, 0.0, 0.0, 1.0))
    return ImageTexture.create_from_image(img)
