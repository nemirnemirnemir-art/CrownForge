# API Contract: EnemyDeathController

**Version**: 1.0  
**Date**: 2025-01-27  
**Feature**: Enemy Death FX v1

## Overview

`EnemyDeathController` provides centralized death handling for all enemies, including LOD-based FX selection, cap enforcement, and cleanup.

## Public API

### Methods

#### `handle_enemy_death(enemy: Enemy, from: Node) -> void`

**Purpose**: Main entry point for enemy death handling.

**Parameters**:
- `enemy: Enemy` — Enemy instance that died (must have `HealthComponent` child)
- `from: Node` — Source of damage (can be null)

**Behavior**:
1. Set enemy state to `DYING`
2. Disable enemy AI, movement, collisions immediately
3. Calculate distance to player
4. Decide FX type (nice vs cheap) based on distance and cap
5. Start appropriate FX (dissolve shader or alpha fade)
6. Trigger loot drop, XP, kill counters (immediate, not delayed)
7. Cleanup and release after FX finishes

**Preconditions**:
- `enemy != null` and `is_instance_valid(enemy)`
- Enemy has `HealthComponent` child with `died` signal
- Enemy has sprite node (`AnimatedSprite2D` or `Sprite2D`) for FX application
- Player exists in scene tree (group "player")

**Postconditions**:
- Enemy state is `DYING` or `DEAD`
- Enemy AI/movement/collisions disabled
- FX started (nice or cheap variant)
- Loot/XP/kill counters triggered

**Side Effects**:
- Increments `_active_nice_fx_count` if nice FX started
- Applies shader material to enemy sprite (if nice FX)
- Creates Tween for FX animation
- Connects cleanup callbacks

**Errors**:
- If player not found → logs warning, uses cheap FX as fallback
- If enemy invalid → returns early, no-op

---

#### `_should_use_nice_fx(enemy: Enemy) -> bool`

**Purpose**: LOD decision logic (distance + cap check).

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Returns**: `true` if nice FX should be used, `false` for cheap FX

**Behavior**:
1. Calculate distance from enemy to player
2. If distance > `NEAR_DEATH_RADIUS` → return `false` (cheap FX)
3. If `_active_nice_fx_count >= max_active_nice_fx` → return `false` (cap exceeded, cheap FX)
4. Otherwise → return `true` (nice FX)

**Preconditions**:
- `enemy != null`
- `_config` loaded (non-null)
- Player exists in scene tree

**Postconditions**:
- Decision cached in enemy state (no re-evaluation)

---

#### `_start_nice_fx(enemy: Enemy) -> void`

**Purpose**: Start dissolve shader FX on enemy sprite.

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Behavior**:
1. Get enemy sprite (`AnimatedSprite2D` or `Sprite2D`)
2. Apply shared `ShaderMaterial` to sprite's `material` property
3. Set shader uniform `dissolve_progress = 0.0`
4. Create Tween, animate `dissolve_progress` from 0.0 to 1.0 over `nice_fx_duration_sec`
5. Connect Tween `finished` signal to `_on_nice_fx_finished()`
6. Increment `_active_nice_fx_count`

**Preconditions**:
- `enemy != null`
- Enemy has sprite node
- Shared shader material loaded
- `_active_nice_fx_count < max_active_nice_fx` (enforced by caller)

**Postconditions**:
- Shader material applied to sprite
- Tween active, animating dissolve
- `_active_nice_fx_count` incremented

**Side Effects**:
- Modifies sprite's `material` property
- Creates Tween node as child of enemy

---

#### `_start_cheap_fx(enemy: Enemy) -> void`

**Purpose**: Start alpha fade-out FX on enemy sprite.

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Behavior**:
1. Get enemy sprite (`AnimatedSprite2D` or `Sprite2D`)
2. Create Tween, animate `modulate.a` from 1.0 to 0.0 over `cheap_fade_duration_sec`
3. Connect Tween `finished` signal to `_on_cheap_fx_finished()`

**Preconditions**:
- `enemy != null`
- Enemy has sprite node

