# Implementation Plan: Damage Popup Enhancement

**Branch**: `016-damage-popup-enhancement` | **Date**: 2025-01-XX | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-damage-popup-enhancement/spec.md`

## Summary

Enhance damage popup visual feedback with smooth animations. Currently, damage popups appear when mobs are hit but have no animations. This feature adds:
- Quick appearance animation (0.1s scale/fade in)
- Upward floating movement (30 pixels over 1.5s)
- Scale down animation (100% → 70% over 1.5s)
- Fade out animation (100% → 0% over 1.5s)
- All animations run in parallel with ease-out easing

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: Godot Engine 4.3, Tween system for animations  
**Storage**: No persistence needed (ephemeral visual effect)  
**Testing**: Manual gameplay testing, visual verification  
**Target Platform**: Godot 4.3 (Windows/Linux/Mac, 2D game)  
**Project Type**: Enhancement to existing game (clickcer)  
**Performance Goals**: Smooth 60 FPS, no frame drops during popup animations  
**Constraints**: Must work with existing `Mob.gd` damage system, no breaking changes  
**Scale/Scope**: 1 scene enhancement, 1 script enhancement, animation system

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Compliance Review

✅ **Documentation Hierarchy**: Spec structure follows project pattern (`specs/016-damage-popup-enhancement/`)

✅ **Godot 4.3 Strict Typing**: All GDScript code will use strict typing (`var tween: Tween`, `var duration: float`)

✅ **Code Style & Formatting**: Code will follow Godot 4.3 GDScript style guide (4-space indentation, snake_case)

✅ **Debug Logging System**: Debug prints will use consistent format `[DamagePopup] message` for key events

✅ **Modularity**: Enhancement isolated to `DamagePopup.gd` script, no changes to core systems required

✅ **Project Validation**: Code structure validated against Godot 4.3 best practices and architecture manifest

**Result**: ✅ **PASS** - All constitution principles satisfied. Enhancement follows established patterns.

## Project Structure

### Scenes (this feature)

```text
res://
└── scenes/
    └── DamagePopup.tscn         # Enhanced with animation support (existing)
```

### Scripts (this feature)

```text
res://
└── scripts/
    └── DamagePopup.gd           # Enhanced with Tween-based animations (existing)
```

**Structure Decision**: Minimal changes - only enhance existing `DamagePopup.gd` script. No new files needed. Animation logic self-contained in popup script.

## Complexity Tracking

> **No violations detected** - Simple visual enhancement with isolated animation logic. No dependencies on other systems beyond existing damage popup instantiation.

---

## Phase 0: Research

**Status**: ✅ Complete

### Research Tasks

1. **Godot 4.3 Tween System for Parallel Animations**
   - **Question**: How to create parallel animations (position, scale, opacity) using Tween in Godot 4.3?
   - **Research**: Godot 4.3 Tween API, parallel property animations, ease-out transitions
   - **Output**: Decision on Tween usage pattern

2. **Animation Timing and Easing**
   - **Question**: How to implement ease-out easing for smooth deceleration?
   - **Research**: Godot 4.3 Tween transition types, ease-out curves
   - **Output**: Easing function selection

3. **Performance Considerations for Multiple Popups**
   - **Question**: Will multiple simultaneous popups cause performance issues?
   - **Research**: Godot 4.3 performance with multiple Tween instances, optimization patterns
   - **Output**: Performance guidelines

**Output**: `research.md` with all research findings

---

## Phase 1: Design & Contracts

**Status**: ✅ Complete

### Data Model

**Output**: `data-model.md`

**Entities:**
- `DamagePopup` - Visual popup entity with animation state
  - Properties: `damage_value: float`, `start_position: Vector2`, `target_position: Vector2`, `start_scale: Vector2`, `target_scale: Vector2`, `start_opacity: float`, `target_opacity: float`
  - State: `ANIMATING`, `FINISHED`
  - Lifecycle: Spawn → Animate → Auto-cleanup

### API Contracts

**Output**: `contracts/damage-popup-api.md`

**DamagePopup API:**
- `set_damage(damage: float) -> void` - Set damage value and start animation
- `_start_animations() -> void` - Internal: Start all parallel animations
- `_on_animation_finished() -> void` - Internal: Cleanup when done

### Quickstart

**Output**: `quickstart.md`

**Implementation Steps:**
1. Enhance `DamagePopup.gd` with Tween system
2. Implement parallel animations (position, scale, opacity)
3. Configure ease-out easing
4. Test with existing `Mob.gd` damage system

---

## Phase 2: Implementation Planning

**Status**: ✅ Complete

### Implementation Summary

**Ready for Implementation**: All design artifacts complete. Implementation can proceed using:
- `research.md` - Animation patterns and Tween usage
- `data-model.md` - Entity structure and lifecycle
- `contracts/damage-popup-api.md` - API specification
- `quickstart.md` - Step-by-step implementation guide

**Next Steps**: 
1. Implement `DamagePopup.gd` following `quickstart.md`
2. Test with existing `Mob.gd` integration
3. Verify all animations work as specified
4. Performance testing with multiple popups

---

## Risks & Mitigations

**Risk 1**: Performance impact with many simultaneous popups
- **Mitigation**: Use efficient Tween system, consider object pooling if needed

**Risk 2**: Animation timing conflicts
- **Mitigation**: Use parallel animations with same duration, test edge cases

**Risk 3**: Breaking existing popup instantiation
- **Mitigation**: Maintain backward compatibility with `set_damage()` method

---

## Success Criteria

✅ Popup appears quickly (0.1s appearance)  
✅ Popup floats upward 30 pixels over 1.5s  
✅ Popup scales down to 70% over 1.5s  
✅ Popup fades out over 1.5s  
✅ All animations run in parallel with ease-out easing  
✅ No performance degradation with multiple popups  
✅ No breaking changes to existing damage system

