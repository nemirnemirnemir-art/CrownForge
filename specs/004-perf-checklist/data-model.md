# Data Model: Performance & Optimization Checklist

**Feature**: 004-perf-checklist  
**Date**: 2025-01-09

## Overview

This feature is documentation-only and does not introduce new data entities. The checklist validates existing performance systems and their data structures.

## Existing System Data Models

### PerformanceMetrics (PerformanceMonitor)

**Purpose**: Represents current game performance state

**Fields**:
- `current_fps: float` - Current frames per second
- `min_fps: float` - Minimum FPS in sample window
- `max_fps: float` - Maximum FPS in sample window
- `avg_fps: float` - Average FPS in sample window
- `enemy_count_total: int` - Total enemy count
- `enemy_count_on_screen: int` - Enemies visible on screen
- `enemy_count_off_screen: int` - Enemies off-screen
- `projectile_count: int` - Active projectile count
- `damage_popup_count: int` - Active damage popup count
- `draw_calls: int` - Render draw calls per frame
- `physics_time_ms: float` - Physics processing time (milliseconds)
- `process_time_ms: float` - Process time (milliseconds)
- `render_time_ms: float` - Render time (milliseconds)
- `memory_static_mb: float` - Static memory usage (MB)
- `memory_dynamic_mb: float` - Dynamic memory usage (MB)

**Validation Rules** (from checklist):
- FPS: Target 60, minimum 30
- Draw calls: Target <500, acceptable <1000, critical >1500
- Physics time: Target <2ms, acceptable <5ms, critical >10ms
- Process time: Target <5ms, acceptable <10ms, critical >20ms
- Memory: Target <200MB, acceptable <500MB, critical >1GB

---

### ObjectPoolStats (ProjectilePool, DamagePopupPool)

**Purpose**: Represents object pool statistics for reuse tracking

**Fields**:
- `total_active: int` - Total active objects in pool
- `spawn_count: int` - Total objects created (not reused)
- `reuse_count: int` - Total objects reused from pool
- `destroy_count: int` - Total objects destroyed
- `pool_count: int` - Number of pool types
- `reuse_ratio: float` - Reuse ratio (reuse_count / (spawn_count + reuse_count))
- `available: int` - Available objects in pool
- `active: int` - Active objects from pool
- `simplified_mode: bool` - Whether simplified mode is active

**Validation Rules** (from checklist):
- Reuse ratio: Target >90%, acceptable >80%, critical <50%
- Pool validation: All objects must pass `is_instance_valid()` before reuse
- Pool cleanup: Invalid objects removed periodically

---

### QualityLevel (QualityManager)

**Purpose**: Represents a performance/quality configuration level

**Fields**:
- `level: int` - Quality level (0=critical, 1=low, 2=medium, 3=high)
- `damage_popups_enabled: bool` - Whether damage popups are enabled
- `animation_lod: int` - Animation LOD level (0=full, 1=reduced, 2=minimal)
- `max_enemies: int` - Maximum enemy count
- `max_projectiles: int` - Maximum projectile count
- `off_screen_simplification: bool` - Whether off-screen simplification is enabled
- `batching_enabled: bool` - Whether batching is enabled
- `neighbor_limit: int` - Spatial query neighbor limit

**Validation Rules** (from checklist):
- Quality levels: 4 levels (0-3) must be configured
- FPS thresholds: 30/45/55 FPS for level transitions
- Settings broadcast: All affected systems receive updated settings

---

### PerformanceThreshold

**Purpose**: Represents a performance limit that triggers alerts

**Fields**:
- `metric_type: String` - Type of metric (fps, enemies, projectiles, draw_calls, memory)
- `warning_value: float` - Value that triggers warning
- `critical_value: float` - Value that triggers critical alert

**Validation Rules** (from checklist):
- FPS: Warning at 50 FPS, critical at 30 FPS
- Enemies: Warning at 300, critical at 500
- Draw calls: Warning at 1000, critical at 1500
- Memory: Warning at 500MB, critical at 1GB

---

## Checklist Item Structure

**Purpose**: Represents a single checklist validation item

**Fields** (implicit in markdown):
- `category: String` - Category name (e.g., "FPS Monitoring")
- `subcategory: String` - Subcategory name (e.g., "FPS Baseline")
- `item_text: String` - Item description
- `validation_method: String` - How to validate (e.g., "check PerformanceMonitor.draw_calls < 500")
- `target_value: Variant` - Target value or threshold
- `system_reference: String` - Reference to system API (e.g., "PerformanceMonitor.draw_calls")

**Validation Rules**:
- All items must reference existing system APIs
- All items must have measurable target values
- All items must have clear validation method

---

## Relationships

- **PerformanceMetrics** → used by → **PerformanceThreshold** (metrics compared against thresholds)
- **ObjectPoolStats** → tracked by → **PerformanceMetrics** (pool counts included in metrics)
- **QualityLevel** → affects → **PerformanceMetrics** (quality settings affect performance)
- **ChecklistItem** → validates → **PerformanceMetrics**, **ObjectPoolStats**, **QualityLevel** (items validate system states)

---

## State Transitions

### Quality Level Transitions

**States**: 0 (critical) → 1 (low) → 2 (medium) → 3 (high)

**Triggers**:
- FPS drops below threshold → decrease level
- FPS recovers above threshold → increase level

**Validation** (from checklist):
- Transitions smoothed over 5 samples
- Quality history prevents rapid switching
- Settings broadcast to all affected systems

---

## Notes

- No new data structures required - checklist validates existing systems
- All data models reference existing autoload systems
- Checklist items are documentation-only (markdown checkboxes)
- Validation performed through gameplay observation and metric queries

