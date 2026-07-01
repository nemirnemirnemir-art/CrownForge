extends RefCounted
class_name DebugHeroItemsTab

const ItemSystemScript = preload("res://modules/inventory/item_system.gd")

const SWORD_ICON := "res://assets/items/equipment/sword.png"
const ARMOR_ICON := "res://assets/items/equipment/armor.png"
const HELMET_ICON := "res://assets/items/equipment/helmet.png"
const RING_ICON := "res://assets/items/equipment/ring.png"

const ITEM_CREATE_MAP: Array[Dictionary] = [
    {
        "label": "Weapon",
        "id": "debug_weapon",
        "type": ItemSystemScript.ItemType.WEAPON,
        "icon": SWORD_ICON,
        "hp": 0,
        "damage": 15,
    },
    {
        "label": "Armor",
        "id": "debug_armor",
        "type": ItemSystemScript.ItemType.ARMOR,
        "icon": ARMOR_ICON,
        "hp": 20,
        "damage": 0,
    },
    {
        "label": "Helmet",
        "id": "debug_helmet",
        "type": ItemSystemScript.ItemType.HELMET,
        "icon": HELMET_ICON,
        "hp": 10,
        "damage": 0,
    },
    {
        "label": "Ring",
        "id": "debug_ring",
        "type": ItemSystemScript.ItemType.RING,
        "icon": RING_ICON,
        "hp": 0,
        "damage": 8,
    },
]

func build_ui(parent: Control, equip_callback: Callable, strip_callback: Callable) -> void:
    var label := Label.new()
    label.text = "HERO ITEMS"
    label.add_theme_font_size_override("font_size", 22)
    parent.add_child(label)

    var container := VBoxContainer.new()
    container.add_theme_constant_override("separation", 6)
    parent.add_child(container)

    for cfg in ITEM_CREATE_MAP:
        container.add_child(_build_item_row(cfg, equip_callback))

    var strip_btn := Button.new()
    strip_btn.text = "Strip All"
    strip_btn.custom_minimum_size = Vector2(0, 42)
    strip_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
    strip_btn.pressed.connect(strip_callback)
    container.add_child(strip_btn)

    parent.add_child(HSeparator.new())

func _build_item_row(cfg: Dictionary, equip_callback: Callable) -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 48)
    row.add_theme_constant_override("separation", 10)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(40, 40)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if ResourceLoader.exists(cfg.icon):
        icon.texture = load(cfg.icon) as Texture2D
    row.add_child(icon)

    var name_label := Label.new()
    name_label.text = cfg.label
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 20)
    row.add_child(name_label)

    var stat_text := _format_stats(cfg.hp, cfg.damage)
    var stat_label := Label.new()
    stat_label.text = stat_text
    stat_label.custom_minimum_size = Vector2(120, 0)
    stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    stat_label.add_theme_font_size_override("font_size", 16)
    stat_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
    row.add_child(stat_label)

    var equip_btn := Button.new()
    equip_btn.text = "Equip"
    equip_btn.custom_minimum_size = Vector2(88, 38)
    equip_btn.focus_mode = Control.FOCUS_NONE
    equip_btn.pressed.connect(equip_callback.bind(cfg))
    row.add_child(equip_btn)

    return row

func _format_stats(hp: int, damage: int) -> String:
    var parts: Array[String] = []
    if hp > 0:
        parts.append("HP+%d" % hp)
    if damage > 0:
        parts.append("DMG+%d" % damage)
    return " ".join(parts)
