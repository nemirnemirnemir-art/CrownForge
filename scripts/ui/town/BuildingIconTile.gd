extends Button
class_name BuildingIconTile

const BuildingUpgradeVisualsScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd")

signal tile_pressed(building_id: String)
signal hover_started(building_id: String)
signal hover_ended(building_id: String)
signal drag_started(building_id: String)

@onready var _icon: TextureRect = get_node_or_null("Icon")
@onready var _recipe_badge: Label = get_node_or_null("RecipeBadge")
@onready var _upgrade_stripe: TextureRect = get_node_or_null("UpgradeStripe")

var building_id: String = ""
var _selected: bool = false
var _affordable: bool = true
var _dragging: bool = false

var _base_normal: StyleBoxFlat
var _base_hover: StyleBoxFlat
var _base_pressed: StyleBoxFlat

const BUDDHIST_TEMPLE_ICON_SCALE := 1.30

func _building_registry() -> Node:
	return get_node_or_null("/root/BuildingRegistry")

func _town_core() -> Node:
	return get_node_or_null("/root/TownCore")

func _seal_registry() -> Node:
	return get_node_or_null("/root/SealRegistry")

func _building_upgrade_core() -> Node:
	return get_node_or_null("/root/BuildingUpgradeCore")

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	var building_registry := _building_registry()
	if building_registry and not building_registry.recipe_changed.is_connected(_on_recipe_changed):
		building_registry.recipe_changed.connect(_on_recipe_changed)
	var upgrade_core := _building_upgrade_core()
	if upgrade_core and upgrade_core.has_signal("building_upgrades_changed") and not upgrade_core.building_upgrades_changed.is_connected(_on_building_upgrades_changed):
		upgrade_core.building_upgrades_changed.connect(_on_building_upgrades_changed)

	# Гарантируем наличие иконки и её правильный визуал
	if _icon == null:
		_icon = TextureRect.new()
		_icon.name = "Icon"
		add_child(_icon)
	
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Делаем иконку на 75% от размера кнопки и центрируем
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.anchor_left = 0.03125
	_icon.anchor_top = 0.03125
	_icon.anchor_right = 0.96875
	_icon.anchor_bottom = 0.96875
	_icon.offset_left = 0
	_icon.offset_top = 0
	_icon.offset_right = 0
	_icon.offset_bottom = 0
	_apply_icon_visual_scale("")

	var n := get_theme_stylebox("normal")
	var h := get_theme_stylebox("hover")
	var p := get_theme_stylebox("pressed")

	if n is StyleBoxFlat:
		_base_normal = (n as StyleBoxFlat).duplicate()
	if h is StyleBoxFlat:
		_base_hover = (h as StyleBoxFlat).duplicate()
	if p is StyleBoxFlat:
		_base_pressed = (p as StyleBoxFlat).duplicate()

	_apply_style()
	_update_recipe_badge()
	_update_upgrade_stripe()
	tooltip_text = ""

func setup(id: String, data: Resource) -> void:
	building_id = id
	_apply_icon_visual_scale(building_id)
	if data and data is BuildingConfig:
		var bc := data as BuildingConfig
		if _icon:
			_icon.texture = bc.get_icon_or_placeholder()
			_icon.show()
		tooltip_text = ""
		var cost_affordable := false
		var building_registry := _building_registry()
		var town_core := _town_core()
		if building_registry:
			cost_affordable = building_registry.can_afford_building(id)
		elif town_core:
			cost_affordable = town_core.can_build(id)
		modulate = Color(1.0, 1.0, 1.0, 1.0) if cost_affordable else Color(0.65, 0.65, 0.65, 1.0)
	elif data and data is BuildingData:
		var bd := data as BuildingData
		if _icon:
			_icon.texture = bd.icon
			_icon.show()
		tooltip_text = ""
		# Check if it has description/cost (or other functional logic)
		var building_registry := _building_registry()
		var cost = building_registry.get_next_build_cost(id) if building_registry else {}
		var is_blank = bd.description == "" or bd.description.begins_with("TODO")
		if is_blank or (cost.is_empty() and id != "well"):
			modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif data and data is SealConfig:
		var sc := data as SealConfig
		if _icon:
			_icon.texture = sc.icon
			_icon.show()
		tooltip_text = ""
		
		# Check affordability
		var can_afford = true
		var seal_registry := _seal_registry()
		if seal_registry:
			can_afford = seal_registry.can_afford_seal(id)
		modulate = Color(1.0, 1.0, 1.0, 1.0) if can_afford else Color(0.65, 0.65, 0.65, 1.0)
	else:
		if _icon: _icon.texture = null
		tooltip_text = ""
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	_update_recipe_badge()
	_update_upgrade_stripe()

