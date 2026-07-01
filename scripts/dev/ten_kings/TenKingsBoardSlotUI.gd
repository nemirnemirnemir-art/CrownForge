## Visual representation of a single board slot in the 5×5 grid.
## Handles display (locked/empty/occupied) and acts as a drag-and-drop target
## for card placement from the hand.  Created purely in code — no .tscn needed.
extends PanelContainer

const BoardVisualLibraryScript = preload("res://scripts/dev/ten_kings/TenKingsBoardVisualLibrary.gd")

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

signal card_dropped(slot_pos: Vector2i, card_id: StringName)
signal slot_hover_started(slot_pos: Vector2i)
signal slot_hover_ended(slot_pos: Vector2i)

# ---------------------------------------------------------------------------
# Slot state constants (mirrors BoardState.SlotState values)
# ---------------------------------------------------------------------------

const STATE_LOCKED: int = 0
const STATE_EMPTY: int = 1
const STATE_OCCUPIED: int = 2

# ---------------------------------------------------------------------------
# Color scheme
# ---------------------------------------------------------------------------

const COLOR_LOCKED: Color = Color(0.15, 0.15, 0.15)
const COLOR_EMPTY: Color = Color(0.3, 0.3, 0.35)
const COLOR_OCCUPIED: Color = Color(0.2, 0.35, 0.2)
const COLOR_HIGHLIGHT: Color = Color(0.5, 0.5, 0.1)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var grid_pos: Vector2i = Vector2i.ZERO
var _current_state: int = STATE_LOCKED

# ---------------------------------------------------------------------------
# Child nodes (created in setup)
# ---------------------------------------------------------------------------

var _bg_style: StyleBoxFlat
var _layout: VBoxContainer
var _pack_grid: GridContainer
var _preview_layer: Control
var _building_sprite: TextureRect
var _icon_rect: TextureRect
var _info_label: Label
var _damage_label: Label
var _pack_icons: Array[TextureRect] = []
var _troop_figures: Array[TextureRect] = []
var _slot_size: float = 56.0
var _preview_data: Dictionary = {}
var _board_visual_library := BoardVisualLibraryScript.new()
var _troop_frames: Array[Texture2D] = []
var _troop_frame_index: int = 0
var _troop_frame_elapsed: float = 0.0

const _TROOP_FRAME_DURATION: float = 0.18

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Called once by the Prototype script right after instantiation.
## Creates child UI elements and stores the grid position.
func setup(pos: Vector2i, slot_size: float = 56.0) -> void:
	grid_pos = pos
	_slot_size = slot_size

	custom_minimum_size = Vector2(_slot_size, _slot_size)

	_bg_style = StyleBoxFlat.new()
	_bg_style.bg_color = COLOR_LOCKED
	_bg_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _bg_style)

	_layout = VBoxContainer.new()
	_layout.name = "Layout"
	_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin: float = clampf(_slot_size * 0.07, 4.0, 8.0)
	_layout.offset_left = margin
	_layout.offset_top = margin
	_layout.offset_right = -margin
	_layout.offset_bottom = -margin
	_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	_layout.add_theme_constant_override("separation", 2)
	add_child(_layout)

	_pack_grid = GridContainer.new()
	_pack_grid.name = "PackGrid"
	_pack_grid.columns = 3
	_pack_grid.visible = false
	_pack_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pack_grid.add_theme_constant_override("h_separation", 2)
	_pack_grid.add_theme_constant_override("v_separation", 2)
	_layout.add_child(_pack_grid)

	_preview_layer = Control.new()
	_preview_layer.name = "PreviewLayer"
	_preview_layer.custom_minimum_size = Vector2(_slot_size * 0.72, _slot_size * 0.72)
	_preview_layer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_layer.visible = false
	_layout.add_child(_preview_layer)

	_building_sprite = TextureRect.new()
	_building_sprite.name = "BuildingSprite"
	_building_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_building_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_building_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_building_sprite.visible = false
	_preview_layer.add_child(_building_sprite)

	for figure_index: int in range(5):
		var troop_figure := TextureRect.new()
		troop_figure.name = "TroopFigure%d" % figure_index
		troop_figure.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		troop_figure.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		troop_figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		troop_figure.visible = false
		_preview_layer.add_child(troop_figure)
		_troop_figures.append(troop_figure)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconRect"
	var icon_size: float = _slot_size * 0.5
	_icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	_icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon_rect.visible = false
	_layout.add_child(_icon_rect)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_layout.add_child(_info_label)

	_damage_label = Label.new()
	_damage_label.text = ""
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_damage_label.modulate = Color.WHITE
	_damage_label.add_theme_font_override("font", load("res://assets/ui/fonts/ThaleahFat.ttf"))
	_damage_label.add_theme_font_size_override("font_size", 12)
	_damage_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_damage_label.visible = false
	_layout.add_child(_damage_label)

	for _index: int in range(9):
		var mini_icon := TextureRect.new()
		var mini_icon_size: float = maxf(12.0, _slot_size * 0.22)
		mini_icon.custom_minimum_size = Vector2(mini_icon_size, mini_icon_size)
		mini_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		mini_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mini_icon.visible = false
		_pack_grid.add_child(mini_icon)
		_pack_icons.append(mini_icon)

	update_display(STATE_LOCKED, null, 0, "")


