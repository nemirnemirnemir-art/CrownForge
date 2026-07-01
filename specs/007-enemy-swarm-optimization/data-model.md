# Data Model: Enemy Swarm Optimization

**Date**: 2025-01-09  
**Feature**: Enemy Swarm Optimization  
**Status**: Complete

## Overview

This document defines the data structures, entities, and relationships for the Enemy Swarm Optimization feature. All structures are runtime-only (no persistence) and integrate with existing systems.

## Core Entities

### Enemy Quality Settings

**Location**: `QualityManager.quality_settings[level]` (Dictionary)

**Structure**:
```gdscript
{
    "animation_lod": int,              # 0=full, 1=reduced, 2=minimal
    "simplified_ai": bool,              # Skip complex AI calculations
    "neighbor_limit": int,              # Max neighbors for steering (3-11)
    "off_screen_simplification": bool,  # Simplify off-screen enemies
    "max_enemies": int,                 # Max enemies at this quality level
    "damage_popups_enabled": bool,      # Enable/disable damage popups
    "culling_distance": float,          # Distance for enemy despawn (px)
    "enemy_count_threshold": int        # Threshold for simplified AI (e.g., 200)
}
```

**Quality Level Configurations**:
- **Level 0 (Critical)**: `animation_lod=2`, `simplified_ai=true`, `neighbor_limit=3`, `max_enemies=300`, `culling_distance=800.0`
- **Level 1 (Low)**: `animation_lod=1`, `simplified_ai=false`, `neighbor_limit=5`, `max_enemies=400`, `culling_distance=1000.0`
- **Level 2 (Medium)**: `animation_lod=1`, `simplified_ai=false`, `neighbor_limit=8`, `max_enemies=500`, `culling_distance=1200.0`
- **Level 3 (High)**: `animation_lod=0`, `simplified_ai=false`, `neighbor_limit=11`, `max_enemies=600`, `culling_distance=1500.0`

**Validation Rules**:
- `animation_lod` must be 0, 1, or 2
- `neighbor_limit` must be between 3 and 11
- `max_enemies` must be >= 300 (hard limit)
- `culling_distance` must be > 0 and >= spawn_radius

---

### Enemy Culling State

**Location**: Per-enemy instance (runtime state)

**Structure**:
```gdscript
# In Enemy.gd
var _is_off_screen: bool = false
var _distance_to_player: float = 0.0
var _culling_checked_at: float = 0.0  # Time of last culling check
var _use_simplified_ai: bool = false   # From QualityManager
```

**State Transitions**:
1. **On-screen → Off-screen**: When `distance_to_player > culling_distance`
   - Set `_is_off_screen = true`
   - Disable animations (if quality level allows)
   - Use simplified AI
   - Check for despawn (if beyond culling distance)

2. **Off-screen → On-screen**: When `distance_to_player <= culling_distance`
   - Set `_is_off_screen = false`
   - Re-enable animations
   - Use full AI (if quality level allows)

3. **Despawn**: When `distance_to_player > culling_distance` for extended period
   - Call `queue_free()` (immediate) or `_fade_out_and_despawn()` (quality 2-3)

**Validation Rules**:
- Culling check should run every 0.5-1.0 seconds (not every frame)
- Despawn should only occur if enemy is beyond culling distance for > 1.0 second

---

### Spawn Zone Configuration

**Location**: `EnemySpawner` (runtime configuration)

**Structure**:
```gdscript
# In EnemySpawner.gd
var spawn_radius_px: float = 480.0        # Base spawn radius
var spawn_position_jitter_px: float = 32.0  # Random offset
var max_enemies_per_zone: int = 50        # Prevent accumulation
var culling_distance: float = 800.0       # From QualityManager
var global_spawn_radius_px: float = 480.0  # Override per-config
```

**Spawn Zone Calculation**:
```gdscript
# Spawn zone = circle around player
# Radius = spawn_radius_px (from EnemySpawnConfig or global)
# Culling zone = circle around player
# Radius = culling_distance (from QualityManager)
# Relationship: spawn_radius should be 1.5-2x culling_distance to ensure enemies reach screen
```

**Validation Rules**:
- `spawn_radius_px` must be > 0
- `spawn_radius_px` should be 1.5-2x `culling_distance` for optimal gameplay
- `max_enemies_per_zone` should be <= `max_enemies` from quality settings

---

### Culling Zone Calculation

**Location**: `EnemySpawner` or `CullingManager` (runtime calculation)

