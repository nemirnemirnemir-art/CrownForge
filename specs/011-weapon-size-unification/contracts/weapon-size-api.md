# Weapon Size API Contract

**Version**: 1.0  
**Date**: 2025-01-27  
**Feature**: Weapon Size Unification

## Overview

This contract defines the API for applying size scaling to weapons and projectiles. The API ensures that size is calculated from base values without accumulation, maintaining synchronization between visual and collision nodes.

## Core API

### WeaponConfig Extension

**Class**: `WeaponConfig`  
**Location**: `gameplay/weapons/WeaponConfig.gd`

#### New Property

```gdscript
@export var size_level: int = 0
```

**Description**: Size upgrade level (0 = base, 1 = +5%, 2 = +10%, etc.)

**Constraints**:
- `size_level >= 0`
- Default: `0` (base size)

**Access**: Read during `Projectile.setup()` from config resource

---

### Projectile Extension

**Class**: `Projectile`  
**Location**: `gameplay/weapons/Projectile.gd`

#### New Methods

##### `_store_base_values() -> void`

**Purpose**: Store base scale/size values from visual and collision nodes.

**When to Call**:
- Once in `_ready()` (for nodes present at initialization)
- Once in `setup()` (for nodes that may be created dynamically)

**Behavior**:
- Stores `scale` of all visual nodes (Sprite2D, AnimatedSprite2D) as `_base_visual_scale`
- Stores `scale` of collider nodes (if using node scale) as `_base_collider_scale`
- Stores `size`/`radius`/`height` of collision shapes (if using shape properties) as `_base_collider_size`

**Preconditions**:
- Visual and collision nodes must exist and be accessible
- Nodes should be in their default/editor state (no runtime modifications)

**Postconditions**:
- All base values stored in instance variables
- Base values represent the "level 0" state

**Example**:
```gdscript
func _store_base_values() -> void:
    if _sprite:
        _base_visual_scale = _sprite.scale
    if _collision_shape:
        var shape: Shape2D = _collision_shape.shape
        if shape is CircleShape2D:
            _base_collider_size = shape.radius
        elif shape is RectangleShape2D:
            _base_collider_size = shape.size
```

---

##### `_apply_size_scale(scale_factor: float) -> void`

**Purpose**: Apply calculated scale factor to all visual and collision nodes.

**Parameters**:
- `scale_factor: float` - Calculated scale factor (1.0 = base, 1.05 = +5%, etc.)

**Behavior**:
- Applies to all visual nodes: `visual_node.scale = base_visual_scale * scale_factor`
- Applies to collision:
  - If using node scale: `collider_node.scale = base_collider_scale * scale_factor`
  - If using shape properties: `shape.size = base_shape_size * scale_factor` (or `radius`, `height`)

**Preconditions**:
- `_store_base_values()` must have been called
- `scale_factor > 0.0`

**Postconditions**:
- All visual nodes scaled proportionally
- All collision nodes/shapes scaled proportionally
- Visual and collision remain synchronized

**Example**:
```gdscript
func _apply_size_scale(scale_factor: float) -> void:
    if _sprite:
        _sprite.scale = _base_visual_scale * scale_factor
    if _collision_shape:
        var shape: Shape2D = _collision_shape.shape
        if shape is CircleShape2D:
            shape.radius = _base_collider_size * scale_factor
        elif shape is RectangleShape2D:
            shape.size = _base_collider_size * scale_factor
```

---

#### Modified Methods

##### `setup(cfg: WeaponConfig, dir: Vector2, from: Node, size_scale: float = 1.0, tome_mods: TomeMods = null) -> void`

**Changes**:
- Read `size_level` from `cfg.size_level` (new field)
- Calculate `scale_factor` from `size_level` and `other_modifiers`
- Call `_store_base_values()` if not already stored
- Call `_apply_size_scale(scale_factor)` instead of old accumulation logic

