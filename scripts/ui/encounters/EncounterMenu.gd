extends Control
class_name EncounterMenu

signal option_selected(encounter_id: String, option_id: String)
signal closed

@onready var title_label: Label = get_node_or_null("Root/Panel/Margin/Title") as Label
@onready var description_label: Label = get_node_or_null("Root/Panel/Margin/Description") as Label
@onready var subtitle_label: Label = get_node_or_null("Root/Panel/Margin/SubTitle") as Label
@onready var options_container: VBoxContainer = get_node_or_null("Root/Panel/Margin/Options") as VBoxContainer

var _encounter_id: String = ""
var _icon_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func open(encounter: Dictionary) -> void:
	_encounter_id = String(encounter.get("id", ""))
	if _encounter_id == "":
		return

	var title := String(encounter.get("title", "Encounter"))
	if title_label:
		title_label.text = title
		
	var desc := String(encounter.get("description", ""))
	if description_label:
		description_label.text = desc
		description_label.visible = desc != ""
		
	if subtitle_label:
		subtitle_label.text = "Choose one option"

	var options_var: Variant = encounter.get("options", [])
	_rebuild_options(options_var)
	visible = true


func close_menu() -> void:
	if not visible:
		return
	print("[EncounterMenu][DEBUG] close_menu | encounter_id=%s visible=%s" % [_encounter_id, str(visible)])
	visible = false
	_encounter_id = ""
	_clear_options()
	closed.emit()


func _rebuild_options(options_var: Variant) -> void:
	_clear_options()
	if not options_container:
		return
	if not (options_var is Array):
		return

	for raw_option in options_var:
		if not (raw_option is Dictionary):
			continue
		var option: Dictionary = raw_option
		var option_id := String(option.get("id", ""))
		var option_label := String(option.get("label", ""))
		if option_id == "" or option_label == "":
			continue

		var button := _build_option_button(option)
		button.disabled = not bool(option.get("enabled", true))
		_apply_button_theme(button, not button.disabled)
		if not button.disabled:
			button.pressed.connect(_on_option_pressed.bind(option_id))
		options_container.add_child(button)


func _build_option_button(option: Dictionary) -> Button:
	var option_label := String(option.get("label", ""))
	var effects_text := String(option.get("effects_text", ""))
	var requirements_text := String(option.get("requirements_text", ""))

	var button := Button.new()
	button.text = _build_button_text(option_label, effects_text, requirements_text)
	button.custom_minimum_size = Vector2(0.0, 154.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)

	var content_row := HBoxContainer.new()
	content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.add_theme_constant_override("separation", 12)
	margin.add_child(content_row)

	var primary_icon := TextureRect.new()
	primary_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	primary_icon.custom_minimum_size = Vector2(64, 64)
	primary_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	primary_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	primary_icon.texture = _resolve_primary_icon(option)
	content_row.add_child(primary_icon)

	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	content_row.add_child(body)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = option_label
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.add_child(title)

	var effect_rows_var: Variant = option.get("effects_rows", [])
	if effect_rows_var is Array:
		for raw_row in effect_rows_var:
			if not (raw_row is Dictionary):
				continue
			body.add_child(_build_info_row(raw_row, false))

	var requirement_rows_var: Variant = option.get("requirements_rows", [])
	if requirement_rows_var is Array and not requirement_rows_var.is_empty():
		var req_caption := Label.new()
		req_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		req_caption.text = "Requirements"
		req_caption.add_theme_font_size_override("font_size", 18)
		req_caption.add_theme_color_override("font_color", Color(0.32, 0.25, 0.19, 1.0))
		body.add_child(req_caption)
		for raw_req in requirement_rows_var:
			if not (raw_req is Dictionary):
				continue
			body.add_child(_build_info_row(raw_req, true))

	return button


func _build_info_row(row_data: Dictionary, is_requirement: bool) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _resolve_row_icon(row_data)
	row.add_child(icon)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = String(row_data.get("text", ""))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", _resolve_row_color(row_data, is_requirement))
	row.add_child(label)

	return row


