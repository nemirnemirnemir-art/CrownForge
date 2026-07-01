# Implementation Tasks: Damage Popup Enhancement

**Feature**: 016-damage-popup-enhancement  
**Branch**: `016-damage-popup-enhancement`  
**Created**: 2025-01-XX  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Overview

This feature enhances damage popup visual feedback with smooth animations. Popups will appear quickly, float upward, scale down, and fade out with ease-out easing. All animations run in parallel for smooth visual feedback.

**Total Tasks**: 12  
**Scope**: Complete animation implementation for damage popups

---

## Dependencies

### Implementation Order

1. **Script Enhancement** (DamagePopup.gd) → **No dependencies** (self-contained)
2. **Scene Verification** (DamagePopup.tscn) → **No dependencies** (verification only)
3. **Integration Testing** (Mob.gd integration) → **Depends on**: Script Enhancement

### Parallel Execution Opportunities

- **Scene verification** can be done in parallel with script enhancement (different files)
- **Testing** can begin as soon as script is complete

---

## Phase 1: Script Enhancement - DamagePopup.gd

**Goal**: Enhance DamagePopup.gd script with animation system

**Independent Test**: Popup appears, animates correctly, and auto-removes when done

- [x] T001 Add `@onready var label: Label = $Label` reference to DamagePopup.gd
- [x] T002 Add animation constants to DamagePopup.gd:
  - `const APPEARANCE_DURATION: float = 0.1`
  - `const MAIN_ANIMATION_DURATION: float = 1.5`
  - `const UPWARD_DISTANCE: float = 30.0`
  - `const END_SCALE: Vector2 = Vector2(0.7, 0.7)`
- [x] T003 Add state variables to DamagePopup.gd:
  - `var damage_value: float = 0.0`
  - `var start_position: Vector2`
  - `var target_position: Vector2`
- [x] T004 Update `_ready()` in DamagePopup.gd to set initial state:
  - `scale = Vector2.ZERO`
  - `modulate.a = 1.0`
- [x] T005 Implement `set_damage(damage: float) -> void` in DamagePopup.gd:
  - Clamp damage to non-negative: `damage_value = max(0.0, damage)`
  - Update label text: `label.text = str(int(damage_value))`
  - Set initial state (scale = 0, opacity = 1)
  - Calculate start_position and target_position (30px up)
  - Call `_start_appearance()`
- [x] T006 Implement `_start_appearance() -> void` in DamagePopup.gd:
  - Create Tween: `var tween: Tween = create_tween()`
  - Animate scale from Vector2.ZERO to Vector2.ONE over APPEARANCE_DURATION
  - Set transition: `Tween.TRANS_CUBIC` with `Tween.EASE_OUT`
  - Add callback to `_start_main_animations()` when complete
- [x] T007 Implement `_start_main_animations() -> void` in DamagePopup.gd:
  - Create Tween with parallel mode: `tween.set_parallel(true)`
  - Animate position upward (relative offset: Vector2(0, -UPWARD_DISTANCE)) over MAIN_ANIMATION_DURATION
  - Animate scale from Vector2.ONE to END_SCALE over MAIN_ANIMATION_DURATION
  - Animate opacity (modulate.a) from 1.0 to 0.0 over MAIN_ANIMATION_DURATION
  - All animations use `Tween.TRANS_CUBIC` with `Tween.EASE_OUT`
  - Add callback to `queue_free()` when all animations complete

---

## Phase 2: Scene Verification - DamagePopup.tscn

**Goal**: Verify scene structure is correct for animations

**Independent Test**: Scene has required nodes and structure

- [x] T008 Verify DamagePopup.tscn root node is Node2D (named "DamagePopup")
- [x] T009 Verify DamagePopup.tscn has Label child node (named "Label")
- [x] T010 Verify Label node has correct properties:
  - Text: "0" (default)
  - Font size: 32
  - Font color: Red (Color(1, 0.2, 0.2, 1))
  - Outline: Black, size 3
  - Horizontal alignment: Center
  - Vertical alignment: Center

---

## Phase 3: Integration Testing

**Goal**: Test popup animations with existing Mob.gd integration

**Independent Test**: Popup appears and animates correctly when mob takes damage

- [ ] T011 Test popup appears when mob takes damage (click or hero attack):
  - Verify popup spawns at mob position
  - Verify popup displays correct damage value
  - Verify appearance animation (0.1s scale-in) works
  - Verify main animations (1.5s parallel) work:
    - Position moves upward 30 pixels
    - Scale reduces to 70%
    - Opacity fades to 0
  - Verify popup auto-removes when animation completes
- [ ] T012 Test multiple simultaneous popups:
  - Spawn 5+ popups simultaneously
  - Verify all animate independently
  - Verify no performance issues (60 FPS maintained)
  - Verify all popups cleanup correctly

---

## Testing Checklist

### Visual Verification

- [ ] Popup appears quickly (0.1s appearance animation)
- [ ] Popup floats upward exactly 30 pixels
- [ ] Popup scales down to 70% of original size
- [ ] Popup fades out completely (opacity 0)
- [ ] All animations use ease-out easing (smooth deceleration)
- [ ] Animation timing matches specification (0.1s + 1.5s = 1.6s total)

### Functional Verification

- [ ] Popup displays correct damage value
- [ ] Popup spawns at correct position (mob position)
- [ ] Popup auto-removes when animation completes
- [ ] Multiple popups work simultaneously
- [ ] No errors in console during animation
- [ ] No memory leaks (popups cleanup properly)

### Integration Verification

- [ ] Existing Mob.gd integration unchanged
- [ ] No breaking changes to damage system
- [ ] Popup works with both player clicks and hero attacks
- [ ] Performance acceptable with 10+ simultaneous popups

---

## Success Criteria

✅ All tasks completed  
✅ Popup appears quickly (0.1s appearance)  
✅ Popup floats upward 30 pixels over 1.5s  
✅ Popup scales down to 70% over 1.5s  
✅ Popup fades out over 1.5s  
✅ All animations run in parallel with ease-out easing  
✅ No performance degradation with multiple popups  
✅ No breaking changes to existing damage system

---

## Notes

- **Position Animation**: Remember that `position` is relative to parent, while `global_position` is absolute. Use relative offset for position animation: `target_position - start_position` or `Vector2(0, -UPWARD_DISTANCE)`
- **Tween Cleanup**: Tween automatically cleans up when node is removed, but explicit `queue_free()` in callback ensures proper cleanup
- **Performance**: Each popup creates one Tween instance. Typical usage (1-5 popups) is well within performance limits. No pooling needed unless profiling shows issues with 20+ simultaneous popups.

