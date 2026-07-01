extends Control
class_name ResearchTableUI

const ProphecyPatternScript := preload("res://scripts/resources/ProphecyPattern.gd")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")
const UNDER_TEXTURE: Texture2D = preload("res://assets/ui/buildings/under.png")

signal mode_requested(mode: int)
signal close_requested

@onready var _row: HBoxContainer = $Panel/Margin/VBox/OptionsRow
@onready var _title: Label = $Panel/Margin/VBox/Title

const BUTTON_SIZE := Vector2(64, 64)

const DEFAULT_OPTIONS := [
    {"mode": 0, "label": "Nothing", "reward_type": -1},
    {"mode": 1, "label": "Basic Production", "reward_type": int(ProphecyPatternScript.RewardType.BASIC_PRODUCTION)},
    {"mode": 2, "label": "Levy Barracks", "reward_type": int(ProphecyPatternScript.RewardType.LEVY_BARRACKS)},
]

func _ready() -> void:
    visible = false
    set_title("Research")
    setup_options(DEFAULT_OPTIONS, 0)
    set_process_unhandled_input(true)

func set_title(title_text: String) -> void:
    if _title:
        _title.text = title_text.strip_edges()

func setup_options(options: Array, current_mode: int = 0) -> void:
    for child in _row.get_children():
        child.queue_free()
    for option_value in options:
        if not (option_value is Dictionary):
            continue
        var option := option_value as Dictionary
        var reward_type := int(option.get("reward_type", -1))
        var icon_texture: Texture2D = null
        if reward_type >= 0:
            icon_texture = RewardPresentationRegistryScript.get_reward_icon(reward_type)
        _add_mode_button(
            int(option.get("mode", 0)),
            String(option.get("label", "Nothing")),
            icon_texture
        )
    setup(current_mode)

func setup(current_mode: int) -> void:
    for child in _row.get_children():
        if not (child is Button):
            continue
        var btn := child as Button
        var mode := int(btn.get_meta("mode", -1))
        btn.disabled = (mode == current_mode)

func _add_mode_button(mode: int, label_text: String, icon_texture: Texture2D) -> void:
    var btn := Button.new()
    btn.custom_minimum_size = Vector2(84, 108)
    btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    btn.set_meta("mode", mode)
    btn.pressed.connect(_on_button_pressed.bind(mode))

    var vb := VBoxContainer.new()
    vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vb.alignment = BoxContainer.ALIGNMENT_CENTER
    vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.add_child(vb)

    var icon_wrap := Control.new()
    icon_wrap.custom_minimum_size = BUTTON_SIZE
    icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vb.add_child(icon_wrap)

    var under := TextureRect.new()
    under.texture = UNDER_TEXTURE
    under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    under.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    under.anchor_right = 1.0
    under.anchor_bottom = 1.0
    under.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon_wrap.add_child(under)

    if icon_texture != null:
        var icon := TextureRect.new()
        icon.texture = icon_texture
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.anchor_left = 0.15
        icon.anchor_top = 0.15
        icon.anchor_right = 0.85
        icon.anchor_bottom = 0.85
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icon_wrap.add_child(icon)

    var label := Label.new()
    label.text = label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vb.add_child(label)

    _row.add_child(btn)

func _on_button_pressed(mode: int) -> void:
    mode_requested.emit(mode)


func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if not (event is InputEventMouseButton):
        return
    var mouse_event := event as InputEventMouseButton
    if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
        return
    var panel := get_node_or_null("Panel") as Control
    if panel == null:
        return
    var rect := Rect2(panel.global_position, panel.size)
    if rect.has_point(mouse_event.global_position):
        return
    close_requested.emit()
