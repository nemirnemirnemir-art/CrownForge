extends RefCounted

var drag_follow_speed: float = 12.0
var debug_vzor_input: bool = false

var _dragging: bool = false
var _drag_pointer_offset: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO

var _zone: Node2D = null
var _model = null  # VzorZoneModel

func setup(zone: Node2D, model) -> void:
    _zone = zone
    _model = model

func is_dragging() -> bool:
    return _dragging

func cancel_drag() -> void:
    if not _dragging:
        return
    _dragging = false
    if _model != null and _model.has_method("get_target_position"):
        _target_position = _model.get_target_position()

func get_target_position() -> Vector2:
    return _target_position

func set_target_position(pos: Vector2) -> void:
    _target_position = pos

func handle_input(event: InputEvent) -> void:
    _handle_pointer_input(event)

func handle_unhandled_input(event: InputEvent) -> void:
    _handle_pointer_input(event)

func update_visual_position(delta: float) -> void:
    if _zone == null or not is_instance_valid(_zone):
        return
    if _zone.position == _target_position:
        return
    var t := clampf(drag_follow_speed * delta, 0.0, 1.0)
    if t <= 0.0:
        return
    var new_position := _zone.position.lerp(_target_position, t)
    if new_position.distance_to(_target_position) < 0.1:
        new_position = _target_position
    if new_position != _zone.position:
        _zone.position = new_position

func _handle_pointer_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton or event is InputEventMouseMotion):
        return

    if event is InputEventMouseButton:
        var left_mouse_event := event as InputEventMouseButton
        if left_mouse_event.button_index == MOUSE_BUTTON_LEFT and not left_mouse_event.pressed and _dragging:
            var release_map_local := _to_map_local(_get_pointer_world_pos())
            _dragging = false
            _run_preview(release_map_local)
            _model.apply_drop()
            _target_position = _model.get_target_position()
            return

    # Right-click: rotate before checking UI block
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
            var pre_map_local: Vector2 = _to_map_local(_get_pointer_world_pos())
            if _point_hits_zone(pre_map_local):
                var rotated: bool = _model.rotate_clockwise()
                if rotated and not _dragging:
                    _model.commit_world_position()
                var vp := _zone.get_viewport()
                if vp:
                    vp.set_input_as_handled()
                return

    if _is_mouse_over_ui() and not _dragging:
        if debug_vzor_input and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
            pass
        return

    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        var map_local := _to_map_local(_get_pointer_world_pos())
        if mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if mouse_event.pressed:
                if Input.is_key_pressed(KEY_SHIFT):
                    return
                if _point_hits_zone(map_local):
                    _dragging = true
                    _drag_pointer_offset = map_local - _zone.position
                    _model.start_drag()
    elif event is InputEventMouseMotion and _dragging:
        var map_local := _to_map_local(_get_pointer_world_pos())
        _run_preview(map_local)

func _run_preview(map_local: Vector2) -> void:
    if _model.cell_size.x == 0 or _model.cell_size.y == 0:
        return
    var desired_top_left := map_local - _drag_pointer_offset
    var snapped_cell: Vector2i = _model.compute_cell_from_top_left(desired_top_left)
    var placement_valid: bool = _model.can_place_at(snapped_cell, _model.get_orientation())
    _model.update_preview(snapped_cell, placement_valid)
    _target_position = Vector2(snapped_cell) * _model.cell_size + _model.visual_offset

func _get_pointer_world_pos() -> Vector2:
    return _zone.get_global_mouse_position()

func _to_map_local(global_pos: Vector2) -> Vector2:
    if _zone.get_parent():
        return _zone.get_parent().to_local(global_pos)
    return global_pos

func _point_hits_zone(map_local: Vector2) -> bool:
    var local_point := map_local - _zone.position
    for offset in _model.get_offsets():
        var tile_rect := Rect2(Vector2(offset) * _model.cell_size, _model.cell_size).grow(10.0)
        if tile_rect.has_point(local_point):
            return true
    return false

func _is_mouse_over_ui() -> bool:
    var vp := _zone.get_viewport()
    if vp == null:
        return false
    var hovered := vp.gui_get_hovered_control()
    if hovered == null:
        return false
    if not hovered.is_visible_in_tree():
        return false
    var n: Node = hovered
    while n != null:
        if n is Control:
            var control := n as Control
            if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
                return true
        n = n.get_parent()
    return false

func reset_hover_state() -> void:
    ## Called after UI panels close to flush stale gui_get_hovered_control() state.
    if _zone == null or not is_instance_valid(_zone):
        return
    var vp := _zone.get_viewport()
    if vp:
        vp.warp_mouse(vp.get_mouse_position())