**Postconditions**:
- Tween active, animating alpha fade
- No cap increment (cheap FX doesn't count toward limit)

**Side Effects**:
- Modifies sprite's `modulate.a` property
- Creates Tween node as child of enemy

---

#### `_on_nice_fx_finished(enemy: Enemy) -> void`

**Purpose**: Cleanup callback for "nice" FX completion.

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Behavior**:
1. Reset shader uniform `dissolve_progress = 0.0`
2. Remove shader material from sprite (set `material = null` or restore original)
3. Decrement `_active_nice_fx_count`
4. Call `_cleanup_and_release(enemy)`

**Preconditions**:
- `enemy != null`
- Nice FX was active (shader material applied)

**Postconditions**:
- Shader material removed/reset
- `_active_nice_fx_count` decremented
- Enemy ready for release

---

#### `_on_cheap_fx_finished(enemy: Enemy) -> void`

**Purpose**: Cleanup callback for "cheap" FX completion.

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Behavior**:
1. Reset alpha `modulate.a = 1.0` (for future reuse if pooling added)
2. Call `_cleanup_and_release(enemy)`

**Preconditions**:
- `enemy != null`
- Cheap FX was active (alpha fade completed)

**Postconditions**:
- Alpha reset
- Enemy ready for release

---

#### `_cleanup_and_release(enemy: Enemy) -> void`

**Purpose**: Final cleanup and release (pool or queue_free).

**Parameters**:
- `enemy: Enemy` — Enemy instance

**Behavior**:
1. Set enemy state to `DEAD`
2. Disconnect any remaining signals
3. If pooling available: call `EnemyPool.release_enemy(enemy)`
4. Otherwise: call `enemy.queue_free()`

**Preconditions**:
- `enemy != null`
- FX finished (nice or cheap)

**Postconditions**:
- Enemy removed from scene or returned to pool
- All resources cleaned up

---

## Signals

### `enemy_death_handled(enemy: Enemy, fx_type: String)`

**Purpose**: Emitted after death handling starts (for debugging/telemetry).

**Parameters**:
- `enemy: Enemy` — Enemy that died
- `fx_type: String` — `"nice"` or `"cheap"`

**When Emitted**: After `handle_enemy_death()` decides FX type and starts FX.

---

## Configuration API

### `EnemyDeathConfig` Resource

**Properties** (all `@export` for editor tuning):
- `near_death_radius_px: float = 500.0`
- `nice_fx_duration_sec: float = 0.6`
- `cheap_fade_duration_sec: float = 0.15`
- `max_active_nice_fx: int = 30`

**Usage**: Load as resource, pass to `EnemyDeathController` on initialization.

---

## Integration Points

### With HealthComponent

**Connection**: `HealthComponent.died` signal → `EnemyDeathController.handle_enemy_death()`

**Setup**: Connect on enemy spawn/ready:
```gdscript
var health := enemy.get_node_or_null("HealthComponent") as HealthComponent
if health != null:
    health.died.connect(EnemyDeathController.handle_enemy_death.bind(enemy))
```

### With Enemy Spawn System

**No changes required**: Death controller connects to existing `HealthComponent.died` signal, no spawn system modifications.

### With Loot/XP Systems

**Trigger**: Loot drop, XP, kill counters triggered immediately in `handle_enemy_death()` (before FX starts).

**Note**: Existing systems should continue to work (no API changes).

---

## Error Handling

### Missing Player

**Symptom**: Player not found in scene tree (group "player" empty).

**Behavior**: Log warning, use cheap FX as fallback (assume far distance).

**Recovery**: Controller can retry player lookup on next death event.

### Invalid Enemy

**Symptom**: `enemy == null` or `not is_instance_valid(enemy)`.

**Behavior**: Return early, no-op (no FX, no cleanup).

### Missing Sprite

**Symptom**: Enemy has no `AnimatedSprite2D` or `Sprite2D` child.

**Behavior**: Log error, skip FX, proceed to cleanup (enemy still removed).

### Shader Material Missing

**Symptom**: Shared shader material resource not loaded.

**Behavior**: Log error, fallback to cheap FX (alpha fade).

---

## Performance Guarantees

- **LOD decision**: O(1) — single distance calculation, cached
- **FX start**: O(1) — shader material application, Tween creation
- **FX update**: O(1) per frame — Tween-driven (no per-frame CPU logic)
- **Cap enforcement**: O(1) — simple counter increment/decrement
- **Cleanup**: O(1) — signal disconnect, pool release or queue_free

**Total overhead per death**: Constant time, no per-frame loops over dying enemies.