## Updates the slot visuals based on the provided state and card info.
## Note: level and extra_info are kept in signature for compatibility but no longer displayed inline.
## Details are now shown in a hover tooltip instead.
func update_display(state: int, icon_texture: Texture2D, _level: int, _extra_info: String, pack_icon_count: int = 0) -> void:
	_current_state = state

	match state:
		STATE_LOCKED:
			_bg_style.bg_color = COLOR_LOCKED
			_clear_preview_visuals()
			_set_single_icon(null)
			_set_pack_preview(null, 0)
			_info_label.text = ""

		STATE_EMPTY:
			_bg_style.bg_color = COLOR_EMPTY
			_clear_preview_visuals()
			_set_single_icon(null)
			_set_pack_preview(null, 0)
			_info_label.text = ""

		STATE_OCCUPIED:
			_bg_style.bg_color = COLOR_OCCUPIED
			_clear_preview_visuals()
			if pack_icon_count > 0:
				_set_single_icon(null)
				_set_pack_preview(icon_texture, pack_icon_count)
			else:
				_set_pack_preview(null, 0)
				_set_single_icon(icon_texture)
			# Visual-only: no inline text details, hover tooltip shows them instead
			_info_label.text = ""

		_:
			push_warning("TenKingsBoardSlotUI: unknown state %d" % state)

	if state != STATE_OCCUPIED:
		_preview_data.clear()


func _set_single_icon(texture: Texture2D) -> void:
	_icon_rect.texture = texture
	_icon_rect.visible = texture != null


func _set_pack_preview(texture: Texture2D, icon_count: int) -> void:
	var visible_count: int = maxi(0, mini(icon_count, _pack_icons.size()))
	for index: int in range(_pack_icons.size()):
		var mini_icon: TextureRect = _pack_icons[index]
		var should_show: bool = texture != null and index < visible_count
		mini_icon.texture = texture
		mini_icon.visible = should_show
	_pack_grid.visible = texture != null and visible_count > 0


func set_preview_data(preview_data: Dictionary) -> void:
	_preview_data = preview_data.duplicate(true)
	_clear_preview_visuals()
	if _current_state != STATE_OCCUPIED or _preview_data.is_empty():
		return

	var card_id: StringName = StringName(_preview_data.get("card_id", &""))
	var side: int = int(_preview_data.get("side", 0))
	var kind: String = String(_preview_data.get("kind", ""))
	if kind == "building":
		var building_texture := _board_visual_library.get_building_texture(card_id, side)
		if building_texture != null:
			_preview_layer.visible = true
			_building_sprite.texture = building_texture
			_building_sprite.visible = true
			_icon_rect.visible = false
			_pack_grid.visible = false
		return

	if kind == "troop":
		_troop_frames = _board_visual_library.get_troop_frames(card_id, side)
		if not _troop_frames.is_empty():
			_troop_frame_index = 0
			_troop_frame_elapsed = 0.0
			_preview_layer.visible = true
			_icon_rect.visible = false
			_pack_grid.visible = false
			_update_troop_figure_layout(int(_preview_data.get("stack_count", 1)))
			_apply_troop_frame(_troop_frames[0])


