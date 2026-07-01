extends RefCounted
class_name MapSlotAnimations

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

const RESOURCE_ICON_MAP := {
	"gold": "gold_4",
	"wheat": "wheat_7",
	"iron_ore": "iron_ore_5",
	"flour": "flour_8",
	"steel": "iron_ingot_6",
	"wood": "wood_1",
	"clay": "clay_3",
	"meat": "meat_9",
	"grapes": "grapes_6",
	"wine": "wine_9",
	"water": "water_1",
	"oil": "oil",
	"crystal": "crystal"
}

var _parent: Node2D = null

func initialize(parent: Node2D) -> void:
	_parent = parent

func show_production_animation(res_id: String, amount: int = 1, position_offset: Vector2 = Vector2.ZERO) -> void:
	var tex = _get_resource_icon_texture(res_id)
	if not tex:
		return
	
	var container := HBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 4)
	container.z_index = 50
	_parent.add_child(container)
	
	var icon_sprite := TextureRect.new()
	icon_sprite.texture = tex
	icon_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_sprite.custom_minimum_size = Vector2(24, 24)
	icon_sprite.size = Vector2(24, 24)
	icon_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon_sprite)
	
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	var container_size := container.get_combined_minimum_size()
	if container_size == Vector2.ZERO:
		container_size = Vector2(80.0, 24.0)
	container.custom_minimum_size = container_size
	container.size = container_size
	container.position = Vector2(-container_size.x * 0.5, -45.0) + position_offset
	
	var tween = _parent.create_tween()
	tween.tween_property(container, "position:y", container.position.y + 10, 0.15)
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - 40, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(container, "modulate:a", 0.0, 0.6)
	tween.set_parallel(false)
	tween.tween_callback(container.queue_free)

func _get_resource_icon_texture(resource_id: String) -> Texture2D:
	return PathRegistryScript.load_resource_icon(resource_id, RESOURCE_ICON_MAP)

static func create_placeholder_texture() -> Texture2D:
	var img := Image.create(180, 180, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.4, 0.4, 1.0))
	return ImageTexture.create_from_image(img)

static func add_placeholder_label(sprite: Sprite2D, text: String) -> void:
	var label := Label.new()
	label.name = "PlaceholderLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2(-90, -30)
	label.size = Vector2(180, 60)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	sprite.add_child(label)
