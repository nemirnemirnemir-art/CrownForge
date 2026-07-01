extends Control
class_name WallHealthUI

const CASTLE_ICON_TEXTURE: Texture2D = preload("res://assets/ui/icons/wall_hp.png")

@onready var icon: TextureRect = $Icon
@onready var value_label: Label = $ValueLabel

const THALEAH_FAT: FontFile = preload("res://assets/ui/fonts/ThaleahFat.ttf")

@export var icon_texture: Texture2D = null

func _ready() -> void:
    if icon:
        icon.texture = icon_texture if icon_texture != null else CASTLE_ICON_TEXTURE
        if icon.texture == null:
            var img := Image.create(50, 50, false, Image.FORMAT_RGBA8)
            img.fill(Color(0, 0, 0, 0))
            var tex := ImageTexture.create_from_image(img)
            icon.texture = tex
        icon.custom_minimum_size = Vector2(50, 50)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

    if CastleCore:
        if not CastleCore.castle_hp_changed.is_connected(_on_castle_hp_changed):
            CastleCore.castle_hp_changed.connect(_on_castle_hp_changed)
        _update_display(int(CastleCore.current_hp), int(CastleCore.get_effective_max_hp()))

func _on_wall_damaged(_damage: int, current_hp: int, _max_hp: int) -> void:
    _update_display(current_hp, _max_hp)

func _on_castle_hp_changed(current_hp: int, _max_hp: int) -> void:
    _update_display(current_hp, _max_hp)

func _on_wall_destroyed() -> void:
    if value_label:
        value_label.text = "0"

func _update_display(current_hp: int, _max_hp: int) -> void:
    if value_label:
        value_label.text = str(current_hp)
        value_label.add_theme_font_override("font", THALEAH_FAT)
        value_label.add_theme_font_size_override("font_size", 64)
        value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
        value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
        value_label.add_theme_constant_override("outline_size", 12)