func _clear_preview_visuals() -> void:
	_preview_layer.visible = false
	_building_sprite.visible = false
	_building_sprite.texture = null
	_troop_frames.clear()
	_troop_frame_index = 0
	_troop_frame_elapsed = 0.0
	for troop_figure: TextureRect in _troop_figures:
		troop_figure.visible = false
		troop_figure.texture = null


func _update_troop_figure_layout(stack_count: int) -> void:
	var figure_count: int = _get_troop_figure_count(stack_count)
	var preview_width: float = maxf(_preview_layer.custom_minimum_size.x, _slot_size * 0.72)
	var preview_height: float = maxf(_preview_layer.custom_minimum_size.y, _slot_size * 0.72)
	for figure_index: int in range(_troop_figures.size()):
		var troop_figure: TextureRect = _troop_figures[figure_index]
		if figure_index >= figure_count:
			troop_figure.visible = false
			continue
		var figure_size := Vector2(_slot_size * 0.28, _slot_size * 0.4)
		var row: int = figure_index / 3
		var col: int = figure_index % 3
		var base_x: float = preview_width * 0.16 + col * (_slot_size * 0.17)
		var base_y: float = preview_height * 0.2 + row * (_slot_size * 0.12)
		troop_figure.position = Vector2(base_x, base_y)
		troop_figure.size = figure_size
		troop_figure.z_index = figure_index
		troop_figure.visible = true


func _get_troop_figure_count(stack_count: int) -> int:
	if stack_count <= 1:
		return 1
	if stack_count <= 6:
		return 2
	if stack_count <= 12:
		return 3
	if stack_count <= 18:
		return 4
	return 5


func _apply_troop_frame(texture: Texture2D) -> void:
	for troop_figure: TextureRect in _troop_figures:
		if troop_figure.visible:
			troop_figure.texture = texture


## Visual feedback to indicate a valid drop target during drag hover.
func set_highlight(enabled: bool) -> void:
	if _bg_style == null:
		return
	if enabled:
		_bg_style.border_color = COLOR_HIGHLIGHT
		_bg_style.set_border_width_all(2)
	else:
		_bg_style.border_color = Color.TRANSPARENT
		_bg_style.set_border_width_all(0)

# ---------------------------------------------------------------------------
# Drag-and-drop target overrides
# ---------------------------------------------------------------------------

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	var dict: Dictionary = data as Dictionary
	if not dict.has("card_id"):
		return false
	# Accept drop on EMPTY or OCCUPIED slots (validation is done by Prototype/TurnFlow)
	var is_droppable: bool = _current_state != STATE_LOCKED
	# Visual highlight while hovering
	set_highlight(is_droppable)
	return is_droppable


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	set_highlight(false)
	if data is Dictionary:
		var dict: Dictionary = data as Dictionary
		if dict.has("card_id"):
			var cid: StringName = StringName(dict["card_id"])
			card_dropped.emit(grid_pos, cid)


## Called when a drag leaves the control without dropping.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_highlight(false)


# ---------------------------------------------------------------------------
# Hover detection for tooltip system
# ---------------------------------------------------------------------------

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	if _troop_frames.size() <= 1 or not _preview_layer.visible:
		return
	_troop_frame_elapsed += delta
	if _troop_frame_elapsed < _TROOP_FRAME_DURATION:
		return
	_troop_frame_elapsed = 0.0
	_troop_frame_index = (_troop_frame_index + 1) % _troop_frames.size()
	_apply_troop_frame(_troop_frames[_troop_frame_index])


func _on_mouse_entered() -> void:
	slot_hover_started.emit(grid_pos)


func _on_mouse_exited() -> void:
	slot_hover_ended.emit(grid_pos)


## Update damage total display for this slot.
## Pass 0 to hide the damage label.
func set_slot_damage_total(damage: int) -> void:
	if damage <= 0:
		_damage_label.visible = false
		_damage_label.text = ""
	else:
		_damage_label.text = str(damage)
		_damage_label.visible = true
