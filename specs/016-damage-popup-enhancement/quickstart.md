# Quickstart: Damage Popup Enhancement

**Phase**: 1 - Design  
**Date**: 2025-01-XX  
**Status**: ✅ Complete

## Overview

This guide provides step-by-step instructions for implementing the damage popup enhancement feature. The enhancement adds smooth animations to damage popups that appear when mobs take damage.

## Prerequisites

- Godot 4.3 project (clickcer)
- Existing `DamagePopup.tscn` scene
- Existing `DamagePopup.gd` script (currently minimal)
- Existing `Mob.gd` that instantiates popups

## Implementation Steps

### Step 1: Enhance DamagePopup.gd Script

**File**: `scripts/DamagePopup.gd`

**Current State**: Minimal script with empty `_ready()` function

**Changes Required**:

1. Add property references:
   ```gdscript
   @onready var label: Label = $Label
   ```

2. Add animation constants:
   ```gdscript
   const APPEARANCE_DURATION: float = 0.1
   const MAIN_ANIMATION_DURATION: float = 1.5
   const UPWARD_DISTANCE: float = 30.0
   const END_SCALE: Vector2 = Vector2(0.7, 0.7)
   ```

3. Add state variables:
   ```gdscript
   var damage_value: float = 0.0
   var start_position: Vector2
   var target_position: Vector2
   ```

4. Implement `set_damage()` method:
   - Set damage value
   - Update label text
   - Initialize animation state
   - Start appearance animation

5. Implement `_start_appearance()` method:
   - Create Tween for quick scale-in
   - Animate scale from 0 to 1
   - Callback to start main animations

6. Implement `_start_main_animations()` method:
   - Create parallel Tween
   - Animate position (upward)
   - Animate scale (down to 70%)
   - Animate opacity (fade out)
   - Callback to cleanup

**See**: `research.md` for detailed implementation pattern

---

### Step 2: Verify Scene Structure

**File**: `scenes/DamagePopup.tscn`

**Required Structure**:
- Root: `Node2D` (named "DamagePopup")
- Child: `Label` (named "Label")
  - Text: "0"
  - Font size: 32
  - Font color: Red
  - Outline: Black, size 3

**Verification**:
- Ensure Label node exists
- Ensure Label is child of Node2D root
- No changes needed to scene file

---

### Step 3: Test Integration

**File**: `scripts/Mob.gd`

**Current Integration** (no changes needed):
```gdscript
func take_damage(damage: float) -> void:
    # ... existing code ...
    
    if damage_popup_scene != null:
        var popup = damage_popup_scene.instantiate()
        get_tree().current_scene.add_child(popup)
        popup.global_position = global_position
        popup.set_damage(damage)
```

**Testing Steps**:
1. Run game
2. Click on a mob or let hero attack
3. Verify popup appears quickly (0.1s scale-in)
4. Verify popup floats upward 30 pixels
5. Verify popup scales down to 70%
6. Verify popup fades out
7. Verify popup auto-removes when done

---

## Code Template

### Complete DamagePopup.gd Implementation

```gdscript
extends Node2D

## Popup showing damage numbers with smooth animations

@onready var label: Label = $Label

# Animation constants
const APPEARANCE_DURATION: float = 0.1
const MAIN_ANIMATION_DURATION: float = 1.5
const UPWARD_DISTANCE: float = 30.0
const END_SCALE: Vector2 = Vector2(0.7, 0.7)

# State
var damage_value: float = 0.0
var start_position: Vector2
var target_position: Vector2

func _ready() -> void:
    # Initial state
    scale = Vector2.ZERO
    modulate.a = 1.0

func set_damage(damage: float) -> void:
    damage_value = max(0.0, damage)  # Clamp to non-negative
    
    if label:
        label.text = str(int(damage_value))
    
    # Set initial state
    scale = Vector2.ZERO
    modulate.a = 1.0
    start_position = global_position
    target_position = start_position + Vector2(0, -UPWARD_DISTANCE)
    
    # Start animations
    _start_appearance()

func _start_appearance() -> void:
    var tween: Tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, APPEARANCE_DURATION)
    tween.tween_callback(_start_main_animations)

func _start_main_animations() -> void:
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    
    # Upward movement
    tween.tween_property(self, "position", target_position - start_position, MAIN_ANIMATION_DURATION)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    
    # Scale down
    tween.tween_property(self, "scale", END_SCALE, MAIN_ANIMATION_DURATION)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    
    # Fade out
    tween.tween_property(self, "modulate:a", 0.0, MAIN_ANIMATION_DURATION)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    
    # Cleanup
    tween.tween_callback(queue_free)
```

**Note**: Position animation uses relative position (`target_position - start_position`) because `position` is relative to parent, while `global_position` is absolute.

---

## Verification Checklist

- [ ] Popup appears quickly (0.1s scale-in)
- [ ] Popup floats upward 30 pixels
- [ ] Popup scales down to 70% of original size
- [ ] Popup fades out completely
- [ ] All animations use ease-out easing
- [ ] Popup auto-removes when animation completes
- [ ] Multiple simultaneous popups work correctly
- [ ] No performance issues with 5+ popups
- [ ] Integration with `Mob.gd` unchanged
- [ ] No breaking changes to existing code

---

## Troubleshooting

### Popup doesn't appear
- Check that `set_damage()` is called
- Verify Label node exists in scene
- Check that popup is added to scene tree

### Animation doesn't start
- Verify Tween creation succeeds
- Check that popup is in scene tree before animating
- Ensure `global_position` is set before `set_damage()`

### Position animation wrong
- Remember: `position` is relative to parent, `global_position` is absolute
- Use relative offset for position animation: `target_position - start_position`

### Popup doesn't cleanup
- Verify `queue_free()` is called in Tween callback
- Check that Tween completes successfully

---

## Next Steps

After implementation:
1. Test with various damage values
2. Test with multiple simultaneous popups
3. Verify performance with 10+ popups
4. Consider object pooling if needed (out of scope for MVP)

---

## References

- **Specification**: `spec.md`
- **Research**: `research.md`
- **Data Model**: `data-model.md`
- **API Contract**: `contracts/damage-popup-api.md`








































