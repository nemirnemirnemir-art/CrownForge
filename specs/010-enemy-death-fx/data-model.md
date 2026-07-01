# Data Model: Enemy Death FX v1

**Date**: 2025-01-27  
**Feature**: Enemy Death FX v1 — Hybrid LOD + Pooling

## Entities

### EnemyDeathConfig

**Type**: `Resource` (extends `Resource`, class_name `EnemyDeathConfig`)

**Purpose**: Centralized configuration for all death FX constants.

**Fields**:
- `near_death_radius_px: float = 500.0` — Distance threshold for "nice" vs "cheap" FX (400–600 px range)
- `nice_fx_duration_sec: float = 0.6` — Duration of dissolve shader FX (0.4–0.8 sec range)
- `cheap_fade_duration_sec: float = 0.15` — Duration of alpha fade-out for far deaths (0.1–0.2 sec range)
- `max_active_nice_fx: int = 30` — Hard cap on simultaneous "nice" FX (mandatory enforcement)

**Validation Rules**:
- `near_death_radius_px > 0.0` (must be positive)
- `nice_fx_duration_sec > 0.0` (must be positive)
- `cheap_fade_duration_sec > 0.0` (must be positive)
- `max_active_nice_fx > 0` (must be at least 1)

**Relationships**:
- Loaded by `EnemyDeathController` (singleton reference)
- Can be saved as `.tres` resource file (e.g., `data/config/EnemyDeathConfig.tres`)

---

### EnemyDeathController

**Type**: `Node` (autoload singleton or scene node, class_name `EnemyDeathController`)

**Purpose**: Centralized death handling, LOD decisions, FX cap enforcement.

**State Variables**:
- `_config: EnemyDeathConfig` — Configuration resource (loaded on ready)
- `_active_nice_fx_count: int = 0` — Current count of active "nice" FX (incremented on start, decremented on finish)
- `_player: Node2D = null` — Cached player reference (lookup via group "player")

**Methods**:
- `handle_enemy_death(enemy: Enemy, from: Node) -> void` — Main entry point for death handling
- `_calculate_distance_to_player(enemy: Enemy) -> float` — Distance calculation helper
- `_should_use_nice_fx(enemy: Enemy) -> bool` — LOD decision (distance + cap check)
- `_start_nice_fx(enemy: Enemy) -> void` — Start dissolve shader FX
- `_start_cheap_fx(enemy: Enemy) -> void` — Start alpha fade-out FX
- `_on_nice_fx_finished(enemy: Enemy) -> void` — Cleanup callback for "nice" FX
- `_on_cheap_fx_finished(enemy: Enemy) -> void` — Cleanup callback for "cheap" FX

**Relationships**:
- Connects to `HealthComponent.died` signal on enemy spawn/ready
- Manages shader material application on enemy sprites
- Tracks active FX count (global state)

**State Transitions**:
```
Enemy alive → HP <= 0 → HealthComponent.died signal → EnemyDeathController.handle_enemy_death()
→ LOD decision → Start FX (nice or cheap) → FX finishes → Cleanup → Release to pool/queue_free()
```

---

### Enemy (Extended State)

**Type**: `Node2D` (existing `Enemy.gd` base class)

**Purpose**: Enemy state extended with death FX state.

**New State Fields** (added to existing Enemy class):
- `_death_state: int = 0` — Death state enum: `ALIVE = 0`, `DYING = 1`, `DEAD = 2`
- `_death_fx_tween: Tween = null` — Active Tween for death FX (null if no FX active)
- `_death_shader_material: ShaderMaterial = null` — Shader material applied during "nice" FX (null if not using shader)

**State Transitions**:
```
ALIVE → (HP <= 0) → DYING → (FX finishes) → DEAD → (cleanup) → removed from scene
```

**Validation Rules**:
- `_death_state == DYING` → enemy AI/movement/collisions disabled
- `_death_state == DEAD` → enemy ready for pool release or `queue_free()`

**Relationships**:
- Has `HealthComponent` child (existing)
- Has `AnimatedSprite2D` or `Sprite2D` child (for shader application)
- Referenced by `EnemyDeathController` during death handling

---

### ShaderMaterial (Shared Resource)

**Type**: `ShaderMaterial` (Godot built-in resource)

**Purpose**: Shared shader material for dissolve effect (reused across all enemies).

**Properties**:
- `shader: Shader` — Reference to `enemy_death_dissolve.gdshader`
- `shader_parameter/dissolve_progress: float = 0.0` — Uniform animated by Tween (0.0 to 1.0)

**Relationships**:
- Loaded once as shared resource (e.g., `preload("res://shaders/enemy_death_dissolve_material.tres")`)
- Applied to enemy sprite's `material` property during "nice" FX
- Reset to `dissolve_progress = 0.0` after FX or on enemy reuse

---

## Data Flow

### Death Event Flow

```
1. Enemy takes damage → HealthComponent.apply_damage()
2. HP <= 0 → HealthComponent._on_death() → HealthComponent.died.emit()
3. EnemyDeathController (connected to died signal) → handle_enemy_death()
4. Calculate distance to player → _should_use_nice_fx()
5a. If nice FX: Check cap → Start dissolve shader → Tween animate → Finish → Cleanup
5b. If cheap FX: Start alpha fade → Tween animate → Finish → Cleanup
6. Cleanup: Reset shader/material, disable collisions, trigger loot/XP
7. Release to pool (if available) or queue_free()
```

### FX Cap Enforcement Flow

```
1. Enemy dies → handle_enemy_death()
2. LOD decision: distance <= NEAR_DEATH_RADIUS → wants nice FX
3. Check: _active_nice_fx_count < max_active_nice_fx?
4a. If yes: Start nice FX → _active_nice_fx_count++ → Tween → Finish → _active_nice_fx_count--
4b. If no: Fallback to cheap FX (no increment)
```

---

## Constraints

### Performance Constraints

- Max 30 simultaneous "nice" FX (hard cap, enforced)
- Shader-based FX only (no separate nodes, 1 draw call per enemy)
- LOD decision made once per death (no per-frame re-evaluation)
- Tween-driven animation (no per-frame CPU logic)

### State Constraints

- Enemy state `DYING` → all AI/movement/collisions disabled immediately
- Shader uniform `dissolve_progress` reset to 0.0 on enemy reuse (if pooling added)
- Alpha `modulate.a` reset to 1.0 on enemy reuse (if pooling added)

### Integration Constraints

- Must not change `HealthComponent.apply_damage()` API
- Must not change enemy spawn system
- Must preserve existing loot drop, XP, kill counter logic

---

## Future Extensions (Phase 2)

### EnemyPool (Optional)

**Type**: `Node` (autoload singleton, similar to `ProjectilePool`)

**Purpose**: Object pooling for enemies (optional in v1, future enhancement).

**State Variables**:
- `_pools: Dictionary` — `{scene_path: {available: Array, active: Array}}`
- `_total_active: int` — Global active enemy count

**Methods**:
- `spawn_enemy(type: PackedScene, position: Vector2) -> Enemy`
- `release_enemy(enemy: Enemy) -> void`
- `_reset_enemy_state(enemy: Enemy) -> void` — Reset HP, status effects, shader uniforms, timers

**State Reset Requirements** (when pooling implemented):
- HP → max_hp
- Status effects → clear all (burn, slow, medusa, etc.)
- AI state → reset to default
- Timers → reset to 0.0
- Shader uniforms → `dissolve_progress = 0.0`
- Alpha → `modulate.a = 1.0`
- Position → set to spawn position
- Collisions → re-enable
- Death state → `ALIVE`

