# Enemy Culling API Contract

**Feature**: Enemy Swarm Optimization  
**Date**: 2025-01-09  
**Status**: Design

## Overview

This document defines the API contract for enemy culling and despawn functionality. Methods are additions to the existing `Enemy.gd` base class.

## New Methods

### `_check_culling() -> bool`

**Description**: Checks if enemy should be culled (despawned) based on distance to player and quality settings.

**Parameters**: None

**Returns**: `bool` - `true` if enemy should be despawned, `false` otherwise

**Implementation**:
```gdscript
func _check_culling() -> bool:
    if _target == null:
        return false
    
    var distance: float = global_position.distance_to(_target.global_position)
    var culling_dist: float = QualityManager.get_culling_distance()
    
    if distance > culling_dist:
        var quality: int = QualityManager.current_quality
        if quality >= 2:
            _fade_out_and_despawn()  # Optional fade for quality 2-3
        else:
            queue_free()  # Immediate despawn for quality 0-1
        return true
    return false
```

**Call Frequency**: Every 0.5-1.0 seconds (not every frame) via `_process()` or `_physics_process()`

---

### `_fade_out_and_despawn() -> void`

**Description**: Fades out enemy sprite and then despawns (optional visual polish for quality levels 2-3).

**Parameters**: None

**Returns**: `void`

**Implementation**:
```gdscript
func _fade_out_and_despawn() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    tween.tween_callback(queue_free)
```

**Usage**: Only called at quality levels 2-3 for visual polish. Quality 0-1 use immediate `queue_free()`.

---

### `_update_off_screen_state() -> void`

**Description**: Updates `_is_off_screen` flag based on viewport visibility and distance.

**Parameters**: None

**Returns**: `void`

**Implementation**:
```gdscript
func _update_off_screen_state() -> void:
    var viewport: Viewport = get_viewport()
    var viewport_rect: Rect2 = viewport.get_visible_rect()
    var camera: Camera2D = viewport.get_camera_2d()
    
    if camera == null:
        _is_off_screen = false
        return
    
    var screen_pos: Vector2 = camera.to_screen_coordinate(global_position)
    var was_off_screen: bool = _is_off_screen
    _is_off_screen = not viewport_rect.has_point(screen_pos)
    
    # Apply off-screen simplifications
    if _is_off_screen and not was_off_screen:
        _apply_off_screen_simplifications()
    elif not _is_off_screen and was_off_screen:
        _remove_off_screen_simplifications()
```

**Call Frequency**: Every frame or every 0.1-0.2 seconds (performance trade-off)

---

## Enhanced Properties

### `_is_off_screen: bool`

**Type**: `bool`

**Description**: Flag indicating if enemy is off-screen. Used for applying simplifications.

**Usage**:
```gdscript
if _is_off_screen:
    # Disable animations, use simplified AI
    _anim.stop()
    _use_simplified_ai = true
```

---

### `_distance_to_player: float`

**Type**: `float`

**Description**: Cached distance to player (updated periodically, not every frame).

**Usage**:
```gdscript
_distance_to_player = global_position.distance_to(_target.global_position)
if _distance_to_player > QualityManager.get_culling_distance():
    _check_culling()
```

---

## Integration with Existing Methods

### `set_quality_settings(settings: Dictionary)`

**Enhancement**: Now also updates culling behavior based on quality level.

**Existing Usage**:
```gdscript
func set_quality_settings(settings: Dictionary) -> void:
    _use_simplified_ai = settings.get("simplified_ai", false)
    # ... existing code ...
```

**New Addition**:
```gdscript
func set_quality_settings(settings: Dictionary) -> void:
    _use_simplified_ai = settings.get("simplified_ai", false)
    # ... existing code ...
    # Culling is handled by _check_culling() using QualityManager.get_culling_distance()
```

---

## Call Flow

### Culling Check Flow
```
_physics_process(delta)
  → _update_off_screen_state()  # Update off-screen flag
  → _check_culling()            # Check if should despawn
    → If distance > culling_distance:
      → _fade_out_and_despawn() or queue_free()
```

### Off-screen Simplification Flow
```
_update_off_screen_state()
  → If _is_off_screen changed:
    → _apply_off_screen_simplifications() or _remove_off_screen_simplifications()
      → Disable/enable animations
      → Switch to/from simplified AI
```

---

## Performance Considerations

- **Culling Check Frequency**: Not every frame (0.5-1.0s interval)
- **Distance Calculation**: Cache `_distance_to_player`, update every 0.5s
- **Off-screen Check**: Can use viewport rect check (cheaper than distance calculation)

---

## Error Handling

- **Null target**: If `_target == null`, skip culling check (return `false`)
- **Invalid viewport**: If viewport is null, assume on-screen (`_is_off_screen = false`)
- **Invalid camera**: If camera is null, skip off-screen check

---

## References

- Implementation plan: `specs/007-enemy-swarm-optimization/plan.md`
- Data model: `specs/007-enemy-swarm-optimization/data-model.md`
- Existing code: `gameplay/enemies/Enemy.gd`

