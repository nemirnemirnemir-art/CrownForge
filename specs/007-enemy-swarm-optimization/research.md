# Research: Enemy Swarm Optimization

**Date**: 2025-01-09  
**Feature**: Enemy Swarm Optimization  
**Status**: Complete

## Overview

This document consolidates research findings for open questions (TBD-001 through TBD-012) identified in the feature specification and implementation plan. All findings are based on Godot 4.3 best practices, performance optimization patterns, and game design considerations for roguelike auto-shooters.

## Research Questions & Findings

### TBD-006: Maximum Screen Size for Culling Calculations

**Question**: What is the maximum screen size to consider for culling calculations? (Viewport size? Fixed buffer? Camera zoom?)

**Decision**: Use viewport size with configurable buffer multiplier based on camera zoom.

**Rationale**:
- Godot 4.3 provides `get_viewport().get_visible_rect().size` for viewport dimensions
- Camera zoom affects visible area, so culling zone should scale with zoom
- Fixed buffer (e.g., 1.5x viewport size) provides predictable performance
- Buffer prevents enemies from popping in/out at screen edges

**Alternatives Considered**:
- **Fixed pixel buffer**: Simple but doesn't account for camera zoom
- **Camera transform-based**: More accurate but complex calculations
- **Viewport-only**: Too tight, causes visible pop-in

**Implementation Approach**:
```gdscript
# In EnemySpawner or CullingManager
var viewport_size: Vector2 = get_viewport().get_visible_rect().size
var camera_zoom: float = camera.zoom.x  # Assume uniform zoom
var culling_buffer_multiplier: float = 1.5  # Configurable
var culling_zone_size: Vector2 = viewport_size * culling_buffer_multiplier / camera_zoom
```

**Reference**: Godot 4.3 documentation - `Viewport.get_visible_rect()`, `Camera2D.zoom`

---

### TBD-007: Optimal Culling Distance

**Question**: What is the optimal culling distance? (Distance beyond screen bounds where enemies are despawned)

**Decision**: Use distance-based culling with quality-level-dependent thresholds.

**Rationale**:
- Distance-based culling is more predictable than viewport-based for moving camera
- Quality levels allow different thresholds (tighter at level 0, looser at level 3)
- Distance should be 1.5-2x spawn radius to prevent accumulation

**Alternatives Considered**:
- **Fixed distance**: Simple but doesn't adapt to performance
- **Viewport-based only**: Doesn't account for camera movement
- **Dynamic based on FPS**: Too complex, quality levels already handle this

**Implementation Approach**:
```gdscript
# Quality-dependent culling distances
var culling_distances: Dictionary = {
    0: 800.0,   # Critical: tight culling
    1: 1000.0,  # Low: moderate
    2: 1200.0,  # Medium: loose
    3: 1500.0   # High: very loose
}
# Check: distance from player > culling_distance[quality_level]
```

**Reference**: Common practice in roguelike games - 1.5-2x spawn radius for despawn distance

---

### TBD-008: Despawn System Implementation

**Question**: How to implement despawn system? (Immediate despawn? Gradual fade? Queue for next spawn?)

**Decision**: Immediate despawn with optional fade-out for quality levels 2-3.

**Rationale**:
- Immediate despawn provides best performance (no lingering objects)
- Fade-out is optional visual polish, only at higher quality levels
- Queue system adds complexity without significant benefit
- Enemies are respawned dynamically, so queue isn't needed

**Alternatives Considered**:
- **Gradual fade**: Better visuals but adds processing overhead
- **Queue for respawn**: Unnecessary complexity, spawner handles respawning
- **Delayed despawn**: Adds memory overhead without benefit

**Implementation Approach**:
```gdscript
# In Enemy.gd or EnemySpawner
func _check_culling() -> bool:
    var distance: float = global_position.distance_to(player.global_position)
    var culling_dist: float = QualityManager.get_culling_distance()
    if distance > culling_dist:
        if QualityManager.current_quality >= 2:
            _fade_out_and_despawn()  # Optional fade
        else:
            queue_free()  # Immediate despawn
        return true
    return false
```

**Reference**: Godot 4.3 `Node.queue_free()` for immediate cleanup, `modulate` property for fade

---

### TBD-009: Spawn Zone Design

**Question**: How to design spawn zones to maintain "attack from all sides" feel without accumulating enemies?

**Decision**: Dynamic spawn zones around player with distance-based limits and culling integration.

**Rationale**:
- Spawn zones should be circular around player (360° coverage)
- Spawn radius should be 1.5-2x culling distance to ensure enemies reach screen
- Limit total enemies per spawn zone to prevent accumulation
- Integrate with culling to despawn enemies beyond culling distance

**Alternatives Considered**:
- **Fixed spawn zones**: Doesn't adapt to player movement
- **Grid-based spawning**: Too rigid for roguelike feel
- **Random spawns everywhere**: Causes accumulation issues

**Implementation Approach**:
```gdscript
# In EnemySpawner
var spawn_radius_px: float = 480.0  # Base spawn radius
var culling_distance: float = 800.0  # From QualityManager
var max_enemies_per_zone: int = 50  # Prevent accumulation

func _spawn_enemy() -> void:
    if PerformanceMonitor.enemy_count_total >= 300:
        return  # Hard limit
    
    var angle: float = randf() * TAU
    var distance: float = spawn_radius_px + randf() * 100.0
    var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * distance
    
    # Spawn enemy at pos
    # Enemy will be culled if it moves beyond culling_distance
```

