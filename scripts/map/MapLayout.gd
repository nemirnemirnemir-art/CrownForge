extends Node2D
class_name MapLayout

const CELL_SIZE = Vector2(80, 80)
const GRID_WIDTH = 14
const GRID_HEIGHT = 7
const SPAWN_MARKERS_COUNT: int = 32
const SPAWN_RING_RADIUS: float = 85.0

@export var spawn_markers_offset: Vector2 = Vector2.ZERO
@export var castle_cluster_offset: Vector2 = Vector2(88.0, 0.0)

var slots: Array[MapSlot] = []

# Simplified map - building slots only
# x: Building slot
# S: Wall
# M: Bridge  
# P: Portal
# N: Nothing (or any other character)

var map_data = [
    "NNNNxNNNNNNNNN",
    "xxxxSNNNNNNNNN",
    "xxxxSNNNNNNNNN",
    "xxxxSMNNNNNNNP",
    "xxxxSNNNNNNNNN",
    "xxxxSNNNNNNNNN",
    "BNNNNNNNNNNNNN"
]

@onready var bridge_pos: Vector2 = Vector2.ZERO
@onready var portal_pos: Vector2 = Vector2.ZERO

func _ready():
    _apply_castle_cluster_offset_to_existing_nodes()
    if _register_existing_slots():
        _generate_map(true)
    else:
        initialize_layout()


func _apply_castle_cluster_offset_to_existing_nodes() -> void:
    if castle_cluster_offset == Vector2.ZERO:
        return

    for child in get_children():
        if child is MapSlot:
            (child as MapSlot).position += castle_cluster_offset
        elif child is Node2D and child.name == "Wall":
            (child as Node2D).position += castle_cluster_offset

func initialize_layout():
    if not slots.is_empty():
        return
    _generate_map()

    slots.clear()
    var found := false
    for child in get_children():
        if child is MapSlot and child.is_building_slot:
            found = true
            var slot: MapSlot = child
            if slot.slot_index < 0:
                slot.slot_index = slots.size()
            slots.append(slot)
            _ensure_slot_debug(slot)
    if not found:
        return false
    
    var bridge_node = get_node_or_null("Bridge")
    if bridge_node and bridge_node is Node2D:
        bridge_pos = (bridge_node as Node2D).position
    var portal_node = get_node_or_null("Portal")
    if portal_node and portal_node is Node2D:
        portal_pos = (portal_node as Node2D).position
    return true

func _generate_map(skip_slots: bool = false):
    # Create NavigationRegion2D
    var nav_region = get_node_or_null("NavigationRegion2D")
    if not nav_region:
        nav_region = NavigationRegion2D.new()
        nav_region.name = "NavigationRegion2D"
        add_child(nav_region)
        
        var nav_poly = NavigationPolygon.new()
        var rect = PackedVector2Array([
            Vector2(-1000, -1000),
            Vector2(3000, -1000),
            Vector2(3000, 1500),
            Vector2(-1000, 1500)
        ])
        nav_poly.vertices = rect
        nav_poly.add_polygon(PackedInt32Array([0, 1, 2, 3]))
        nav_region.navigation_polygon = nav_poly
        nav_region.enabled = true

    for y in range(GRID_HEIGHT):
        for x in range(GRID_WIDTH):
            var cell_type = map_data[y][x]
            var pos = Vector2(x * CELL_SIZE.x, y * CELL_SIZE.y)
            
            if cell_type == 'x':
                if skip_slots:
                    continue
                _create_slot(pos, slots.size(), true)
            elif cell_type == 'M':
                _create_bridge_marker(pos)
                bridge_pos = pos + CELL_SIZE/2
            elif cell_type == 'P':
                _create_portal_marker(pos)
                portal_pos = pos + CELL_SIZE/2
            elif cell_type == 'S':
                var existing_wall := get_node_or_null("Wall") as Node2D
                if existing_wall == null:
                    _create_wall(pos)
                    existing_wall = get_node_or_null("Wall") as Node2D

                if existing_wall != null:
                    _ensure_wall_related_markers(existing_wall.position)

const MapSlotScene = preload("res://scenes/map/MapSlot.tscn")

func _create_slot(pos: Vector2, index: int, is_building: bool):
    var slot = MapSlotScene.instantiate()
    slot.position = pos + CELL_SIZE/2
    slot.slot_index = index
    slot.is_building_slot = is_building
    add_child(slot)
    slots.append(slot)
    _ensure_slot_debug(slot)

func _ensure_slot_debug(slot: MapSlot) -> void:
    if slot.has_node("DebugRect"):
        return
    var color_rect = ColorRect.new()
    color_rect.name = "DebugRect"
    color_rect.size = Vector2(40, 40)
    color_rect.position = Vector2(-20, -20)
    color_rect.color = Color(0, 1, 0, 0.2)
    color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    color_rect.z_index = -1
    slot.add_child(color_rect)

## Creates a bridge marker (MapMarker)
func _create_bridge_marker(pos: Vector2):
    var marker_exists = get_node_or_null("BridgeMarker")
    if marker_exists:
        return
        
    var marker = MapMarker.new()
    marker.name = "BridgeMarker"
    marker.position = pos + CELL_SIZE/2
    marker.marker_type = MapMarker.MarkerType.BRIDGE
    marker.debug_color = Color.BLUE
    add_child(marker)
    
    # Also create a visual node
    var visual_node = Node2D.new()
    visual_node.name = "Bridge"
    visual_node.position = pos + CELL_SIZE/2
    add_child(visual_node)