func _apply_icon_visual_scale(id: String) -> void:
	if _icon == null:
		return
	if id == "buddhist_temple":
		_icon.anchor_left = -0.15
		_icon.anchor_top = -0.15
		_icon.anchor_right = 1.15
		_icon.anchor_bottom = 1.15
		_icon.scale = Vector2.ONE * BUDDHIST_TEMPLE_ICON_SCALE
	else:
		_icon.anchor_left = 0.03125
		_icon.anchor_top = 0.03125
		_icon.anchor_right = 0.96875
		_icon.anchor_bottom = 0.96875
		_icon.scale = Vector2.ONE

func _on_recipe_changed(changed_id: String, _new_count: int) -> void:
	if changed_id == building_id:
		_update_recipe_badge()

func _update_recipe_badge() -> void:
	if not _recipe_badge:
		return
	var building_registry := _building_registry()
	if not building_registry or building_id == "":
		_recipe_badge.visible = false
		return
	var count: int = int(building_registry.get_recipe_count(building_id))
	if count > 0:
		_recipe_badge.text = str(count)
		_recipe_badge.visible = true
	else:
		_recipe_badge.visible = false

func _update_upgrade_stripe() -> void:
	if _upgrade_stripe == null:
		return
	if building_id == "":
		_upgrade_stripe.visible = false
		_upgrade_stripe.texture = null
		return
	var upgrade_core := _building_upgrade_core()
	var level := int(upgrade_core.call("get_building_upgrade_level", building_id)) if upgrade_core and upgrade_core.has_method("get_building_upgrade_level") else 0
	var texture := BuildingUpgradeVisualsScript.get_stripe_texture(level)
	_upgrade_stripe.texture = texture
	_upgrade_stripe.visible = texture != null

func _on_building_upgrades_changed(changed_building_id: String, _level: int) -> void:
	if changed_building_id == building_id:
		_update_upgrade_stripe()

func set_selected(is_selected: bool) -> void:
	if _selected == is_selected:
		return
	_selected = is_selected
	_apply_style()

func set_affordable(is_affordable: bool) -> void:
	if _affordable == is_affordable:
		return
	_affordable = is_affordable
	_apply_style()

func _apply_style() -> void:
	if _base_normal:
		var s := _base_normal.duplicate()
		if _selected:
			s.border_width_left = 3
			s.border_width_top = 3
			s.border_width_right = 3
			s.border_width_bottom = 3
			s.border_color = Color(1.0, 0.95, 0.4, 1.0)
		else:
			s.border_width_left = 0
			s.border_width_top = 0
			s.border_width_right = 0
			s.border_width_bottom = 0
		add_theme_stylebox_override("normal", s)

	if _base_hover:
		var sh := _base_hover.duplicate()
		if _selected:
			sh.border_width_left = 3
			sh.border_width_top = 3
			sh.border_width_right = 3
			sh.border_width_bottom = 3
			sh.border_color = Color(1.0, 0.95, 0.4, 1.0)
		else:
			sh.border_width_left = 0
			sh.border_width_top = 0
			sh.border_width_right = 0
			sh.border_width_bottom = 0
		add_theme_stylebox_override("hover", sh)

	if _base_pressed:
		var sp := _base_pressed.duplicate()
		if _selected:
			sp.border_width_left = 3
			sp.border_width_top = 3
			sp.border_width_right = 3
			sp.border_width_bottom = 3
			sp.border_color = Color(1.0, 0.95, 0.4, 1.0)
		else:
			sp.border_width_left = 0
			sp.border_width_top = 0
			sp.border_width_right = 0
			sp.border_width_bottom = 0
		add_theme_stylebox_override("pressed", sp)

	if _affordable:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(0.65, 0.65, 0.65, 1.0)

func _on_pressed() -> void:
	if building_id == "":
		return
	if not _affordable:
		return
	tile_pressed.emit(building_id)

func _on_mouse_entered() -> void:
	if building_id != "":
		hover_started.emit(building_id)

func _on_mouse_exited() -> void:
	hover_ended.emit(building_id)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = _affordable and building_id != ""
			else:
				_dragging = false
	
	if event is InputEventMouseMotion and _dragging:
		if building_id != "" and _affordable:
			drag_started.emit(building_id)
			_dragging = false # Only emit once per drag
