# Research: Enemy Death FX v1

**Date**: 2025-01-27  
**Feature**: Enemy Death FX v1 — Hybrid LOD + Pooling  
**Status**: Complete

## Research Questions

### Q1: Shader-based dissolve effect implementation in Godot 4.3

**Decision**: Use `ShaderMaterial` with a uniform `dissolve_progress` (0.0 to 1.0) driven by Tween.

**Rationale**:
- Godot 4.3 supports `ShaderMaterial` on `Sprite2D`/`AnimatedSprite2D` via `material` property
- Shader uniforms can be set via `shader.set_shader_parameter("uniform_name", value)`
- Tween can animate uniform values smoothly without per-frame CPU logic
- Single draw call (no additional nodes) = minimal FPS impact

**Alternatives considered**:
- **Separate DeathFX node**: Rejected — adds draw call, requires pooling separate nodes
- **AnimationPlayer**: Rejected — less flexible for shader uniforms, requires per-enemy setup
- **CPU-based alpha fade**: Rejected — doesn't provide "dissolve" visual effect (pixel-like)

**Implementation notes**:
- Shader type: `shader_type canvas_item;` (for 2D sprites)
- Uniform: `uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;`
- Shader logic: Sample noise texture or use UV-based pattern for dissolve pattern
- Apply shader to enemy sprite's `material` property (can be shared `ShaderMaterial` resource)

**References**:
- Godot 4.3 docs: `ShaderMaterial`, `shader.set_shader_parameter()`
- Existing pattern: `ProjectilePool` shows object reuse pattern (for future pooling)

---

### Q2: Tween integration for shader uniforms

**Decision**: Use `create_tween()` on enemy node, tween shader uniform from 0.0 to 1.0 over FX duration (0.4–0.8 sec).

**Rationale**:
- `Tween` is built-in Godot 4.3 API, no dependencies
- `tween_property()` can animate shader parameters via `material:shader_parameter/dissolve_progress`
- Automatic cleanup when tween finishes (no manual timer management)
- Can connect `finished` signal to cleanup/release logic

**Alternatives considered**:
- **Manual timer + _process()**: Rejected — requires per-frame updates, more CPU overhead
- **AnimationPlayer**: Rejected — requires per-enemy setup, less flexible for runtime values

**Implementation notes**:
```gdscript
var tween := create_tween()
tween.tween_property(material, "shader_parameter/dissolve_progress", 1.0, fx_duration)
tween.finished.connect(_on_fx_finished)
```

**References**:
- Godot 4.3 docs: `Tween`, `tween_property()`, shader parameter paths

---

### Q3: Integration point with existing HealthComponent

**Decision**: Connect to `HealthComponent.died` signal, centralize handling in `EnemyDeathController`.

**Rationale**:
- `HealthComponent` already emits `died` signal when `hp <= 0` (see `components/HealthComponent.gd:106`)
- Existing code uses `died` signal for death animation and `queue_free()` (lines 108-123)
- Can intercept signal before existing handlers, or replace existing `_on_death()` logic
- Centralized controller prevents duplication across enemy types

**Alternatives considered**:
- **Modify HealthComponent directly**: Rejected — violates "don't change existing damage pipeline" requirement
- **Per-enemy death handlers**: Rejected — duplicates logic, harder to maintain LOD cap

**Implementation notes**:
- `EnemyDeathController` connects to `HealthComponent.died` signal on enemy spawn/ready
- Controller checks distance to player, enforces FX cap, triggers appropriate FX
- Existing `HealthComponent._on_death()` logic (death animation, timer) can be disabled or replaced
- Loot drop, XP, kill counters triggered before FX (immediate, not delayed)

**References**:
- Existing: `components/HealthComponent.gd:103-123` (`_on_death()` method)
- Existing: `components/HealthComponent.gd:21` (`died` signal)

---

### Q4: Centralized death controller pattern

**Decision**: Create `EnemyDeathController` autoload or system component that manages all enemy deaths.

