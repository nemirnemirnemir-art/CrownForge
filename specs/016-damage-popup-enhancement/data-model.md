# Data Model: Damage Popup Enhancement

**Phase**: 1 - Design  
**Date**: 2025-01-XX  
**Status**: ✅ Complete

## Core Entities

### DamagePopup

Visual popup entity that displays damage numbers with animations.

**Properties**:
- `damage_value: float` - Damage amount to display
- `start_position: Vector2` - Initial spawn position (mob position)
- `target_position: Vector2` - Final position after upward movement (start_position + Vector2(0, -30))
- `start_scale: Vector2` - Initial scale (Vector2.ONE after appearance)
- `target_scale: Vector2` - Final scale (Vector2(0.7, 0.7))
- `start_opacity: float` - Initial opacity (1.0)
- `target_opacity: float` - Final opacity (0.0)

**State**:
- `SPAWNING` - Initial state, scale = 0
- `APPEARING` - Quick appearance animation (0.1s)
- `ANIMATING` - Main animation phase (1.5s, parallel animations)
- `FINISHED` - Animation complete, ready for cleanup

**Lifecycle**:
1. **Spawn**: Created by `Mob.gd` when damage is taken
   - Position set to mob's global_position
   - Scale = Vector2.ZERO
   - Opacity = 1.0
   - Damage value set via `set_damage()`
2. **Appearance**: Quick scale-in animation (0.1s)
   - Scale: Vector2.ZERO → Vector2.ONE
3. **Main Animation**: Parallel animations (1.5s)
   - Position: start_position → target_position (30px up)
   - Scale: Vector2.ONE → Vector2(0.7, 0.7)
   - Opacity: 1.0 → 0.0
4. **Cleanup**: Auto-removed via `queue_free()` when animation finishes

**Relationships**:
- Created by `Mob.gd` when `take_damage()` is called
- Added to scene tree as child of current scene
- No dependencies on other systems
- Self-contained animation logic

**Validation**:
- `damage_value >= 0` (negative damage not allowed)
- `target_position.y < start_position.y` (must move upward)
- `target_scale.x > 0 && target_scale.y > 0` (scale must remain positive)
- `target_opacity >= 0 && target_opacity <= 1` (opacity in valid range)

---

## Animation Constants

### Timing Constants

- `APPEARANCE_DURATION: float = 0.1` - Quick appearance duration (seconds)
- `MAIN_ANIMATION_DURATION: float = 1.5` - Main animation duration (seconds)
- `TOTAL_DURATION: float = 1.6` - Total animation duration (appearance + main)

### Movement Constants

- `UPWARD_DISTANCE: float = 30.0` - Pixels to move upward
- `UPWARD_DIRECTION: Vector2 = Vector2(0, -1)` - Upward direction vector

### Scale Constants

- `START_SCALE: Vector2 = Vector2.ZERO` - Initial scale (before appearance)
- `APPEARED_SCALE: Vector2 = Vector2.ONE` - Scale after appearance
- `END_SCALE: Vector2 = Vector2(0.7, 0.7)` - Final scale (70% of original)

### Opacity Constants

- `START_OPACITY: float = 1.0` - Initial opacity (fully visible)
- `END_OPACITY: float = 0.0` - Final opacity (fully transparent)

### Easing Constants

- `TRANSITION_TYPE: Tween.TransitionType = Tween.TRANS_CUBIC` - Smooth cubic transition
- `EASE_TYPE: Tween.EaseType = Tween.EASE_OUT` - Ease-out (deceleration at end)

---

## Data Flow

### Damage Popup Creation Flow

1. `Mob.take_damage(damage)` is called
2. Mob instantiates `DamagePopup` scene
3. Popup added to scene tree (current scene)
4. Popup position set to mob's `global_position`
5. `popup.set_damage(damage)` called
6. Popup starts appearance animation
7. After appearance, main animations start in parallel
8. When animations finish, popup calls `queue_free()`

### Animation Flow

1. **Appearance Phase**:
   - Tween created for scale animation
   - Scale: Vector2.ZERO → Vector2.ONE (0.1s)
   - Callback triggers main animation start

2. **Main Animation Phase**:
   - New Tween created with parallel mode
   - Position tween: start → target (1.5s, ease-out)
   - Scale tween: Vector2.ONE → Vector2(0.7, 0.7) (1.5s, ease-out)
   - Opacity tween: 1.0 → 0.0 (1.5s, ease-out)
   - All animations run simultaneously
   - Callback triggers cleanup when all finish

---

## Edge Cases Handled

1. **Multiple simultaneous popups**: Each popup manages its own Tween, no conflicts
2. **Popup created before scene ready**: Use `call_deferred()` or check `is_inside_tree()`
3. **Animation interrupted**: Tween automatically cleans up, `queue_free()` safe to call multiple times
4. **Zero or negative damage**: Display as "0", animation still plays
5. **Very large damage values**: Label text formatting handles large numbers
6. **Scene tree removal during animation**: Tween stops, no errors

---

## Performance Considerations

- **Memory**: Each popup = 1 Node2D + 1 Label + 1 Tween = minimal overhead
- **CPU**: Tween calculations are lightweight, multiple instances handled efficiently
- **Rendering**: Single Label per popup = 1 draw call per popup
- **Typical usage**: 1-5 popups visible = well within performance limits
- **Optimization**: No pooling needed unless profiling shows issues with 20+ simultaneous popups








































