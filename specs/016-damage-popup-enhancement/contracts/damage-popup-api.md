# API Contract: DamagePopup

**Phase**: 1 - Design  
**Date**: 2025-01-XX  
**Status**: ✅ Complete

## Overview

DamagePopup is a visual effect that displays damage numbers with smooth animations. It appears when mobs take damage, floats upward, scales down, and fades out.

## Public API

### Methods

#### `set_damage(damage: float) -> void`

Sets the damage value to display and starts the animation sequence.

**Parameters**:
- `damage: float` - Damage amount to display (must be >= 0)

**Behavior**:
- Sets internal `damage_value` property
- Updates Label text to display damage (formatted as integer)
- Initializes animation state (scale = 0, opacity = 1)
- Calculates target position (30 pixels upward from current position)
- Starts appearance animation (0.1s scale-in)
- Appearance animation triggers main animations on completion

**Example**:
```gdscript
var popup = damage_popup_scene.instantiate()
get_tree().current_scene.add_child(popup)
popup.global_position = mob.global_position
popup.set_damage(42.5)  # Displays "42" or "43"
```

**Edge Cases**:
- Negative damage: Clamped to 0, displays "0"
- Very large damage: Label handles formatting automatically
- Called multiple times: Only first call starts animation, subsequent calls ignored

---

## Internal API (Implementation Details)

### Private Methods

#### `_start_appearance() -> void`

Starts the quick appearance animation (0.1s scale-in).

**Behavior**:
- Creates new Tween instance
- Animates scale from Vector2.ZERO to Vector2.ONE
- Sets transition to CUBIC with EASE_OUT
- Calls `_start_main_animations()` when complete

**Called by**: `set_damage()`

---

#### `_start_main_animations() -> void`

Starts the main animation sequence (1.5s parallel animations).

**Behavior**:
- Creates new Tween instance with parallel mode enabled
- Animates position upward (30 pixels) with ease-out
- Animates scale down to 70% with ease-out
- Animates opacity to 0 with ease-out
- Calls `queue_free()` when all animations complete

**Called by**: `_start_appearance()` callback

---

## Animation Properties

### Appearance Animation (0.1s)

- **Property**: `scale`
- **From**: `Vector2.ZERO`
- **To**: `Vector2.ONE`
- **Duration**: 0.1 seconds
- **Transition**: `Tween.TRANS_CUBIC`
- **Ease**: `Tween.EASE_OUT`

### Main Animations (1.5s, parallel)

#### Position Animation

- **Property**: `position` (relative to parent)
- **From**: `start_position` (spawn position)
- **To**: `start_position + Vector2(0, -30)` (30 pixels up)
- **Duration**: 1.5 seconds
- **Transition**: `Tween.TRANS_CUBIC`
- **Ease**: `Tween.EASE_OUT`

#### Scale Animation

- **Property**: `scale`
- **From**: `Vector2.ONE` (100%)
- **To**: `Vector2(0.7, 0.7)` (70%)
- **Duration**: 1.5 seconds
- **Transition**: `Tween.TRANS_CUBIC`
- **Ease**: `Tween.EASE_OUT`

#### Opacity Animation

- **Property**: `modulate.a` (alpha channel)
- **From**: `1.0` (fully visible)
- **To**: `0.0` (fully transparent)
- **Duration**: 1.5 seconds
- **Transition**: `Tween.TRANS_CUBIC`
- **Ease**: `Tween.EASE_OUT`

---

## Integration Points

### Mob.gd Integration

**Current Usage**:
```gdscript
func take_damage(damage: float) -> void:
    # ... damage logic ...
    
    if damage_popup_scene != null:
        var popup = damage_popup_scene.instantiate()
        get_tree().current_scene.add_child(popup)
        popup.global_position = global_position
        popup.set_damage(damage)
```

**No Changes Required**: Existing integration remains compatible. Enhancement is internal to DamagePopup.

---

## Error Handling

### Invalid States

- **Popup not in scene tree**: Animation still works, but position relative to parent
- **Tween creation fails**: No animation, popup remains visible (fallback behavior)
- **Label node missing**: No text displayed, but animation still plays

### Recovery

- All errors are non-fatal
- Popup will still cleanup via `queue_free()` even if animation fails
- No error propagation to calling code

---

## Performance Guarantees

- **Memory**: O(1) per popup instance
- **CPU**: O(1) per frame per popup (Tween calculations)
- **Rendering**: 1 draw call per popup (Label rendering)
- **Cleanup**: Automatic via `queue_free()` when animation completes

---

## Testing Considerations

### Unit Tests

- `set_damage()` sets correct damage value
- Appearance animation completes in 0.1s
- Main animations complete in 1.5s
- All animations use correct easing

### Integration Tests

- Popup appears at correct position
- Popup moves upward 30 pixels
- Popup scales down to 70%
- Popup fades out completely
- Popup auto-removes when done

### Performance Tests

- 10 simultaneous popups: No frame drops
- 20 simultaneous popups: Acceptable performance
- 50 simultaneous popups: May need optimization (out of scope)








































