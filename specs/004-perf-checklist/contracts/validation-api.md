# Validation API Contract: Performance Checklist

**Feature**: 004-perf-checklist  
**Date**: 2025-01-09  
**Type**: Documentation/Validation API

## Overview

This contract defines the validation methods and APIs used by the performance checklist to evaluate game performance. All APIs reference existing autoload systems.

## Performance Metrics API

### PerformanceMonitor.get_fps() -> float

**Purpose**: Get current FPS value

**Returns**: Current frames per second (float)

**Validation**: Check `get_fps() >= 30.0` for minimum, `>= 60.0` for target

**Example**:
```gdscript
var fps: float = PerformanceMonitor.get_fps()
if fps < 30.0:
    # Critical performance issue
```

---

### PerformanceMonitor.get_avg_fps() -> float

**Purpose**: Get average FPS over sample window

**Returns**: Average FPS (float)

**Validation**: Check `get_avg_fps() >= 55.0` for stable performance

---

### PerformanceMonitor.enemy_count_total -> int

**Purpose**: Get total enemy count

**Returns**: Total enemy count (int)

**Validation**: Check `enemy_count_total <= 600` for quality level 3, `<= 300` for quality level 0

---

### PerformanceMonitor.projectile_count -> int

**Purpose**: Get active projectile count

**Returns**: Active projectile count (int)

**Validation**: Check `projectile_count < 500` for acceptable, `< 300` for target

---

### PerformanceMonitor.draw_calls -> int

**Purpose**: Get draw calls per frame

**Returns**: Draw calls (int)

**Validation**: Check `draw_calls < 1000` for acceptable, `< 500` for target, `> 1500` for critical

---

### PerformanceMonitor.physics_time_ms -> float

**Purpose**: Get physics processing time

**Returns**: Physics time in milliseconds (float)

**Validation**: Check `physics_time_ms < 5.0` for acceptable, `< 2.0` for target, `> 10.0` for critical

---

### PerformanceMonitor.process_time_ms -> float

**Purpose**: Get process time

**Returns**: Process time in milliseconds (float)

**Validation**: Check `process_time_ms < 10.0` for acceptable, `< 5.0` for target, `> 20.0` for critical

---

### PerformanceMonitor.memory_static_mb -> float

**Purpose**: Get static memory usage

**Returns**: Static memory in MB (float)

**Validation**: Check `memory_static_mb < 500.0` for acceptable, `< 200.0` for target, `> 1000.0` for critical

---

## Object Pool API

### ProjectilePool.get_stats() -> Dictionary

**Purpose**: Get projectile pool statistics

**Returns**: Dictionary with keys:
- `total_active: int` - Active projectiles
- `spawn_count: int` - Total spawned
- `reuse_count: int` - Total reused
- `destroy_count: int` - Total destroyed
- `pool_count: int` - Number of pool types
- `reuse_ratio: float` - Reuse ratio (0.0-1.0)

**Validation**: Check `get_stats()["reuse_ratio"] > 0.8` for acceptable, `> 0.9` for target, `< 0.5` for critical

**Example**:
```gdscript
var stats: Dictionary = ProjectilePool.get_stats()
var reuse_ratio: float = stats.get("reuse_ratio", 0.0)
if reuse_ratio < 0.8:
    # Pool efficiency below target
```

---

### DamagePopupPool.get_pool_stats() -> Dictionary

**Purpose**: Get damage popup pool statistics

**Returns**: Dictionary with keys:
- `available: int` - Available popups in pool
- `active: int` - Active popups
- `total: int` - Total popups (available + active)
- `simplified_mode: bool` - Whether simplified mode is active

**Validation**: Check `get_pool_stats()["active"] <= 100` for limit, `get_pool_stats()["total"] <= 200` for pool size

---

## Quality Management API

### QualityManager.get_current_quality() -> int

**Purpose**: Get current quality level

**Returns**: Quality level (0=critical, 1=low, 2=medium, 3=high)

**Validation**: Check `get_current_quality() >= 2` for medium quality, `>= 3` for high quality

---

### QualityManager.get_quality_settings(level: int = -1) -> Dictionary

**Purpose**: Get quality settings for a level

**Parameters**:
- `level: int` - Quality level (-1 for current level)

**Returns**: Dictionary with quality settings:
- `damage_popups_enabled: bool`
- `animation_lod: int`
- `max_enemies: int`
- `max_projectiles: int`
- `off_screen_simplification: bool`
- `batching_enabled: bool`
- `neighbor_limit: int`

**Validation**: Check settings match expected values for each quality level

---

## Validation Workflow

1. **Query Metrics**: Use PerformanceMonitor APIs to get current metrics
2. **Compare Thresholds**: Compare metrics against target/acceptable/critical thresholds
3. **Check Pools**: Use pool APIs to validate reuse ratios and limits
4. **Verify Quality**: Use QualityManager APIs to verify quality settings
5. **Document Results**: Mark checklist items as complete/incomplete based on validation

---

## Error Handling

- All APIs return valid defaults if systems are unavailable
- Missing autoloads should be logged as validation failures
- Invalid metric values should trigger warnings

---

## Notes

- All APIs are read-only (validation only, no state changes)
- APIs reference existing autoload systems (no new implementation)
- Validation performed through gameplay observation and metric queries
- Checklist items use these APIs to determine pass/fail status

