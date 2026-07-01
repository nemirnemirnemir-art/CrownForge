extends Node
class_name BarracksTooltips

const _TEX_WARRIOR := preload("res://assets/ui/class_ui/Warrior.png")
const _PATH_TOOLTIP_BG := "res://assets/ui/class_ui/UI_for_barrack_buttons.png"
const UnitInfoPanelScene := preload("res://scenes/ui/town/UnitInfoPanel.tscn")

var _mode_tooltip: Control = null
var _mode_tooltip_bg: TextureRect = null
var _mode_tooltip_label: Label = null
var _mode_button: Button = null

var _unit_tooltip: Control = null
var _unit_tooltip_bg: TextureRect = null
var _unit_tooltip_title: Label = null
var _unit_tooltip_base_header: Label = null
var _unit_tooltip_hp_label: Label = null
var _unit_tooltip_hp_value: Label = null
var _unit_tooltip_dps_label: Label = null
var _unit_tooltip_dps_value: Label = null
var _unit_tooltip_class_icon: TextureRect = null
var _unit_tooltip_class_label: Label = null
var _unit_tooltip_trait_header: Label = null
var _unit_tooltip_trait_description: Label = null

var _hovering_unit_face: bool = false
var _hovering_unit_tooltip: bool = false
var _hide_unit_tooltip_token: int = 0

var _collector: BarracksUnitCollector = null
var _unit_popup_panel: UnitInfoPanel = null

func initialize(
	mode_tooltip: Control,
	mode_tooltip_bg: TextureRect,
	mode_tooltip_label: Label,
	mode_button: Button,
	unit_tooltip: Control,
	unit_tooltip_bg: TextureRect,
	unit_tooltip_title: Label,
	unit_tooltip_base_header: Label,
	unit_tooltip_hp_label: Label,
	unit_tooltip_hp_value: Label,
	unit_tooltip_dps_label: Label,
	unit_tooltip_dps_value: Label,
	unit_tooltip_class_icon: TextureRect,
	unit_tooltip_class_label: Label,
	unit_tooltip_trait_header: Label,
	unit_tooltip_trait_description: Label,
	collector: BarracksUnitCollector
) -> void:
	_mode_tooltip = mode_tooltip
	_mode_tooltip_bg = mode_tooltip_bg
	_mode_tooltip_label = mode_tooltip_label
	_mode_button = mode_button
	_unit_tooltip = unit_tooltip
	_unit_tooltip_bg = unit_tooltip_bg
	_unit_tooltip_title = unit_tooltip_title
	_unit_tooltip_base_header = unit_tooltip_base_header
	_unit_tooltip_hp_label = unit_tooltip_hp_label
	_unit_tooltip_hp_value = unit_tooltip_hp_value
	_unit_tooltip_dps_label = unit_tooltip_dps_label
	_unit_tooltip_dps_value = unit_tooltip_dps_value
	_unit_tooltip_class_icon = unit_tooltip_class_icon
	_unit_tooltip_class_label = unit_tooltip_class_label
	_unit_tooltip_trait_header = unit_tooltip_trait_header
	_unit_tooltip_trait_description = unit_tooltip_trait_description
	_collector = collector
	
	if _mode_tooltip_bg:
		_mode_tooltip_bg.texture = load(_PATH_TOOLTIP_BG) as Texture2D
	if _unit_tooltip_bg:
		_unit_tooltip_bg.texture = load(_PATH_TOOLTIP_BG) as Texture2D
	if _mode_tooltip_label:
		_mode_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mode_tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_outline(_mode_tooltip_label, 20, 4)
	_style_unit_tooltip_controls()
	
	if _mode_tooltip:
		_mode_tooltip.visible = false
	if _unit_tooltip:
		_unit_tooltip.visible = false
	_ensure_unit_popup_panel()

func _ensure_unit_popup_panel() -> void:
	if _unit_popup_panel != null and is_instance_valid(_unit_popup_panel):
		return
	var parent: Node = null
	if _unit_tooltip and _unit_tooltip.get_parent():
		parent = _unit_tooltip.get_parent()
	elif _mode_tooltip and _mode_tooltip.get_parent():
		parent = _mode_tooltip.get_parent()
	if parent == null:
		return
	_unit_popup_panel = UnitInfoPanelScene.instantiate() as UnitInfoPanel
	if _unit_popup_panel == null:
		return
	parent.add_child(_unit_popup_panel)
	_unit_popup_panel.top_level = true
	_unit_popup_panel.visible = false
	_unit_popup_panel.z_index = 260
	_unit_popup_panel.mouse_entered.connect(func(): _hovering_unit_tooltip = true)
	_unit_popup_panel.mouse_exited.connect(func():
		_hovering_unit_tooltip = false
		schedule_hide_unit_tooltip()
	)

