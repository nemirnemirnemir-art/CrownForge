extends PanelContainer
class_name UnitInfoPanel

const UNIT_NAME_FONT_SIZE := 40
const UNIT_PANEL_MIN_WIDTH := 320.0
const UNIT_PANEL_MAX_WIDTH := 460.0
const UNIT_PANEL_MAX_HEIGHT := 420.0
const UNIT_TRAIT_MAX_LINES := 4
const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const UnitTraitLibraryScript := preload("res://scripts/ui/town/UnitTraitLibrary.gd")
const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

@onready var _unit_icon: TextureRect = $Margin/VBox/Header/UnitIcon
@onready var _unit_name: Label = $Margin/VBox/Header/UnitName
@onready var _stats_header: Label = $Margin/VBox/StatsLabel
@onready var _hp_label: Label = $Margin/VBox/StatsRow/StatsGrid/HPLabel
@onready var _hp_value: Label = $Margin/VBox/StatsRow/StatsGrid/HPValue
@onready var _dps_label: Label = $Margin/VBox/StatsRow/StatsGrid/DPSLabel
@onready var _dps_value: Label = $Margin/VBox/StatsRow/StatsGrid/DPSValue
@onready var _unit_face: TextureRect = $Margin/VBox/StatsRow/UnitFace
@onready var _class_icon1: TextureRect = $Margin/VBox/ClassesBox/ClassIcon1
@onready var _class_label1: Label = $Margin/VBox/ClassesBox/ClassLabel1
@onready var _class_icon2: TextureRect = $Margin/VBox/ClassesBox/ClassIcon2
@onready var _class_label2: Label = $Margin/VBox/ClassesBox/ClassLabel2
@onready var _trait_header: Label = $Margin/VBox/TraitHeader
@onready var _trait_description: Label = $Margin/VBox/TraitDescription

var _unit_config: UnitConfig = null
var _unit_id: String = ""

func _ready() -> void:
    _apply_compact_visual_style()

func _apply_compact_visual_style() -> void:
    clip_contents = true

    var header: BoxContainer = get_node_or_null("Margin/VBox/Header") as BoxContainer
    if header:
        header.alignment = BoxContainer.ALIGNMENT_CENTER

    var classes_box: BoxContainer = get_node_or_null("Margin/VBox/ClassesBox") as BoxContainer
    if classes_box:
        classes_box.alignment = BoxContainer.ALIGNMENT_CENTER

    if _unit_name:
        _unit_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _unit_name.size_flags_vertical = 0
        _unit_name.add_theme_color_override("font_color", Color.BLACK)
        _unit_name.add_theme_font_size_override("font_size", UNIT_NAME_FONT_SIZE)

    if _class_label1:
        _class_label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _class_label1.add_theme_color_override("font_color", Color.BLACK)
        _class_label1.add_theme_font_size_override("font_size", UNIT_NAME_FONT_SIZE)
    if _class_label2:
        _class_label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _class_label2.add_theme_color_override("font_color", Color.BLACK)
        _class_label2.add_theme_font_size_override("font_size", UNIT_NAME_FONT_SIZE)

    if _stats_header:
        _stats_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if _hp_label:
        _hp_label.add_theme_color_override("font_color", Color.BLACK)
    if _hp_value:
        _hp_value.add_theme_color_override("font_color", Color.BLACK)
    if _dps_label:
        _dps_label.add_theme_color_override("font_color", Color.BLACK)
    if _dps_value:
        _dps_value.add_theme_color_override("font_color", Color.BLACK)
    if _unit_face:
        _unit_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        _unit_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        _unit_face.custom_minimum_size = Vector2(96, 96)
    if _trait_header:
        _trait_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _trait_header.add_theme_color_override("font_color", Color.BLACK)
    if _trait_description:
        _trait_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _trait_description.add_theme_color_override("font_color", Color.BLACK)
        _trait_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _trait_description.max_lines_visible = UNIT_TRAIT_MAX_LINES

