# Quickstart: Weapon Size Unification

**Date**: 2025-01-27  
**Feature**: Weapon Size Unification

## Overview

This guide provides step-by-step instructions for implementing unified size behavior across all 20 weapons. The implementation follows a sequential task order to minimize conflicts and ensure correctness.

## Prerequisites

- Godot 4.3 project open
- Access to `gameplay/weapons/` directory
- Understanding of weapon structure (configs, scenes, scripts)

## Implementation Steps

### Step 1: Inventory (Task 1)

**Goal**: Document current state of all 20 weapons.

**Actions**:
1. Scan `gameplay/weapons/` for all `.tres` files (WeaponConfig resources)
2. For each weapon:
   - Open `.tscn` file (projectile scene)
   - Identify visual nodes (Sprite2D, AnimatedSprite2D)
   - Identify collision nodes (Area2D, CollisionShape2D, CollisionPolygon2D)
   - Open `.gd` file (projectile script)
   - Document current scale logic (search for `scale`, `size`, `radius`)
3. Create inventory table:
   ```
   weapon_name | visual_nodes | collider_nodes | current_scale_logic
   ```

**Output**: Inventory document with all 20 weapons documented.

**Time Estimate**: 2-3 hours

---

### Step 2: Fix Accumulation Bugs (Task 3)

**Goal**: Remove all `scale *=` patterns and restore base value logic.

**Actions**:
1. Search for accumulation patterns:
   ```gdscript
   # Search for:
   scale *=
   size *=
   radius *=
   ```
2. For each occurrence:
   - Identify base value source (editor value, initial value)
   - Store base value in `_base_*` variable
   - Replace `scale *= factor` with `scale = base_scale * factor`
3. Ensure base values are restored in `_ready()` or `setup()`

**Example Fix**:
```gdscript
# BEFORE (bug):
func apply_size_upgrade():
    sprite.scale *= 1.05

# AFTER (fixed):
var _base_sprite_scale: Vector2 = Vector2.ONE

func _ready():
    _base_sprite_scale = sprite.scale  # Store base

func apply_size_upgrade():
    var scale_factor = 1.0 + size_level * 0.05
    sprite.scale = _base_sprite_scale * scale_factor
```

**Output**: All accumulation bugs fixed, base values stored.

**Time Estimate**: 3-4 hours

---

### Step 3: Implement Unified System (Task 2)

**Goal**: Apply unified size calculation to all weapons.

**Actions**:

#### 3.1: Extend WeaponConfig

Add to `gameplay/weapons/WeaponConfig.gd`:
```gdscript
@export var size_level: int = 0
```

#### 3.2: Extend Projectile Base Class

Add to `gameplay/weapons/Projectile.gd`:
```gdscript
var _base_visual_scale: Vector2 = Vector2.ONE
var _base_collider_scale: Vector2 = Vector2.ONE
var _base_collider_size: Variant = null
var _size_level: int = 0
var _other_size_modifiers: float = 1.0

func _store_base_values() -> void:
    # Store base values from visual and collision nodes
    # Implementation depends on weapon structure

func _apply_size_scale(scale_factor: float) -> void:
    # Apply scale_factor to all nodes
    # Implementation depends on weapon structure
```

#### 3.3: Update setup() Method

Modify `Projectile.setup()`:
```gdscript
func setup(cfg: WeaponConfig, dir: Vector2, from: Node, size_scale: float = 1.0, tome_mods: TomeMods = null) -> void:
    # ... existing setup code ...
    
    # Read size_level from config
    _size_level = cfg.size_level
    
    # Calculate scale_factor
    var base_scale_factor: float = 1.0 + _size_level * 0.05
    _other_size_modifiers = 1.0  # TODO: Get from hero passives/perks
    var scale_factor: float = base_scale_factor * _other_size_modifiers
    
    # Store base values (if not already stored)
    if _base_visual_scale == Vector2.ZERO:
        _store_base_values()
    
    # Apply scale
    _apply_size_scale(scale_factor)
```

#### 3.4: Implement Per-Weapon Logic

For each weapon (20 weapons):
1. Implement `_store_base_values()` for that weapon's node structure
2. Implement `_apply_size_scale()` for that weapon's node structure
3. Test in editor and runtime

**Output**: All weapons use unified size system.

**Time Estimate**: 8-10 hours (varies by weapon complexity)

---

### Step 4: Editor Synchronization (Task 4)

**Goal**: Ensure 2D editor view matches runtime behavior.

**Actions**:
1. For each weapon scene (`.tscn`):
   - Set visual node `scale` to base value (usually `Vector2(1, 1)`)
   - Set collision shape to match visual size
   - Verify in 2D editor view
2. Ensure `_ready()` doesn't override editor values:
   - Store base values from editor state
   - Only apply modifiers if `size_level > 0` or modifiers exist

**Output**: Editor view matches runtime at level 0.