**Rationale**:
- Single point of control for LOD decisions, FX cap enforcement, pooling (future)
- Can track active "nice" FX count globally
- Easier to debug and tune (all death logic in one place)
- Follows existing pattern: `ProjectilePool`, `DamagePopupPool` are autoloads

**Alternatives considered**:
- **Per-enemy death logic**: Rejected — duplicates code, harder to enforce global FX cap
- **EnemyManager integration**: Rejected — EnemyManager doesn't exist yet, would require new system

**Implementation notes**:
- `EnemyDeathController` can be autoload (like `ProjectilePool`) or regular node in scene tree
- Methods: `handle_enemy_death(enemy: Enemy, from: Node) -> void`
- Tracks: `var _active_nice_fx_count: int = 0` (incremented on start, decremented on finish)
- Configuration: `EnemyDeathConfig` resource for constants (radius, durations, max FX count)

**References**:
- Existing pattern: `autoload/ProjectilePool.gd` (autoload singleton)
- Existing pattern: `autoload/DamagePopupPool.gd` (autoload singleton)

---

### Q5: LOD distance calculation pattern

**Decision**: Use `enemy.global_position.distance_to(player.global_position)` once per death event.

**Rationale**:
- `Enemy.gd` already calculates distance to target for avoidance logic (line 274: `dist_to_target_sq`)
- Player is accessible via `get_tree().get_first_node_in_group("player")` (existing pattern)
- Distance calculation is cheap (`distance_to()` or `distance_squared_to()` for comparison)
- Decision made once at death time, not per-frame (spec requirement)

**Alternatives considered**:
- **Camera position**: Rejected — player position is simpler, matches existing Enemy.gd logic
- **Per-frame LOD switching**: Rejected — spec explicitly forbids this

**Implementation notes**:
- Get player: `var player := get_tree().get_first_node_in_group("player") as Node2D`
- Calculate: `var dist := enemy.global_position.distance_to(player.global_position)`
- Compare: `if dist <= NEAR_DEATH_RADIUS: # nice FX else: # cheap fade`
- Cache decision in enemy state (no re-evaluation during FX)

**References**:
- Existing: `gameplay/enemies/Enemy.gd:274` (distance calculation pattern)
- Existing: `gameplay/enemies/EnemySpawner.gd:89` (player lookup via group)

---

### Q6: Configuration management pattern

**Decision**: Create `EnemyDeathConfig` resource (extends `Resource`) with all constants, load as singleton or per-scene.

**Rationale**:
- Follows existing pattern: `WeaponConfig`, `EnemySpawnConfig` are resources
- Single source of truth for all tunable values
- Can be exported in editor, saved as `.tres` file
- Easy to adjust without code changes

**Alternatives considered**:
- **Hardcoded constants**: Rejected — violates "configurable in one place" requirement
- **Config file (JSON/INI)**: Rejected — Godot resources are more integrated with editor

**Implementation notes**:
```gdscript
extends Resource
class_name EnemyDeathConfig

@export var near_death_radius_px: float = 500.0
@export var nice_fx_duration_sec: float = 0.6
@export var cheap_fade_duration_sec: float = 0.15
@export var max_active_nice_fx: int = 30
```

**References**:
- Existing: `data/config/WeaponConfig.gd` (resource pattern)
- Existing: `gameplay/enemies/EnemySpawnConfig.gd` (resource pattern)

---

## Summary

All research questions resolved. Implementation approach:
1. **Shader dissolve**: `ShaderMaterial` with `dissolve_progress` uniform, driven by Tween
2. **Tween**: `create_tween()` → `tween_property()` for shader parameter animation
3. **Integration**: Connect to `HealthComponent.died` signal, centralize in `EnemyDeathController`
4. **Controller**: Autoload or system component, tracks active FX count, enforces cap
5. **LOD**: Distance to player, calculated once per death, cached in enemy state
6. **Config**: `EnemyDeathConfig` resource for all constants

**No blocking unknowns remain.** Ready for Phase 1 design.

