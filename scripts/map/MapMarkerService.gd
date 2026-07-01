extends Node

## Service for accessing map markers
## Autoload singleton - single source of truth for positions

var _cached_spawn_markers: Array[MapMarker] = []
var _cached_defense_markers: Array[MapMarker] = []
var _cache_valid: bool = false
var _spawn_cycle_indices: Array[int] = []
var _spawn_cycle_cursor: int = 0

func _ready() -> void:
    # Invalidate cache on scene changes
    get_tree().tree_changed.connect(_invalidate_cache)

func _invalidate_cache() -> void:
    _cache_valid = false
    _cached_spawn_markers.clear()
    _cached_defense_markers.clear()
    _spawn_cycle_indices.clear()
    _spawn_cycle_cursor = 0

## === SPAWN MARKERS ===

func get_spawn_markers() -> Array[MapMarker]:
    if not _cache_valid:
        _rebuild_cache()
    return _cached_spawn_markers

func get_random_spawn_position(jitter: float = 30.0) -> Vector2:
    var markers := get_spawn_markers()
    if markers.is_empty():
        # Fallback to portal
        return get_portal_position()
    var marker := _get_next_spawn_marker()
    if marker == null:
        return get_portal_position()
    return marker.get_spawn_position(jitter)

func get_spawn_position_by_priority(priority: int, jitter: float = 30.0) -> Vector2:
    var markers = get_spawn_markers()
    for marker in markers:
        if marker.priority == priority:
            return marker.get_spawn_position(jitter)
    return get_random_spawn_position(jitter)

## === DEFENSE MARKERS ===

func get_defense_markers() -> Array[MapMarker]:
    if not _cache_valid:
        _rebuild_cache()
    return _cached_defense_markers

func get_defense_position(index: int) -> Vector2:
    var markers = get_defense_markers()
    if markers.is_empty():
        # Fallback to bridge
        return get_bridge_position()
    
    # Sort by priority
    markers.sort_custom(func(a, b): return a.priority < b.priority)
    
    if index < markers.size():
        return markers[index].global_position
    
    # If index exceeds marker count - use last marker + offset
    var last_marker = markers[markers.size() - 1]
    var extra_index = index - markers.size()
    var col = extra_index % 3
    var row = int(float(extra_index) / 3.0)
    var offset = Vector2(-60 - col * 50, -40 - row * 40)
    return last_marker.global_position + offset

func get_all_defense_positions() -> Array[Vector2]:
    var result: Array[Vector2] = []
    var markers = get_defense_markers()
    markers.sort_custom(func(a, b): return a.priority < b.priority)
    for marker in markers:
        result.append(marker.global_position)
    return result

## === KEY POSITION MARKERS ===

func get_portal_position() -> Vector2:
    var markers = get_tree().get_nodes_in_group("portal_markers")
    if markers.size() > 0 and is_instance_valid(markers[0]):
        return markers[0].global_position
    
    # Fallback: Try to find MapLayout and query it directly
    var map_layouts = get_tree().get_nodes_in_group("map_layout")
    for layout in map_layouts:
        if layout.has_method("get_portal_position"):
            var pos: Vector2 = layout.get_portal_position()
            if pos != Vector2.ZERO:
                return pos
    
    # Try finding via game_scene
    var game_scenes = get_tree().get_nodes_in_group("game_scene")
    for gs in game_scenes:
        var map_layout = gs.get_node_or_null("WorldYSort/MapContainer/MapLayout")
        if map_layout and map_layout.has_method("get_portal_position"):
            var pos: Vector2 = map_layout.get_portal_position()
            if pos != Vector2.ZERO:
                return pos
    
    # Last resort fallback - far right side of the map
    push_warning("[MapMarkerService] Portal marker not found! Using fallback.")
    return Vector2(1600, 300)  # Approximate portal position (right side of battlefield)

func get_bridge_position() -> Vector2:
    var markers = get_tree().get_nodes_in_group("bridge_markers")
    if markers.size() > 0 and is_instance_valid(markers[0]):
        return markers[0].global_position
    # Fallback
    push_warning("[MapMarkerService] Bridge marker not found!")
    return Vector2(400, 300)  # Approximate default bridge position

func get_wall_position() -> Vector2:
    var markers = get_tree().get_nodes_in_group("wall_markers")
    if markers.size() > 0 and is_instance_valid(markers[0]):
        return markers[0].global_position
    # Fallback - try to find Wall via group
    var walls = get_tree().get_nodes_in_group("wall")
    if walls.size() > 0 and is_instance_valid(walls[0]):
        return walls[0].global_position
    push_warning("[MapMarkerService] Wall marker not found!")
    return Vector2(350, 300)

## === PATROL MARKERS ===

func get_patrol_markers() -> Array[MapMarker]:
    var result: Array[MapMarker] = []
    for node in get_tree().get_nodes_in_group("patrol_markers"):
        if node is MapMarker:
            result.append(node)
    result.sort_custom(func(a, b): return a.priority < b.priority)
    return result

func get_patrol_path() -> Array[Vector2]:
    var result: Array[Vector2] = []
    for marker in get_patrol_markers():
        result.append(marker.global_position)
    return result

## === UTILITY ===

func _rebuild_cache() -> void:
    _cached_spawn_markers.clear()
    _cached_defense_markers.clear()
    
    for node in get_tree().get_nodes_in_group("spawn_markers"):
        if node is MapMarker:
            _cached_spawn_markers.append(node)
    
    for node in get_tree().get_nodes_in_group("defense_markers"):
        if node is MapMarker:
            _cached_defense_markers.append(node)

    _rebuild_spawn_cycle()
    
    _cache_valid = true

func _rebuild_spawn_cycle() -> void:
    _spawn_cycle_indices.clear()
    for i in range(_cached_spawn_markers.size()):
        _spawn_cycle_indices.append(i)
    _spawn_cycle_indices.shuffle()
    _spawn_cycle_cursor = 0

func _get_next_spawn_marker() -> MapMarker:
    if _cached_spawn_markers.is_empty():
        return null
    if _spawn_cycle_indices.size() != _cached_spawn_markers.size() or _spawn_cycle_indices.is_empty():
        _rebuild_spawn_cycle()
    if _spawn_cycle_cursor >= _spawn_cycle_indices.size():
        _spawn_cycle_indices.shuffle()
        _spawn_cycle_cursor = 0
    var marker_index := int(_spawn_cycle_indices[_spawn_cycle_cursor])
    _spawn_cycle_cursor += 1
    if marker_index < 0 or marker_index >= _cached_spawn_markers.size():
        return _cached_spawn_markers[0]
    return _cached_spawn_markers[marker_index]

func _get_markers_by_group(group: String) -> Array[MapMarker]:
    var result: Array[MapMarker] = []
    for node in get_tree().get_nodes_in_group(group):
        if node is MapMarker:
            result.append(node)
    return result

## Debug - print all markers
func debug_print_markers() -> void:
    print("[MapMarkerService] === Markers Debug ===")
    print("  Spawn markers: %d" % get_spawn_markers().size())
    print("  Defense markers: %d" % get_defense_markers().size())
    print("  Portal: %v" % get_portal_position())
    print("  Bridge: %v" % get_bridge_position())
    print("  Wall: %v" % get_wall_position())