## Creates a portal marker (MapMarker) + spawn markers around it
func _create_portal_marker(pos: Vector2):
    var marker_exists = get_node_or_null("PortalMarker")
    if marker_exists:
        return

    var portal_visual := get_node_or_null("Portal") as Node2D
    var portal_center := pos + CELL_SIZE / 2
    if portal_visual != null:
        portal_center = portal_visual.position
    
    # Portal marker
    var marker = MapMarker.new()
    marker.name = "PortalMarker"
    marker.position = portal_center
    marker.marker_type = MapMarker.MarkerType.PORTAL
    marker.debug_color = Color.PURPLE
    add_child(marker)
    
    # Portal visual node (create only when scene has none)
    if portal_visual == null:
        var visual_node = Node2D.new()
        visual_node.name = "Portal"
        visual_node.position = portal_center
        add_child(visual_node)
    
    # Spawn markers around the portal
    _create_spawn_markers(portal_center)

## Creates spawn markers around a center point in a circular pattern
func _create_spawn_markers(center: Vector2):
    for child in get_children():
        if child is MapMarker and (child as MapMarker).marker_type == MapMarker.MarkerType.SPAWN:
            child.queue_free()

    var spawn_center := center + spawn_markers_offset
    for i in range(SPAWN_MARKERS_COUNT):
        var angle = float(i) / float(SPAWN_MARKERS_COUNT) * TAU
        var offset = Vector2(cos(angle), sin(angle)) * SPAWN_RING_RADIUS
        
        var spawn_marker = MapMarker.new()
        spawn_marker.name = "SpawnMarker_%d" % i
        spawn_marker.position = spawn_center + offset
        spawn_marker.marker_type = MapMarker.MarkerType.SPAWN
        spawn_marker.priority = i
        spawn_marker.debug_color = Color.RED
        add_child(spawn_marker)

const WallScene = preload("res://scenes/map/Wall.tscn")

func _create_wall(pos: Vector2):
    var wall = WallScene.instantiate()
    wall.name = "Wall"
    wall.position = pos + Vector2(CELL_SIZE.x / 2, CELL_SIZE.y * 3.5)
    add_child(wall)
    
    wall.wall_damaged.connect(_on_wall_damaged)
    wall.wall_destroyed.connect(_on_wall_destroyed)

    _ensure_wall_related_markers(wall.position)

func _has_marker_type(marker_type: MapMarker.MarkerType) -> bool:
    for child in get_children():
        if child is MapMarker and (child as MapMarker).marker_type == marker_type:
            return true
    return false

func _ensure_wall_related_markers(wall_pos: Vector2) -> void:
    if not _has_marker_type(MapMarker.MarkerType.WALL):
        var wall_marker = MapMarker.new()
        wall_marker.name = "WallMarker"
        wall_marker.position = wall_pos
        wall_marker.marker_type = MapMarker.MarkerType.WALL
        wall_marker.debug_color = Color.GRAY
        add_child(wall_marker)

    if not _has_marker_type(MapMarker.MarkerType.DEFENSE):
        _create_defense_markers(wall_pos)

## Creates defense position markers for heroes
func _create_defense_markers(wall_pos: Vector2):
    # 6 hero positions in 2 rows
    var defense_offsets = [
        Vector2(60, 50),    # Row 1
        Vector2(60, 0),
        Vector2(60, -50),
        Vector2(120, 70),   # Row 2
        Vector2(120, 20),
        Vector2(120, -30),
    ]
    
    for i in range(defense_offsets.size()):
        var def_marker = MapMarker.new()
        def_marker.name = "DefenseMarker_%d" % i
        def_marker.position = wall_pos + defense_offsets[i]
        def_marker.marker_type = MapMarker.MarkerType.DEFENSE
        def_marker.priority = i
        def_marker.debug_color = Color.CYAN
        add_child(def_marker)

func _on_wall_damaged(_damage: int, current_hp: int, max_hp: int):
    print("[MapLayout] Wall damaged! HP: %d/%d" % [current_hp, max_hp])

func _on_wall_destroyed():
    print("[MapLayout] Wall destroyed! Game Over!")
    get_tree().paused = true

func get_bridge_position() -> Vector2:
    return bridge_pos

func get_portal_position() -> Vector2:
    return portal_pos

func _register_existing_slots() -> bool:
    slots.clear()
    var found := false
    for child in get_children():
        if child is MapSlot and child.is_building_slot:
            found = true
            var slot: MapSlot = child
            if slot.slot_index < 0:
                slot.slot_index = slots.size()
            slots.append(slot)
            _ensure_slot_debug(slot)

    if not found:
        return false

    var bridge_node = get_node_or_null("Bridge")
    if bridge_node and bridge_node is Node2D:
        bridge_pos = (bridge_node as Node2D).position
    var portal_node = get_node_or_null("Portal")
    if portal_node and portal_node is Node2D:
        portal_pos = (portal_node as Node2D).position
    return true
