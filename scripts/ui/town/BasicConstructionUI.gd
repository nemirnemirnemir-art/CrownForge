extends Control
class_name BasicConstructionUI

const UNDER_TEXTURE: Texture2D = preload("res://assets/ui/buildings/under.png")
const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")
const OPTIONS := [
    {"id": "", "label": "Nothing"},
    {"id": "clay_mine", "label": "Clay Mine"},
    {"id": "crystal_mine", "label": "Crystal Mine"},
    {"id": "gold_mine", "label": "Gold Mine"},
    {"id": "iron_mine", "label": "Iron Mine"},
    {"id": "vineyard", "label": "Vineyard"},
    {"id": "wheat_field", "label": "Wheat Field"},
]
const BUTTON_SIZE := Vector2(64, 64)

signal target_requested(building_id: String)
signal close_requested

@onready var _title: Label = $Panel/Margin/VBox/Title
@onready var _row: HBoxContainer = $Panel/Margin/VBox/OptionsRow

func _building_registry() -> Node:
    return get_node_or_null("/root/BuildingRegistry")

func _building_upgrade_core() -> Node:
    return get_node_or_null("/root/BuildingUpgradeCore")

func _ready() -> void:
    visible = false
    _build_buttons()
    var upgrade_core := _building_upgrade_core()
    if upgrade_core and upgrade_core.has_signal("building_upgrades_changed") and not upgrade_core.building_upgrades_changed.is_connected(_on_building_upgrades_changed):
        upgrade_core.building_upgrades_changed.connect(_on_building_upgrades_changed)
    set_process_unhandled_input(true)

func setup(is_ready: bool) -> void:
    if _title:
        _title.text = "Basic Construction: Ready" if is_ready else "Basic Construction: Nothing"
    for child in _row.get_children():
        if not (child is Button):
            continue
        var btn := child as Button
        var building_id := String(btn.get_meta("building_id", ""))
        btn.disabled = (not is_ready) and building_id != ""

func _build_buttons() -> void:
    for child in _row.get_children():
        child.queue_free()
    for entry_value in OPTIONS:
        if not (entry_value is Dictionary):
            continue
        var entry := entry_value as Dictionary
        _add_option_button(String(entry.get("id", "")), String(entry.get("label", "")))

func _add_option_button(building_id: String, label_text: String) -> void:
    var btn := Button.new()
    btn.custom_minimum_size = Vector2(84, 108)
    btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    btn.set_meta("building_id", building_id)
    btn.pressed.connect(_on_button_pressed.bind(building_id))

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

    if building_id != "":
        var icon := TextureRect.new()
        var building_registry := _building_registry()
        icon.texture = building_registry.get_building_icon(building_id) if building_registry else null
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.anchor_left = 0.15
        icon.anchor_top = 0.15
        icon.anchor_right = 0.85
        icon.anchor_bottom = 0.85
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        icon_wrap.add_child(icon)

    if building_id != "":
        var stripe := TextureRect.new()
        stripe.name = "UpgradeStripe"
        stripe.offset_left = 44.0
        stripe.offset_top = -4.0
        stripe.offset_right = 84.0
        stripe.offset_bottom = 36.0
        stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
        stripe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        var upgrade_core := _building_upgrade_core()
        var level := int(upgrade_core.call("get_building_upgrade_level", building_id)) if upgrade_core and upgrade_core.has_method("get_building_upgrade_level") else 0
        stripe.texture = BuildingUpgradeVisualsScript.get_stripe_texture(level)
        stripe.visible = stripe.texture != null
        btn.add_child(stripe)

    var label := Label.new()
    label.text = label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vb.add_child(label)

    _row.add_child(btn)

func _on_button_pressed(building_id: String) -> void:
    target_requested.emit(building_id)

func _on_building_upgrades_changed(changed_building_id: String, _level: int) -> void:
    for child in _row.get_children():
        var button := child as Button
        if button == null:
            continue
        if String(button.get_meta("building_id", "")) != changed_building_id:
            continue
        var stripe := button.get_node_or_null("UpgradeStripe") as TextureRect
        if stripe == null:
            continue
        var upgrade_core := _building_upgrade_core()
        var new_level := int(upgrade_core.call("get_building_upgrade_level", changed_building_id)) if upgrade_core and upgrade_core.has_method("get_building_upgrade_level") else 0
        stripe.texture = BuildingUpgradeVisualsScript.get_stripe_texture(new_level)
        stripe.visible = stripe.texture != null

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
