# Data Model: Weapon Size Unification

**Date**: 2025-01-27  
**Feature**: Weapon Size Unification

## Entities

### WeaponConfig (Extended)

**Location**: `gameplay/weapons/WeaponConfig.gd`

**New Fields**:
```gdscript
@export var size_level: int = 0  # Level of size upgrade (0 = base, 1 = +5%, 2 = +10%, etc.)
```

**Existing Fields** (unchanged):
- `id: StringName`
- `display_name: String`
- `min_damage: int`
- `max_damage: int`
- `cooldown: float`
- `projectile_scene: PackedScene`
- ... (all other existing fields)

**Relationships**:
- One `WeaponConfig` → One or more `Projectile` instances
- `size_level` is read from config and passed to projectile during setup

**Validation Rules**:
- `size_level >= 0` (no negative levels)
- Default value is 0 (base size)

---

### Projectile (Extended)

**Location**: `gameplay/weapons/Projectile.gd` (base class)

**New Fields**:
```gdscript
var _base_visual_scale: Vector2 = Vector2.ONE  # Base scale for visual nodes
var _base_collider_scale: Vector2 = Vector2.ONE  # Base scale for collider nodes (if using node scale)
var _base_collider_size: Variant = null  # Base size for collider shapes (Vector2 for Rect, float for radius/height)
var _size_level: int = 0  # Current size level (from config)
var _other_size_modifiers: float = 1.0  # Multiplier from hero passives, perks, etc.
```

**Existing Fields** (modified):
- `_size_scale: float = 1.0` - **DEPRECATED** - Replace with new system
- `size_scale: float = 1.0` parameter in `setup()` - **MODIFIED** - Now represents `scale_factor`

**Methods** (new):
```gdscript
func _store_base_values() -> void
  # Store base scale/size values from visual and collision nodes
  # Called once in _ready() or setup()

func _apply_size_scale(scale_factor: float) -> void
  # Apply scale_factor to all visual and collision nodes
  # Uses stored base values, never accumulates
```

**Relationships**:
- One `Projectile` → Multiple visual nodes (Sprite2D, AnimatedSprite2D)
- One `Projectile` → Multiple collision nodes (Area2D, CollisionShape2D, CollisionPolygon2D)
- Each weapon may have different node structure (documented in inventory)

**Validation Rules**:
- Base values must be stored before applying any modifiers
- `scale_factor` must be calculated from base, never accumulated
- Formula: `scale_factor = (1.0 + size_level * 0.05) * other_modifiers`

---

### Weapon Size Calculation

**Constants**:
```gdscript
const SIZE_STEP: float = 0.05  # +5% per level
```

**Calculation Flow**:
1. Read `size_level` from `WeaponConfig` (`.tres` file)
2. Calculate `base_scale_factor = 1.0 + size_level * SIZE_STEP`
3. Get `other_modifiers` from hero passives/perks (if any)
4. Calculate `scale_factor = base_scale_factor * other_modifiers`
5. Apply to visual nodes: `visual_node.scale = base_visual_scale * scale_factor`
6. Apply to collision:
   - If using node scale: `collider_node.scale = base_collider_scale * scale_factor`
   - If using shape size: `shape.size = base_shape_size * scale_factor` (or `radius`, `height`)

**State Transitions**:
- **Initialization**: Store base values → Apply scale_factor
- **Size Upgrade**: Recalculate scale_factor from base → Reapply
- **Respawn**: Restore base values → Apply scale_factor (no accumulation)

---

## Data Flow

```
WeaponConfig (.tres)
  └─> size_level: int
       │
       v
Projectile.setup(cfg, ..., size_scale, ...)
  └─> Read size_level from cfg
       │
       v
_store_base_values()
  └─> Store visual/collision base values
       │
       v
Calculate scale_factor
  └─> base_scale_factor = 1.0 + size_level * 0.05
  └─> scale_factor = base_scale_factor * other_modifiers
       │
       v
_apply_size_scale(scale_factor)
  └─> Apply to all visual nodes
  └─> Apply to all collision nodes
```

---

## Constraints

1. **No Accumulation**: Always calculate from base values, never use `*=`
2. **Base First**: Always restore base values before applying modifiers
3. **Synchronization**: Visual and collision must use same `scale_factor`
4. **Individual Mapping**: Each weapon may have different node structure (documented in inventory)

---

## Migration Notes

**From Old System**:
- Remove `_size_scale` accumulation patterns
- Replace `scale *= factor` with `scale = base_scale * scale_factor`
- Store base values on first access (in `_ready()` or `setup()`)

**Backward Compatibility**:
- Default `size_level = 0` maintains current behavior (base size)
- Existing weapons without `size_level` field will use default 0

