# Research: Weapon Size Unification

**Date**: 2025-01-27  
**Feature**: Weapon Size Unification  
**Phase**: 0 (Outline & Research)

## Research Tasks

### 1. Weapon Identification Strategy

**Task**: Determine how to automatically find all 20 weapons in the project.

**Decision**: Automatic search by project structure (scanning weapon folders, finding `.tscn` files with characteristic nodes).

**Rationale**: 
- Reliable and scalable approach
- No manual maintenance required
- Can be scripted for validation

**Alternatives Considered**:
- Manual registry/list: Requires maintenance, error-prone
- Using existing weapon registry: May not exist or be incomplete

**Implementation Notes**:
- Scan `gameplay/weapons/` directory for `.tres` files (WeaponConfig resources)
- Match with corresponding `.tscn` files (projectile scenes)
- Identify visual nodes (Sprite2D, AnimatedSprite2D) and collision nodes (Area2D, CollisionShape2D) in each scene

---

### 2. Size Level Storage Location

**Task**: Determine where `size_level` is stored and how it's accessed.

**Decision**: `size_level` stored in weapon config (`.tres` file) and read during initialization.

**Rationale**:
- Aligns with project architecture (WeaponConfig resources)
- Allows level to be stored independently of instance
- Consistent with existing weapon property storage pattern

**Alternatives Considered**:
- External parameter during spawn: Requires passing through multiple layers
- Global registry by weapon ID: Adds complexity, not aligned with current architecture
- Dynamic calculation from tomes: Doesn't match requirement (size_level is separate from tome modifiers)

**Implementation Notes**:
- Add `@export var size_level: int = 0` to `WeaponConfig.gd`
- Read `size_level` from config in `Projectile.setup()` or weapon controller
- Default value is 0 (base size)

---

### 3. Multiple Visual/Collision Nodes Handling

**Task**: Determine how to handle weapons with multiple visual nodes or collision shapes.

**Decision**: Determine individually for each weapon during inventory phase (Task 1).

**Rationale**:
- Weapon structures may differ significantly
- Some weapons may have complex hierarchies
- Individual approach ensures correctness for each weapon

**Alternatives Considered**:
- Apply to all nodes uniformly: May not work for complex structures
- Apply only to "main" node: May miss important visual/collision elements

**Implementation Notes**:
- During Task 1 (inventory), document which nodes need scaling for each weapon
- Create mapping: `weapon_name -> [visual_nodes], [collider_nodes]`
- Apply scale_factor to all documented nodes during Task 2

---

### 4. Integration with Existing Size Modifiers

**Task**: Determine how to integrate with existing size modifiers (hero passives, perks).

**Decision**: `size_level` accounts only for tomes/upgrades; other modifiers applied as multiplier to `scale_factor`.

**Rationale**:
- Separates concerns (size_level vs other modifiers)
- Simplifies debugging (can isolate size_level effects)
- Maintains compatibility with existing modifier system

**Alternatives Considered**:
- Convert all modifiers to size_level: Loses granularity, harder to debug
- Ignore size_level, use only existing system: Doesn't meet requirement for unified system

**Implementation Notes**:
```gdscript
base_scale_factor = 1.0 + size_level * SIZE_STEP
other_modifiers = 1.0  # from hero passives, perks, etc.
scale_factor = base_scale_factor * other_modifiers
```

---

### 5. Bug Fix Order

**Task**: Determine order of fixing accumulation bugs vs applying new system.

**Decision**: Fix accumulation bugs first (remove `*=`, restore base values), then apply new system.

**Rationale**:
- Reduces risk of conflicts
- Simplifies debugging (one change at a time)
- Ensures clean state before applying new logic

**Alternatives Considered**:
- Apply new system immediately: May conflict with existing bugs
- Fix and apply in parallel: Higher risk of errors

**Implementation Notes**:
- Task 3 (bug fixes) must complete before Task 2 (new system)
- In `_ready()` and on spawn, always restore base values first, then apply modifiers
- Search for patterns: `scale *=`, `size *=`, `radius *=` and replace with base-based calculation

---

## Technical Decisions Summary

| Decision | Rationale | Impact |
|----------|-----------|--------|
| Automatic weapon discovery | Scalable, maintainable | Low risk, high reliability |
| size_level in .tres config | Aligns with architecture | Minimal changes to existing code |
| Individual node mapping | Handles weapon variety | Requires careful inventory phase |
| Separate size_level from other modifiers | Clear separation of concerns | Maintains compatibility |
| Fix bugs before new system | Reduces conflicts | Sequential task order required |

## Open Questions (Resolved)

All questions from clarification phase have been resolved. No additional research needed.

## Next Steps

Proceed to Phase 1: Design & Contracts
- Generate data-model.md with size calculation entities
- Create contracts for size application API
- Generate quickstart.md for implementation guidance

