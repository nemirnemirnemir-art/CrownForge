extends "res://core/buildings/special/GenericSpecialBuilding.gd"

var _is_vzor_active: bool = false
var _affected_slots: Array = []
var _neighbor_signature: String = ""

const SOURCE_ID_PREFIX := "monument_to_kings_gaze:"
const POSITION_BUCKET_TOLERANCE := 4.0
const DEBUG_MONUMENT_GAZE := false

func tick(_delta: float) -> Dictionary:
    if _is_vzor_active:
        var next_signature: String = _build_neighbor_signature()
        if next_signature != _neighbor_signature:
            _refresh_affected_slots()
    return {"progress_ratio": 0.0, "is_producing": false, "completed": false, "cycle_time": 0.0}

func set_vzor_active(active: bool) -> void:
    if _is_vzor_active == active:
        return
    _is_vzor_active = active
    _refresh_affected_slots()

func cleanup() -> void:
    _clear_external_gaze()

func _refresh_affected_slots() -> void:
    _clear_external_gaze()
    _neighbor_signature = ""
    if not _is_vzor_active:
        return
    var neighbors := _find_orthogonal_neighbors()
    for slot in neighbors:
        if slot == null:
            continue
        if slot.has_method("set_external_vzor_active"):
            slot.call("set_external_vzor_active", _get_source_id(), true)
            _affected_slots.append(slot)
    _neighbor_signature = _signature_from_slots(neighbors)
    if DEBUG_MONUMENT_GAZE:
        var affected_ids: Array[String] = []
        for slot_value in _affected_slots:
            var slot := slot_value as Node
            if slot == null:
                continue
            var raw_slot_index: Variant = slot.get("slot_index")
            var slot_index: int = -1
            var building_id: String = ""
            if raw_slot_index != null:
                slot_index = int(raw_slot_index)
            var raw_building_id: Variant = slot.get("current_building_id")
            if raw_building_id != null:
                building_id = String(raw_building_id)
            affected_ids.append("%d:%s" % [slot_index, building_id])
        print("[MonumentToKingsGaze] source=%s active=%s affected=%s" % [_get_source_id(), str(_is_vzor_active), affected_ids])

func _clear_external_gaze() -> void:
    for slot in _affected_slots:
        if slot == null or not is_instance_valid(slot):
            continue
        if slot.has_method("set_external_vzor_active"):
            slot.call("set_external_vzor_active", _get_source_id(), false)
    _affected_slots.clear()

func _build_neighbor_signature() -> String:
    return _signature_from_slots(_find_orthogonal_neighbors())

func _signature_from_slots(slots: Array) -> String:
    var parts: Array[String] = []
    for slot_value in slots:
        var slot := slot_value as Node2D
        if slot == null:
            continue
        var raw_slot_index: Variant = slot.get("slot_index")
        var slot_index: int = -1
        if raw_slot_index != null:
            slot_index = int(raw_slot_index)
        parts.append("%d@%.1f:%.1f" % [slot_index, slot.position.x, slot.position.y])
    parts.sort()
    return "|".join(parts)

func _find_orthogonal_neighbors() -> Array:
    var result: Array = []
    var map_layout := _get_map_layout()
    if map_layout == null:
        return result
    var slots: Variant = map_layout.get("slots")
    if not (slots is Array) or _slot == null or not (_slot is Node2D):
        return result
    var positions_by_key: Dictionary = {}
    var unique_x: Array[float] = []
    var unique_y: Array[float] = []
    for candidate_value in slots:
        var candidate := candidate_value as Node2D
        if candidate == null:
            continue
        var bucket_x := _bucket_position(candidate.position.x)
        var bucket_y := _bucket_position(candidate.position.y)
        var key := _make_grid_key(bucket_x, bucket_y)
        positions_by_key[key] = candidate
        _append_unique_bucket(unique_x, bucket_x)
        _append_unique_bucket(unique_y, bucket_y)

    unique_x.sort()
    unique_y.sort()

    var slot2d := _slot as Node2D
    var current_x := _bucket_position(slot2d.position.x)
    var current_y := _bucket_position(slot2d.position.y)
    var column_index := unique_x.find(current_x)
    var row_index := unique_y.find(current_y)
    if column_index < 0 or row_index < 0:
        return result

    var neighbor_offsets := [
        Vector2i(-1, 0),
        Vector2i(1, 0),
        Vector2i(0, -1),
        Vector2i(0, 1),
    ]
    for offset in neighbor_offsets:
        var next_column: int = column_index + offset.x
        var next_row: int = row_index + offset.y
        if next_column < 0 or next_column >= unique_x.size():
            continue
        if next_row < 0 or next_row >= unique_y.size():
            continue
        var lookup_key := _make_grid_key(unique_x[next_column], unique_y[next_row])
        var neighbor: Variant = positions_by_key.get(lookup_key, null)
        if neighbor != null:
            result.append(neighbor)
    return result

func _append_unique_bucket(values: Array[float], bucket: float) -> void:
    for existing in values:
        if is_equal_approx(existing, bucket):
            return
    values.append(bucket)

func _bucket_position(value: float) -> float:
    return snappedf(value, POSITION_BUCKET_TOLERANCE)

func _make_grid_key(x_value: float, y_value: float) -> String:
    return "%s:%s" % [str(x_value), str(y_value)]

func _get_map_layout() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    var game_scene := tree.get_first_node_in_group("game_scene")
    if game_scene == null:
        game_scene = tree.current_scene
    if game_scene == null:
        return null
    var raw_map_layout: Node = game_scene.get("map_layout_node")
    if raw_map_layout != null:
        return raw_map_layout
    return game_scene.get_node_or_null("WorldYSort/MapContainer/MapLayout")

func _get_source_id() -> String:
    var slot_index: int = -1
    if _slot != null:
        var raw_slot_index: Variant = _slot.get("slot_index")
        if raw_slot_index != null:
            slot_index = int(raw_slot_index)
    return "%s%d" % [SOURCE_ID_PREFIX, slot_index]