**Reference**: Existing `EnemySpawner` already uses circular spawn pattern, needs culling integration

---

### TBD-001: Walk Animation at Quality Level 0

**Question**: Can walk animation be stopped at quality level 0 without breaking gameplay?

**Decision**: Keep animation at 0.5x speed (current implementation). Stopping completely may break visual feedback.

**Rationale**:
- Current implementation (0.5x speed) already provides significant performance benefit
- Stopping animation completely may make enemies appear frozen or glitched
- Sprite flip_h still needs to update for direction, which requires animation frame or manual update
- 0.5x speed is acceptable compromise between performance and visuals

**Alternatives Considered**:
- **Stop animation completely**: Better performance but may break visual feedback
- **Keep at 1.0x speed**: Better visuals but worse performance
- **0.25x speed**: Too slow, looks broken

**Implementation Approach**: Current implementation in `Enemy.gd` already handles this via `animation_lod` setting. No changes needed unless testing shows 0.5x is insufficient.

**Reference**: Current `Enemy.gd` implementation, `QualityManager.quality_settings[0]["animation_lod"] = 2`

---

### TBD-002: Optimal Simplification Level for Hit Effects

**Question**: What is the optimal simplification level for hit effects? (Disable completely vs. reduce particle count vs. simpler sprite)

**Decision**: Quality-dependent: Level 0 = disable, Level 1 = reduce particles, Level 2-3 = full effects.

**Rationale**:
- Hit effects are visual polish, not gameplay-critical
- Disabling at level 0 provides maximum performance benefit
- Reducing particles at level 1 balances performance and feedback
- Full effects at higher levels maintain visual quality

**Alternatives Considered**:
- **Always reduce particles**: Doesn't provide enough performance benefit at level 0
- **Never disable**: Misses optimization opportunity
- **Simpler sprite**: Adds complexity without significant benefit

**Implementation Approach**:
```gdscript
# In Enemy.gd or hit effect system
func _spawn_hit_effect() -> void:
    var quality: int = QualityManager.current_quality
    if quality == 0:
        return  # Disabled
    elif quality == 1:
        _spawn_simple_hit_effect()  # Reduced particles
    else:
        _spawn_full_hit_effect()  # Full effects
```

**Reference**: `QualityManager.quality_settings` already has `damage_popups_enabled` flag, can extend for hit effects

---

### TBD-003: Optimal Simplification Level for Damage Popups

**Question**: What is the optimal simplification level for damage popups? (Disable vs. reduce frequency vs. simpler rendering)

**Decision**: Quality-dependent: Level 0 = disable, Level 1 = reduce frequency, Level 2-3 = full popups.

**Rationale**:
- Damage popups are feedback, not gameplay-critical
- `QualityManager` already has `damage_popups_enabled` flag for level 0
- Reducing frequency at level 1 provides performance benefit while maintaining feedback
- Full popups at higher levels maintain visual quality

**Alternatives Considered**:
- **Always reduce frequency**: Doesn't provide enough benefit at level 0
- **Never disable**: Misses optimization opportunity
- **Simpler rendering**: Adds complexity, frequency reduction is simpler

**Implementation Approach**:
```gdscript
# In DamagePopupPool or damage system
func _spawn_damage_popup(damage: int, pos: Vector2) -> void:
    var quality: int = QualityManager.current_quality
    if quality == 0:
        return  # Disabled (already implemented)
    elif quality == 1:
        if randf() > 0.5:  # 50% frequency
            _spawn_popup(damage, pos)
    else:
        _spawn_popup(damage, pos)  # Full frequency
```

**Reference**: `QualityManager.quality_settings[0]["damage_popups_enabled"] = false` already implemented

---

## Consolidated Implementation Strategy

### Culling System
1. **Viewport-based culling zone**: Use `get_viewport().get_visible_rect().size * 1.5 / camera.zoom`
2. **Distance-based despawn**: Quality-dependent distances (800-1500px)
3. **Immediate despawn**: `queue_free()` for performance, optional fade at quality 2-3

### Spawn System
1. **Dynamic spawn zones**: Circular around player, 1.5-2x culling distance
2. **Hard limit enforcement**: 300 enemies max (visible + culling buffer)
3. **Integration with culling**: Spawner checks culling distance before spawning

### Visual Effects
1. **Animation LOD**: Keep current 0.5x speed at level 0 (no stopping)
2. **Hit effects**: Disable at level 0, reduce particles at level 1, full at 2-3
3. **Damage popups**: Disable at level 0 (already implemented), reduce frequency at level 1

## Testing Requirements

### Performance Tests
- Measure FPS impact of different culling distances (800, 1000, 1200, 1500px)
- Measure FPS impact of disabling/reducing hit effects and damage popups
- Verify 300 enemy limit maintains 30+ FPS

### Gameplay Tests
- Verify "attack from all sides" feel is maintained
- Verify enemies don't pop in/out at screen edges
- Verify culling doesn't break immersion or create visual glitches

## References

- Godot 4.3 Documentation: `Viewport.get_visible_rect()`, `Camera2D.zoom`, `Node.queue_free()`
- Existing code: `QualityManager.gd`, `Enemy.gd`, `EnemySpawner.gd`, `PerformanceMonitor.gd`
- Feature spec: `specs/007-enemy-swarm-optimization/spec.md`
- Performance checklist: `docs/perf_checklist.md`

