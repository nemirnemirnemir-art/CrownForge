# QualityManager API Contract

**Feature**: Enemy Swarm Optimization  
**Date**: 2025-01-09  
**Status**: Design

## Overview

This document defines the API contract for `QualityManager` enhancements related to enemy swarm optimization. All methods and properties are additions to the existing `QualityManager` autoload.

## New Methods

### `get_culling_distance() -> float`

**Description**: Returns the culling distance for the current quality level.

**Parameters**: None

**Returns**: `float` - Culling distance in pixels (800-1500px based on quality level)

**Example**:
```gdscript
var culling_dist: float = QualityManager.get_culling_distance()
if enemy.global_position.distance_to(player.global_position) > culling_dist:
    enemy.queue_free()
```

**Quality Level Mappings**:
- Level 0 (Critical): 800.0px
- Level 1 (Low): 1000.0px
- Level 2 (Medium): 1200.0px
- Level 3 (High): 1500.0px

---

### `get_max_enemies() -> int`

**Description**: Returns the maximum enemy count for the current quality level.

**Parameters**: None

**Returns**: `int` - Maximum enemies (300-600 based on quality level)

**Example**:
```gdscript
var max_enemies: int = QualityManager.get_max_enemies()
if PerformanceMonitor.enemy_count_total >= max_enemies:
    return  # Don't spawn
```

**Quality Level Mappings**:
- Level 0 (Critical): 300
- Level 1 (Low): 400
- Level 2 (Medium): 500
- Level 3 (High): 600

---

## Enhanced Properties

### `quality_settings[level]["culling_distance"]`

**Type**: `float`

**Description**: Culling distance for each quality level (added to existing `quality_settings` dictionary).

**Access**:
```gdscript
var culling_dist: float = QualityManager.quality_settings[QualityManager.current_quality]["culling_distance"]
```

---

### `quality_settings[level]["enemy_count_threshold"]`

**Type**: `int`

**Description**: Enemy count threshold for triggering simplified AI (already exists, documented here for reference).

**Access**:
```gdscript
var threshold: int = QualityManager.quality_settings[0]["enemy_count_threshold"]  # e.g., 200
```

---

## Existing Methods (Used by Feature)

### `quality_changed(level: int)`

**Description**: Signal emitted when quality level changes. Enemies should connect to this to update their settings.

**Usage**:
```gdscript
# In Enemy.gd
func _ready() -> void:
    QualityManager.quality_changed.connect(_on_quality_changed)

func _on_quality_changed(level: int) -> void:
    var settings: Dictionary = QualityManager.quality_settings[level]
    set_quality_settings(settings)
```

---

## Integration Points

### Enemy.gd
- Calls `QualityManager.get_culling_distance()` for culling checks
- Receives `quality_changed` signal to update settings

### EnemySpawner
- Calls `QualityManager.get_max_enemies()` to enforce limits
- Uses `QualityManager.quality_settings[level]["culling_distance"]` for spawn zone calculations

### PerformanceMonitor
- Provides `enemy_count_total` to `QualityManager` for quality adjustments
- `QualityManager` reads `PerformanceMonitor.current_fps` for quality level decisions

---

## Error Handling

- **Invalid quality level**: If `current_quality` is out of range (0-3), return default values (Level 0: 800px, 300 enemies)
- **Missing settings**: If `quality_settings[level]` is missing, log error and return defaults

---

## References

- Implementation plan: `specs/007-enemy-swarm-optimization/plan.md`
- Data model: `specs/007-enemy-swarm-optimization/data-model.md`
- Existing code: `autoload/QualityManager.gd`