func setup(unit_id: String) -> void:
    _unit_id = unit_id.to_lower()
    _unit_config = PathRegistryScript.load_unit_config(_unit_id) as UnitConfig

    if _unit_config == null:
        _show_placeholder(unit_id)
        _fit_to_content()
        return

    _update_display()
    _fit_to_content()

func _show_placeholder(unit_id: String) -> void:
    if _unit_name:
        _unit_name.text = unit_id.replace("_", " ").capitalize()
    if _unit_icon:
        _unit_icon.texture = null
        _unit_icon.visible = false
    if _unit_face:
        _unit_face.texture = _resolve_unit_face_texture(_unit_id, null)
        _unit_face.visible = _unit_face.texture != null
    if _hp_value:
        _hp_value.text = "?"
    if _dps_value:
        _dps_value.text = "?"
    if _class_label1:
        _class_label1.text = "Unknown"
        _class_label1.show()
    if _class_label2:
        _class_label2.hide()
    if _class_icon1:
        _class_icon1.hide()
    if _class_icon2:
        _class_icon2.hide()
    if _trait_description:
        var placeholder_trait := UnitTraitLibraryScript.get_trait_text(_unit_id, _unit_config)
        _trait_description.text = placeholder_trait if placeholder_trait != "" else "No unit data available."

func _update_display() -> void:
    if _unit_config == null:
        return

    if _unit_name:
        _unit_name.text = _unit_config.display_name

    if _hp_value:
        _hp_value.text = str(_unit_config.hp)
    if _dps_value:
        _dps_value.text = str(_unit_config.dps)

    if _unit_icon:
        _unit_icon.texture = _unit_config.icon
        _unit_icon.visible = _unit_config.icon != null

    if _unit_face:
        _unit_face.texture = _resolve_unit_face_texture(_unit_id, _unit_config)
        _unit_face.visible = _unit_face.texture != null

    var class_names: Array = _unit_config.get_class_names()
    if _class_label1:
        if class_names.size() > 0:
            _class_label1.text = class_names[0]
            _class_label1.show()
        else:
            _class_label1.hide()

    if _class_label2:
        if class_names.size() > 1:
            _class_label2.text = class_names[1]
            _class_label2.show()
        else:
            _class_label2.hide()

    if _class_icon1:
        _class_icon1.hide()
    if _class_icon2:
        _class_icon2.hide()

    if _trait_description:
        var trait_text: String = UnitTraitLibraryScript.get_trait_text(_unit_id, _unit_config)
        _trait_description.text = trait_text if trait_text != "" else "No trait description."

func _fit_to_content() -> void:
    set_anchors_preset(Control.PRESET_TOP_LEFT)
    anchor_left = 0.0
    anchor_top = 0.0
    anchor_right = 0.0
    anchor_bottom = 0.0
    size_flags_horizontal = 0
    size_flags_vertical = 0

    custom_minimum_size = Vector2(UNIT_PANEL_MAX_WIDTH, 0.0)
    size = Vector2(UNIT_PANEL_MAX_WIDTH, 0.0)
    reset_size()

    var sz: Vector2 = get_combined_minimum_size()
    if sz == Vector2.ZERO:
        return

    var final_width: float = clampf(sz.x, UNIT_PANEL_MIN_WIDTH, UNIT_PANEL_MAX_WIDTH)

    custom_minimum_size = Vector2(final_width, 0.0)
    size = Vector2(final_width, 0.0)
    reset_size()
    sz = get_combined_minimum_size()

    var final_size: Vector2 = Vector2(final_width, minf(sz.y, UNIT_PANEL_MAX_HEIGHT))
    custom_minimum_size = final_size
    size = final_size

func _resolve_unit_face_texture(unit_id: String, cfg: UnitConfig) -> Texture2D:
    var display_name: String = _get_unit_display_name(unit_id, cfg)
    var fallback: Texture2D = null
    if cfg != null:
        fallback = cfg.icon
    return UnitFaceLibraryScript.get_face_texture(unit_id, display_name, fallback)

func _get_unit_display_name(unit_id: String, cfg: UnitConfig) -> String:
    if cfg != null and cfg.display_name != "":
        return cfg.display_name
    return unit_id.replace("_", " ").capitalize()
