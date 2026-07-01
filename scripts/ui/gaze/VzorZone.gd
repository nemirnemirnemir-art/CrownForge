extends Node2D
class_name VzorZone

signal gaze_slots_changed

const _ModelScript := preload("res://scripts/ui/gaze/VzorZoneModel.gd")
const _ViewScript := preload("res://scripts/ui/gaze/VzorZoneView.gd")
const _DragControllerScript := preload("res://scripts/ui/gaze/VzorZoneDragController.gd")

@export var cell_size: Vector2 = Vector2(80, 80):
	set(v):
		cell_size = v
		if _model: _model.cell_size = v
		if _view: _view.cell_size = v

@export var line_color: Color = Color(0.95, 0.95, 0.95, 1.0):
	set(v):
		line_color = v
		if _view: _view.line_color = v

@export var invalid_line_color: Color = Color(1.0, 0.35, 0.35, 1.0):
	set(v):
		invalid_line_color = v
		if _view: _view.invalid_line_color = v

@export var line_width: float = 2.0

@export var drag_follow_speed: float = 12.0:
	set(v):
		drag_follow_speed = v
		if _drag_controller: _drag_controller.drag_follow_speed = v

@export var debug_vzor_input: bool = false:
	set(v):
		debug_vzor_input = v
		if _drag_controller: _drag_controller.debug_vzor_input = v

@onready var _map_layout := get_parent()
@onready var _gaze_tile_1: AnimatedSprite2D = $GazeTile1
@onready var _gaze_tile_2: AnimatedSprite2D = $GazeTile2
@onready var _gaze_tile_3: AnimatedSprite2D = $GazeTile3
@onready var _gaze_tile_4: AnimatedSprite2D = get_node_or_null("GazeTile4") as AnimatedSprite2D
@onready var _gaze_tile_5: AnimatedSprite2D = get_node_or_null("GazeTile5") as AnimatedSprite2D
@onready var _gaze_tile_6: AnimatedSprite2D = get_node_or_null("GazeTile6") as AnimatedSprite2D

var _gaze_core: Node = null
var _active_slots: Dictionary = {}

var _model = null      # VzorZoneModel
var _view = null       # VzorZoneView
var _drag_controller = null  # VzorZoneDragController

var _vzor_debug_timer: float = 0.0

func _tick_manager() -> Node:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("TickManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("vzor_zone")
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)

	_model = _ModelScript.new()
	_model.cell_size = cell_size
	_model.visual_offset = Vector2(-30, -45)

	_view = _ViewScript.new()
	_view.cell_size = cell_size
	_view.line_color = line_color
	_view.invalid_line_color = invalid_line_color
	_view.line_width = line_width

	_drag_controller = _DragControllerScript.new()
	_drag_controller.drag_follow_speed = drag_follow_speed
	_drag_controller.debug_vzor_input = debug_vzor_input

	_gaze_core = get_node_or_null("/root/GazeCore")
	if _gaze_core and _gaze_core.has_signal("gaze_level_changed"):
		_gaze_core.gaze_level_changed.connect(_on_gaze_level_changed)
	_model.setup(_gaze_core)

	var tiles: Array[AnimatedSprite2D] = [_gaze_tile_1, _gaze_tile_2, _gaze_tile_3]
	if _gaze_tile_4: tiles.append(_gaze_tile_4)
	if _gaze_tile_5: tiles.append(_gaze_tile_5)
	if _gaze_tile_6: tiles.append(_gaze_tile_6)
	_view.setup(self, tiles)

	_drag_controller.setup(self, _model)

	_refresh_view()
	call_deferred("_initialize_placement")

func _initialize_placement() -> void:
	if not is_inside_tree():
		return
	if _map_layout:
		var attempts := 0
		while _map_layout.slots.is_empty() and attempts < 5:
			await get_tree().process_frame
			attempts += 1
	_model.rebuild_valid_cells(_map_layout.slots if _map_layout else [])
	_model.move_to_central_placement(_get_visible_center_in_map_local())
	_model.commit_placement()
	if not _model.can_place_at(_model.get_corner_cell(), _model.get_orientation()):
		_model.move_to_first_valid_placement()
	_update_world_position()
	position = _drag_controller.get_target_position()

