extends Node2D
class_name MapMarker

## Map marker for spawn/defense/patrol points, etc.
## Placed in the scene editor

enum MarkerType { SPAWN, DEFENSE, PATROL, PORTAL, BRIDGE, WALL }

@export var marker_type: MarkerType = MarkerType.SPAWN
@export var marker_id: String = ""
@export var priority: int = 0  ## Used for sorting when multiple markers of the same type exist

## Visual indicator in editor (debug only)
@export var debug_color: Color = Color.GREEN
@export var debug_radius: float = 20.0

func _ready() -> void:
    add_to_group("map_markers")
    add_to_group(_get_group_name())

func _get_group_name() -> String:
    match marker_type:
        MarkerType.SPAWN: return "spawn_markers"
        MarkerType.DEFENSE: return "defense_markers"
        MarkerType.PATROL: return "patrol_markers"
        MarkerType.PORTAL: return "portal_markers"
        MarkerType.BRIDGE: return "bridge_markers"
        MarkerType.WALL: return "wall_markers"
    return "map_markers"

## Get spawn position with optional random jitter
func get_spawn_position(jitter: float = 0.0) -> Vector2:
    if jitter > 0:
        return global_position + Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
    return global_position

## Draw marker in editor for visualization
func _draw() -> void:
    if Engine.is_editor_hint():
        draw_circle(Vector2.ZERO, debug_radius, Color(debug_color, 0.5))
        draw_arc(Vector2.ZERO, debug_radius, 0, TAU, 32, debug_color, 2.0)
        
        # Marker type label
        var _label: String = MarkerType.keys()[marker_type]
        if marker_id != "":
            _label += " (" + marker_id + ")"