**Structure**:
```gdscript
# Calculated per frame or on-demand
var viewport_size: Vector2
var camera_zoom: float
var culling_buffer_multiplier: float = 1.5
var culling_zone_size: Vector2  # Calculated: viewport_size * buffer_multiplier / camera_zoom
```

**Calculation**:
```gdscript
func _calculate_culling_zone() -> Rect2:
    var viewport: Viewport = get_viewport()
    var viewport_rect: Rect2 = viewport.get_visible_rect()
    var camera: Camera2D = get_viewport().get_camera_2d()
    var zoom: float = camera.zoom.x if camera else 1.0
    
    var buffer_size: Vector2 = viewport_rect.size * culling_buffer_multiplier / zoom
    var center: Vector2 = player.global_position
    return Rect2(center - buffer_size / 2, buffer_size)
```

**Validation Rules**:
- `culling_buffer_multiplier` should be 1.5-2.0
- `culling_zone_size` must be >= viewport size
- Calculation should account for camera zoom

---

## Relationships

### QualityManager → Enemy
- **One-to-Many**: One quality level applies to all enemies
- **Signal**: `quality_changed(level: int)` → all enemies receive `set_quality_settings()`
- **Data Flow**: `QualityManager.quality_settings[level]` → `Enemy.set_quality_settings(settings: Dictionary)`

### EnemySpawner → Enemy
- **One-to-Many**: One spawner manages multiple enemy instances
- **Tracking**: `_alive_counts[EnemySpawnConfig]` tracks alive enemies per config
- **Culling**: Spawner checks `PerformanceMonitor.enemy_count_total` before spawning

### PerformanceMonitor → QualityManager
- **One-to-One**: PerformanceMonitor provides FPS/metrics to QualityManager
- **Data Flow**: `PerformanceMonitor.current_fps` → `QualityManager._check_and_adjust_quality()`
- **Trigger**: QualityManager adjusts quality level based on FPS thresholds

### Enemy → Player
- **Many-to-One**: Multiple enemies target one player
- **Distance Calculation**: `enemy.global_position.distance_to(player.global_position)`
- **Culling Check**: Enemy uses distance to player for culling/despawn decisions

---

## State Transitions

### Enemy Lifecycle

```
[Spawned] → [On-screen] → [Off-screen] → [Culling Check] → [Despawned]
    ↓           ↓              ↓
  [Simplified AI] (if quality level 0 or enemy_count >= 200)
    ↓
  [Animation LOD] (based on quality level)
```

### Quality Level Transitions

```
[Level 3] ←→ [Level 2] ←→ [Level 1] ←→ [Level 0]
   (High)      (Medium)      (Low)      (Critical)
   
Trigger: FPS thresholds (NFR-002)
- Level 0: FPS < 30
- Level 1: FPS 30-45
- Level 2: FPS 45-55
- Level 3: FPS >= 55
```

---

## Data Validation

### Enemy Count Limits
- **Hard Limit**: 300 enemies on screen (visible + culling buffer)
- **Per Quality**: `max_enemies` from quality settings (300-600)
- **Enforcement**: `EnemySpawner` checks `PerformanceMonitor.enemy_count_total` before spawning

### Culling Distance Validation
- **Minimum**: Must be > `spawn_radius_px` to prevent immediate despawn
- **Maximum**: Should be < 2000px to prevent memory accumulation
- **Quality-dependent**: Increases with quality level (800-1500px)

### Spawn Zone Validation
- **Radius**: Must be 1.5-2x `culling_distance` for optimal gameplay
- **Position**: Must be outside player collision radius
- **Limit**: `max_enemies_per_zone` prevents accumulation

---

## Integration Points

### Existing Systems
- **QualityManager**: Provides quality settings and culling distance
- **PerformanceMonitor**: Tracks `enemy_count_total` and FPS
- **Enemy.gd**: Implements simplified AI and animation LOD
- **EnemySpawner**: Manages spawning and integrates with culling

### New Additions
- **Culling distance calculation**: Added to `QualityManager` or `EnemySpawner`
- **Despawn logic**: Added to `Enemy.gd` or `EnemySpawner`
- **Spawn zone limits**: Enhanced in `EnemySpawner`

---

## References

- Feature spec: `specs/007-enemy-swarm-optimization/spec.md`
- Research findings: `specs/007-enemy-swarm-optimization/research.md`
- Existing code: `autoload/QualityManager.gd`, `gameplay/enemies/Enemy.gd`, `gameplay/enemies/EnemySpawner.gd`

