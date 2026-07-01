extends RefCounted
class_name ProphecyUIBuilder

const SECTION_GAP_HEIGHT := 70
const SECTION_BANNER_HARD: Texture2D = preload("res://assets/ui/prophecy/hard.png")
const SECTION_BANNER_MID: Texture2D = preload("res://assets/ui/prophecy/mid.png")
const SECTION_BANNER_EASY: Texture2D = preload("res://assets/ui/prophecy/easy.png")

const LEGEND_ROW_HEIGHT := 48.0
const LEGEND_TITLE_FONT_SIZE := 36
const LEGEND_BADGE_FONT_SIZE := 30

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")
const RewardPresentationRegistryScript := preload("res://scripts/ui/rewards/RewardPresentationRegistry.gd")

func add_section_banner(container: VBoxContainer, tier_name: String) -> void:
	if container == null:
		return
	var tex := _get_banner_texture_for_tier(tier_name)
	var layer := Control.new()
	layer.custom_minimum_size = Vector2(0, SECTION_GAP_HEIGHT)
	layer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(layer)

	var banner := TextureRect.new()
	banner.texture = tex
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.offset_left = 0
	banner.offset_top = 0
	banner.offset_right = 0
	banner.offset_bottom = 0
	banner.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(banner)

	var label := Label.new()
	label.text = tier_name
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 0
	label.offset_top = 0
	label.offset_right = 0
	label.offset_bottom = 0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ThaleahFont)
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85, 1))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)

func add_vertical_gap(container: VBoxContainer, pixels: int) -> void:
	if container == null:
		return
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, pixels)
	container.add_child(spacer)

func build_tier_legend() -> Control:
	var legend := VBoxContainer.new()
	legend.name = "TierLegend"
	legend.custom_minimum_size = Vector2(260, 0)
	legend.set("theme_override_constants/separation", 6)
	legend.add_child(_build_tier_legend_row("HARD", ""))
	legend.add_child(_build_tier_legend_row("MID", ""))
	legend.add_child(_build_tier_legend_row("EASY", "MUST"))
	return legend

func _build_tier_legend_row(title: String, badge: String) -> Control:
	var row := Control.new()
	row.name = "%sRow" % _capitalize_tier_name(title)
	row.custom_minimum_size = Vector2(260, LEGEND_ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var banner := TextureRect.new()
	banner.name = "Banner"
	banner.texture = _get_tier_banner_texture(title)
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.offset_left = 0
	banner.offset_top = 0
	banner.offset_right = 0
	banner.offset_bottom = 0
	banner.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(banner)

	var content := HBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_top = 0
	content.offset_right = -12
	content.offset_bottom = 0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.set("theme_override_constants/separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(content)

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title
	title_label.add_theme_font_override("font", ThaleahFont)
	title_label.add_theme_font_size_override("font_size", LEGEND_TITLE_FONT_SIZE)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85, 1.0))
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("outline_color", Color.BLACK)
	content.add_child(title_label)

	if badge != "":
		var must_label := Label.new()
		must_label.name = "Badge"
		must_label.text = badge
		must_label.add_theme_font_override("font", ThaleahFont)
		must_label.add_theme_font_size_override("font_size", LEGEND_BADGE_FONT_SIZE)
		must_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))
		must_label.add_theme_constant_override("outline_size", 2)
		must_label.add_theme_color_override("outline_color", Color.BLACK)
		content.add_child(must_label)

	return row

func _get_tier_banner_texture(title: String) -> Texture2D:
	return _get_banner_texture_for_tier(title)

func _get_banner_texture_for_tier(tier_name: String) -> Texture2D:
	match tier_name:
		"HARD":
			return SECTION_BANNER_HARD
		"MID":
			return SECTION_BANNER_MID
		"EASY":
			return SECTION_BANNER_EASY
		_:
			return null

func _capitalize_tier_name(title: String) -> String:
	var lower := title.to_lower()
	if lower.is_empty():
		return "Tier"
	return "%s%s" % [lower.substr(0, 1).to_upper(), lower.substr(1)]

func populate_possible_rewards(rows_container: VBoxContainer) -> void:
	if rows_container == null:
		return
	for ch in rows_container.get_children():
		ch.queue_free()

	var entries := RewardPresentationRegistryScript.get_reward_entries(false)

	for e in entries:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = e
		var icon: Texture2D = d.get("icon", null)
		var label_text: String = str(d.get("name", ""))
		rows_container.add_child(_build_reward_row(icon, label_text))

func _build_reward_row(tex: Texture2D, label_text: String) -> Control:
	var row := HBoxContainer.new()
	row.set("theme_override_constants/separation", 10)

	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(34, 34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_override("font", ThaleahFont)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.25, 0.15, 0.05))
	row.add_child(label)

	return row

static func take_first(arr: Array, count: int) -> Array:
	var result: Array = []
	if arr == null:
		return result
	var c: int = min(count, arr.size())
	for i in range(c):
		result.append(arr[0])
		arr.remove_at(0)
	return result