func _resolve_primary_icon(option: Dictionary) -> Texture2D:
	var effects_rows_var: Variant = option.get("effects_rows", [])
	if effects_rows_var is Array:
		for raw_row in effects_rows_var:
			if raw_row is Dictionary:
				var icon := _resolve_row_icon(raw_row)
				if icon != null:
					return icon

	var requirement_rows_var: Variant = option.get("requirements_rows", [])
	if requirement_rows_var is Array:
		for raw_req in requirement_rows_var:
			if raw_req is Dictionary:
				var req_icon := _resolve_row_icon(raw_req)
				if req_icon != null:
					return req_icon

	return null


func _resolve_row_icon(row_data: Dictionary) -> Texture2D:
	var inline_icon: Variant = row_data.get("icon_texture", null)
	if inline_icon is Texture2D:
		return inline_icon

	var path := String(row_data.get("icon_path", ""))
	if path == "":
		return null
	if _icon_cache.has(path):
		var cached: Variant = _icon_cache[path]
		if cached is Texture2D:
			return cached
		return null

	if not ResourceLoader.exists(path):
		_icon_cache[path] = null
		return null

	var loaded := load(path) as Texture2D
	_icon_cache[path] = loaded
	return loaded


func _resolve_row_color(row_data: Dictionary, is_requirement: bool) -> Color:
	if is_requirement:
		var met := bool(row_data.get("met", true))
		if not met:
			return Color(0.72, 0.2, 0.18, 1.0)
		return Color(0.17, 0.27, 0.17, 1.0)

	var tone := String(row_data.get("tone", "neutral"))
	if tone == "positive":
		return Color(0.15, 0.32, 0.15, 1.0)
	if tone == "negative":
		return Color(0.72, 0.2, 0.18, 1.0)
	return Color(0.2, 0.16, 0.12, 1.0)


func _apply_button_theme(button: Button, enabled: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(1, 2)

	var hover := normal.duplicate() as StyleBoxFlat
	var pressed := normal.duplicate() as StyleBoxFlat
	var disabled := normal.duplicate() as StyleBoxFlat

	if enabled:
		normal.bg_color = Color(0.93, 0.87, 0.77, 1.0)
		normal.border_color = Color(0.45, 0.33, 0.2, 1.0)
		hover.bg_color = Color(0.97, 0.91, 0.8, 1.0)
		hover.border_color = Color(0.6, 0.43, 0.23, 1.0)
		pressed.bg_color = Color(0.86, 0.8, 0.71, 1.0)
		pressed.border_color = Color(0.35, 0.26, 0.16, 1.0)
		disabled.bg_color = Color(0.66, 0.62, 0.57, 0.95)
		disabled.border_color = Color(0.4, 0.37, 0.33, 1.0)
	else:
		normal.bg_color = Color(0.67, 0.63, 0.58, 0.98)
		normal.border_color = Color(0.43, 0.39, 0.34, 1.0)
		hover.bg_color = normal.bg_color
		hover.border_color = normal.border_color
		pressed.bg_color = normal.bg_color
		pressed.border_color = normal.border_color
		disabled.bg_color = Color(0.58, 0.55, 0.51, 0.98)
		disabled.border_color = Color(0.4, 0.37, 0.33, 1.0)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _build_button_text(label: String, effects_text: String, requirements_text: String) -> String:
	var lines: Array[String] = [label]
	if effects_text != "":
		lines.append(effects_text)
	if requirements_text != "":
		lines.append(requirements_text)
	return "\n".join(lines)


func _on_option_pressed(option_id: String) -> void:
	if option_id == "" or _encounter_id == "":
		return
	print("[EncounterMenu][DEBUG] option_pressed | encounter_id=%s option_id=%s" % [_encounter_id, option_id])
	option_selected.emit(_encounter_id, option_id)
	close_menu()


func _clear_options() -> void:
	if not options_container:
		return
	for child in options_container.get_children():
		child.queue_free()