**New Logic**:
```gdscript
# Read size_level from config
_size_level = cfg.size_level

# Calculate scale_factor
var base_scale_factor: float = 1.0 + _size_level * 0.05
_other_size_modifiers = 1.0  # TODO: Get from hero passives/perks if needed
var scale_factor: float = base_scale_factor * _other_size_modifiers

# Store base values (if not already stored)
if _base_visual_scale == Vector2.ZERO:  # Check if not initialized
    _store_base_values()

# Apply scale
_apply_size_scale(scale_factor)
```

**Deprecated**:
- Old `size_scale` parameter accumulation logic
- `_size_scale *= factor` patterns

---

## Size Calculation Formula

**Formula**:
```
base_scale_factor = 1.0 + size_level * SIZE_STEP
scale_factor = base_scale_factor * other_modifiers
```

**Constants**:
- `SIZE_STEP = 0.05` (+5% per level)

**Examples**:
- `size_level = 0`: `base_scale_factor = 1.0` (100% = base)
- `size_level = 1`: `base_scale_factor = 1.05` (105% = +5%)
- `size_level = 10`: `base_scale_factor = 1.5` (150% = +50%)

---

## Integration Points

### With Tome System

**Current**: Tome modifiers may affect size through `other_modifiers`.

**Future**: If tomes add size bonuses, they should modify `_other_size_modifiers` multiplier, not `size_level`.

**Example**:
```gdscript
# In Projectile.setup() or tome application
if tome_mods.has_size_mult:
    _other_size_modifiers = tome_mods.size_mult
else:
    _other_size_modifiers = 1.0
```

### With Hero Passives

**Current**: Hero passives may affect size through `other_modifiers`.

**Future**: Similar to tomes, passives should modify `_other_size_modifiers`, not `size_level`.

---

## Error Handling

### Invalid size_level

**Condition**: `size_level < 0`

**Behavior**: Clamp to 0, log warning if `debug_logs` enabled

```gdscript
if size_level < 0:
    if debug_logs:
        print("[Projectile] Invalid size_level %d, clamping to 0" % size_level)
    size_level = 0
```

### Base Values Not Stored

**Condition**: `_apply_size_scale()` called before `_store_base_values()`

**Behavior**: Call `_store_base_values()` automatically, log warning if `debug_logs` enabled

```gdscript
func _apply_size_scale(scale_factor: float) -> void:
    if _base_visual_scale == Vector2.ZERO:
        if debug_logs:
            print("[Projectile] Base values not stored, storing now")
        _store_base_values()
    # ... apply scale
```

### Zero or Negative scale_factor

**Condition**: `scale_factor <= 0.0`

**Behavior**: Clamp to 0.01 (minimum 1%), log error if `debug_logs` enabled

```gdscript
if scale_factor <= 0.0:
    if debug_logs:
        print("[Projectile] Invalid scale_factor %f, clamping to 0.01" % scale_factor)
    scale_factor = 0.01
```

---

## Testing Requirements

### Unit Tests

1. **Base Value Storage**: Verify `_store_base_values()` captures correct base values
2. **Scale Calculation**: Verify `scale_factor` calculation for various `size_level` values
3. **Scale Application**: Verify visual and collision nodes scale proportionally
4. **No Accumulation**: Verify multiple calls to `_apply_size_scale()` don't accumulate

### Integration Tests

1. **Weapon Spawn**: Verify size applied correctly on weapon spawn
2. **Size Upgrade**: Verify size increases correctly when `size_level` increases
3. **Respawn**: Verify size doesn't accumulate on respawn
4. **Multiple Weapons**: Verify all 20 weapons use unified system

---

## Migration Guide

### For Existing Weapons

1. Add `size_level: int = 0` to `WeaponConfig.gd`
2. Add base value storage fields to `Projectile.gd` subclasses
3. Replace `scale *= factor` with `scale = base_scale * scale_factor`
4. Call `_store_base_values()` in `_ready()` or `setup()`
5. Call `_apply_size_scale(scale_factor)` instead of accumulation

### Breaking Changes

- `_size_scale` variable is deprecated (remove after migration)
- Old `size_scale *=` patterns must be replaced
- Base values must be stored before applying scale

---

## Version History

- **1.0** (2025-01-27): Initial contract for weapon size unification