func _on_gaze_level_changed(_lvl: int) -> void:
	if not _model.can_place_at(_model.get_corner_cell(), _model.get_orientation()):
		_model.move_to_central_placement(_get_visible_center_in_map_local())
	_update_world_position()

func _input(event: InputEvent) -> void:
	_drag_controller.handle_input(event)
	_refresh_view()

func _unhandled_input(event: InputEvent) -> void:
	_drag_controller.handle_unhandled_input(event)
	_refresh_view()

func _process(delta: float) -> void:
	var tree := get_tree()
	var tick_manager := _tick_manager()
	var pause_like_state := (tree and tree.paused) or is_equal_approx(Engine.time_scale, 0.0) or (tick_manager and bool(tick_manager.get("is_paused")))
	var real_delta := delta
	if is_equal_approx(Engine.time_scale, 0.0):
		real_delta = 0.016
	_vzor_debug_timer += delta
	if _vzor_debug_timer >= 2.0:
		_vzor_debug_timer = 0.0
		print("[VzorZone] dragging=%s pause_like=%s target_pos=%s slots=%d" % [
			str(_drag_controller.is_dragging() if _drag_controller else false),
			str(pause_like_state),
			str(_drag_controller.get_target_position() if _drag_controller else Vector2.ZERO),
			_active_slots.size(),
		])
	_drag_controller.update_visual_position(real_delta)

	if not _map_layout:
		return

	var scaled_delta: float = delta
	if tick_manager and tick_manager.has_method("get_scaled_delta"):
		scaled_delta = float(tick_manager.get_scaled_delta(delta))
	if tree and tree.paused:
		scaled_delta = 0.0
	var slots := _get_slots_under_gaze()
	if scaled_delta <= 0.0:
		_sync_active_slots([])
		return
	_sync_active_slots(slots)
	for slot in slots:
		if slot and slot.has_method("tick_production"):
			slot.tick_production(scaled_delta)

# --- Internal orchestration helpers ---

func _update_world_position() -> void:
	_model.commit_world_position()
	_drag_controller.set_target_position(_model.get_target_position())
	_refresh_view()

func _refresh_view() -> void:
	_view.update_gaze_tiles(_model.get_offsets(), _model.is_preview_valid())

func _get_visible_center_in_map_local() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var cam := viewport.get_camera_2d()
	var world_center := Vector2.ZERO
	if cam:
		world_center = cam.get_screen_center_position()
	else:
		var screen_center := viewport.get_visible_rect().size * 0.5
		world_center = viewport.get_canvas_transform().affine_inverse() * screen_center
	if _map_layout and _map_layout is Node2D:
		return (_map_layout as Node2D).to_local(world_center)
	return world_center

func _get_slots_under_gaze() -> Array:
	var result: Array = []
	if _drag_controller.is_dragging() and not _model.is_preview_valid():
		return result
	var corner_cell: Vector2i = _model.get_corner_cell()
	if _drag_controller.is_dragging():
		corner_cell = _model.get_preview_corner_cell()
	var offsets = _model.get_offsets()
	for offset in offsets:
		var cell: Vector2i = corner_cell + offset
		var slot := _find_slot_in_cell(cell)
		if slot:
			result.append(slot)
	return result

func _find_slot_in_cell(cell: Vector2i) -> MapSlot:
	if not _map_layout:
		return null
	for slot in _map_layout.slots:
		if slot == null:
			continue
		var slot_cell: Vector2i = _model.get_cell_from_position(slot.position)
		if slot_cell == cell:
			return slot
	return null

func _sync_active_slots(slots: Array) -> void:
	var new_active: Dictionary = {}
	for slot in slots:
		if slot == null:
			continue
		new_active[slot.get_instance_id()] = slot
		if slot.has_method("set_vzor_active"):
			slot.set_vzor_active(true)
	for id in _active_slots.keys():
		if not new_active.has(id):
			var old_slot = _active_slots[id]
			if old_slot and is_instance_valid(old_slot) and old_slot.has_method("set_vzor_active"):
				old_slot.set_vzor_active(false)
	var slots_changed := new_active.keys() != _active_slots.keys()
	_active_slots = new_active
	if slots_changed:
		gaze_slots_changed.emit()

func cancel_drag() -> void:
	if _drag_controller:
		_drag_controller.cancel_drag()
		_refresh_view()

func reset_drag_hover_state() -> void:
	if _drag_controller:
		_drag_controller.reset_hover_state()