func show_mode_tooltip(mode: int) -> void:
	if _mode_tooltip == null:
		return
	_mode_tooltip.visible = true
	_mode_tooltip.z_index = 250
	_mode_tooltip.custom_minimum_size = Vector2(540, 120)
	_mode_tooltip.reset_size()
	var sz := _mode_tooltip.get_combined_minimum_size()
	if sz == Vector2.ZERO:
		sz = _mode_tooltip.custom_minimum_size
	_mode_tooltip.size = sz

	var anchor_rect := _mode_button.get_global_rect() if _mode_button else Rect2(_get_global_mouse_position(), Vector2.ZERO)
	var pos := Vector2(
		anchor_rect.position.x + anchor_rect.size.x * 0.5 - sz.x * 0.5,
		anchor_rect.position.y - sz.y - 8.0
	)

	var screen := _get_viewport_rect().size
	pos.x = clamp(pos.x, 5.0, max(5.0, screen.x - sz.x - 5.0))
	pos.y = clamp(pos.y, 5.0, max(5.0, screen.y - sz.y - 5.0))
	_mode_tooltip.global_position = pos
	
	if _mode_tooltip_label:
		match mode:
			0:
				_mode_tooltip_label.text = "Spawn troops on the battlefield\n\nChoose whether newly created troops should appear on the battlefield or in the barracks upon creation."
			1:
				_mode_tooltip_label.text = "Spawn troops in the barracks\n\nChoose whether newly created troops should appear on the battlefield or in the barracks upon creation."
			2:
				_mode_tooltip_label.text = "Spawn troops To Capacity\n\nTo Capacity mode allows units to be produced after the unit limit on the battlefield is reached while there is still space in the barracks."

func hide_mode_tooltip() -> void:
	if _mode_tooltip:
		_mode_tooltip.visible = false
		_mode_tooltip.z_index = 0

func show_unit_tooltip(unit_id: String) -> void:
	_ensure_unit_popup_panel()
	if _unit_popup_panel == null:
		return
	_hovering_unit_face = true
	_hide_unit_tooltip_token += 1
	_unit_popup_panel.setup(unit_id)
	_unit_popup_panel.visible = true
	_unit_popup_panel.z_index = 260
	_unit_popup_panel.reset_size()
	var tooltip_size := _unit_popup_panel.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = _unit_popup_panel.get_combined_minimum_size()
	if tooltip_size == Vector2.ZERO:
		tooltip_size = _unit_popup_panel.custom_minimum_size
	var pos := _get_global_mouse_position() + Vector2(16, 16)
	var screen := _get_viewport_rect().size
	pos.x = clampf(pos.x, 5.0, maxf(5.0, screen.x - tooltip_size.x - 5.0))
	pos.y = clampf(pos.y, 5.0, maxf(5.0, screen.y - tooltip_size.y - 5.0))
	_unit_popup_panel.global_position = pos

func hide_unit_tooltip() -> void:
	if _hovering_unit_face or _hovering_unit_tooltip:
		return
	if _unit_popup_panel and _unit_popup_panel.get_global_rect().has_point(_get_global_mouse_position()):
		return
	if _unit_popup_panel:
		_unit_popup_panel.visible = false
		_unit_popup_panel.z_index = 0
	if _unit_tooltip:
		_unit_tooltip.visible = false
		_unit_tooltip.z_index = 0

func schedule_hide_unit_tooltip() -> void:
	if _unit_tooltip == null:
		return
	_hide_unit_tooltip_token += 1
	var token := _hide_unit_tooltip_token
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	tree.create_timer(0.08).timeout.connect(func():
		if token != _hide_unit_tooltip_token:
			return
		hide_unit_tooltip()
	)

func on_face_unhover() -> void:
	_hovering_unit_face = false
	schedule_hide_unit_tooltip()

func _style_unit_tooltip_controls() -> void:
	if _unit_tooltip_title:
		_unit_tooltip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_title.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_title, 44, 6)
	if _unit_tooltip_base_header:
		_unit_tooltip_base_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_base_header.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_base_header, 32, 4)
	if _unit_tooltip_hp_label:
		_unit_tooltip_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_unit_tooltip_hp_label.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_hp_label, 32, 4)
	if _unit_tooltip_hp_value:
		_unit_tooltip_hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_hp_value.visible = false
		_unit_tooltip_hp_value.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_hp_value, 32, 4)
	if _unit_tooltip_dps_label:
		_unit_tooltip_dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_dps_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_unit_tooltip_dps_label.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_dps_label, 32, 4)
	if _unit_tooltip_dps_value:
		_unit_tooltip_dps_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_dps_value.visible = false
		_unit_tooltip_dps_value.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_dps_value, 32, 4)
	if _unit_tooltip_class_label:
		_unit_tooltip_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_class_label.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_class_label, 44, 4)
		var parent := _unit_tooltip_class_label.get_parent()
		if parent is BoxContainer:
			var bc := parent as BoxContainer
			bc.alignment = BoxContainer.ALIGNMENT_CENTER
	if _unit_tooltip_trait_header:
		_unit_tooltip_trait_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_trait_header.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_trait_header, 32, 4)
	if _unit_tooltip_trait_description:
		_unit_tooltip_trait_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_unit_tooltip_trait_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_unit_tooltip_trait_description.add_theme_color_override("font_color", Color.BLACK)
		_apply_outline(_unit_tooltip_trait_description, 30, 4)

func _apply_outline(label: Label, font_size: int, outline_size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline_size)

func _get_global_mouse_position() -> Vector2:
	var vp := Engine.get_main_loop().root.get_viewport() as Viewport
	if vp:
		return vp.get_mouse_position()
	return Vector2.ZERO

func _get_viewport_rect() -> Rect2:
	var vp := Engine.get_main_loop().root.get_viewport() as Viewport
	if vp:
		return vp.get_visible_rect()
	return Rect2(Vector2.ZERO, Vector2(1920, 1080))