**Time Estimate**: 2-3 hours

---

### Step 5: Testing (Task 5)

**Goal**: Verify unified behavior across all weapons.

**Test Cases**:

#### 5.1: Base Level (size_level = 0)
- [ ] Visual and collision match in editor
- [ ] Visual and collision match in runtime
- [ ] No size change on multiple spawns/restarts

#### 5.2: Size Upgrades (size_level 0 → 1 → 2 → ...)
- [ ] Visual and collision increase proportionally
- [ ] No "jumps" (sudden 2x size)
- [ ] At level 10, size ≈ 1.5x base (10 × 5%)

#### 5.3: Multiple Spawns
- [ ] 10 spawns with same `size_level` = same size
- [ ] No accumulation on respawn

#### 5.4: All 20 Weapons
- [ ] Each weapon uses unified formula
- [ ] Each weapon maintains visual/collision sync
- [ ] No "giant" or "microscopic" collisions

**Output**: Test results document, all tests passing.

**Time Estimate**: 4-5 hours

---

## Common Patterns

### Pattern 1: Simple Sprite + Circle Collision

```gdscript
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_circle_radius: float = 0.0

func _store_base_values() -> void:
    _base_sprite_scale = _sprite.scale
    var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
    if shape:
        _base_circle_radius = shape.radius

func _apply_size_scale(scale_factor: float) -> void:
    _sprite.scale = _base_sprite_scale * scale_factor
    var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
    if shape:
        shape.radius = _base_circle_radius * scale_factor
```

### Pattern 2: AnimatedSprite2D + Rectangle Collision

```gdscript
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_rect_size: Vector2 = Vector2.ZERO

func _store_base_values() -> void:
    _base_sprite_scale = _animated_sprite.scale
    var shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
    if shape:
        _base_rect_size = shape.size

func _apply_size_scale(scale_factor: float) -> void:
    _animated_sprite.scale = _base_sprite_scale * scale_factor
    var shape: RectangleShape2D = _collision_shape.shape as RectangleShape2D
    if shape:
        shape.size = _base_rect_size * scale_factor
```

### Pattern 3: Multiple Visual Nodes

```gdscript
@onready var _sprite1: Sprite2D = $Sprite1
@onready var _sprite2: Sprite2D = $Sprite2
@onready var _collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var _base_sprite1_scale: Vector2 = Vector2.ONE
var _base_sprite2_scale: Vector2 = Vector2.ONE
var _base_circle_radius: float = 0.0

func _store_base_values() -> void:
    _base_sprite1_scale = _sprite1.scale
    _base_sprite2_scale = _sprite2.scale
    var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
    if shape:
        _base_circle_radius = shape.radius

func _apply_size_scale(scale_factor: float) -> void:
    _sprite1.scale = _base_sprite1_scale * scale_factor
    _sprite2.scale = _base_sprite2_scale * scale_factor
    var shape: CircleShape2D = _collision_shape.shape as CircleShape2D
    if shape:
        shape.radius = _base_circle_radius * scale_factor
```

---

## Troubleshooting

### Issue: Size accumulates on respawn

**Cause**: Base values not restored before applying scale.

**Fix**: Ensure `_store_base_values()` is called before `_apply_size_scale()` in `setup()`.

### Issue: Visual and collision don't match

**Cause**: Different scale factors applied or base values stored incorrectly.

**Fix**: Verify both use same `scale_factor` and base values are from same "level 0" state.

### Issue: Editor view doesn't match runtime

**Cause**: `_ready()` overrides editor values or base values stored incorrectly.

**Fix**: Store base values from editor state, only apply modifiers if needed.

### Issue: Size doesn't change with size_level

**Cause**: `size_level` not read from config or `scale_factor` not calculated.

**Fix**: Verify `cfg.size_level` is read in `setup()` and `scale_factor` calculation is correct.

---

## Validation Checklist

Before considering implementation complete:

- [ ] All 20 weapons documented in inventory
- [ ] All accumulation bugs fixed (`scale *=` removed)
- [ ] All weapons use unified formula (`1.0 + size_level * 0.05`)
- [ ] Base values stored for all weapons
- [ ] Visual and collision synchronized for all weapons
- [ ] Editor view matches runtime at level 0
- [ ] Size upgrades work correctly (0 → 1 → 2 → ...)
- [ ] No accumulation on respawn (test 10 spawns)
- [ ] All tests passing
- [ ] `godot --headless --check-only` returns 0 (no errors)
- [ ] No `inferred_variant` warnings

---

## Next Steps

After completing implementation:

1. Run full test suite (Task 5)
2. Update `docs/BUGS_PATTERNS.md` if new patterns discovered
3. Document any weapon-specific quirks in weapon documentation
4. Create PR with implementation

---

## References

- [Specification](./spec.md)
- [Data Model](./data-model.md)
- [API Contract](./contracts/weapon-size-api.md)
- [Research](./research.md)

