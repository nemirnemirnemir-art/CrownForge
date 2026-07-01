## UI element representing one card in the player's hand.
## Draggable onto BoardSlotUI elements on the board.
## Created dynamically by the Prototype scene — all children built in code.
extends PanelContainer

const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

# Category -> background color mapping
const CATEGORY_COLORS: Dictionary = {
	"troop": Color(0.2, 0.25, 0.4),
	"building": Color(0.35, 0.25, 0.15),
	"tome": Color(0.3, 0.2, 0.35),
	"enchantment": Color(0.4, 0.35, 0.15),
}
const DEFAULT_BG_COLOR: Color = Color(0.25, 0.25, 0.25)

var card_id: StringName = &""

var _icon_texture: Texture2D = null


func setup(p_card_id: StringName) -> void:
	card_id = p_card_id

	var card_def: Dictionary = CardLib.get_card_def(card_id)
	if card_def.is_empty():
		push_warning("TenKingsHandCardUI: unknown card_id '%s'" % str(card_id))
		return

	# -- Size & mouse filter ------------------------------------------------
	custom_minimum_size = Vector2(70.0, 100.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# -- Background style ---------------------------------------------------
	var bg_style := StyleBoxFlat.new()
	var category: String = card_def.get("category", "")
	bg_style.bg_color = CATEGORY_COLORS.get(category, DEFAULT_BG_COLOR)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", bg_style)

	# -- Content layout -----------------------------------------------------
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	# Icon
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(60.0, 60.0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_path: String = card_def.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_icon_texture = load(icon_path) as Texture2D
		icon_rect.texture = _icon_texture

	vbox.add_child(icon_rect)

	# Name label
	var name_label := Label.new()
	name_label.text = card_def.get("display_name", str(card_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)


# ---------------------------------------------------------------------------
# Drag & Drop — this node is a drag SOURCE only
# ---------------------------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_id == &"":
		return null

	# Build a lightweight drag preview
	var preview := TextureRect.new()
	if _icon_texture != null:
		preview.texture = _icon_texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(50.0, 50.0)
	preview.size = Vector2(50.0, 50.0)
	preview.modulate = Color(1.0, 1.0, 1.0, 0.75)
	# Offset so the cursor sits at the center of the preview
	preview.position = Vector2(-25.0, -25.0)
	set_drag_preview(preview)

	return { "card_id": card_id, "source": "hand" }


# ---------------------------------------------------------------------------
# Hover highlight
# ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			modulate = Color(1.2, 1.2, 1.2)
		NOTIFICATION_MOUSE_EXIT:
			modulate = Color(1.0, 1.0, 1.0)
