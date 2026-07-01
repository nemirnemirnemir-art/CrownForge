# Quick Start: Performance & Optimization Checklist

**Feature**: 004-perf-checklist  
**Date**: 2025-01-09

## Overview

The Performance & Optimization Checklist is a comprehensive evaluation tool for assessing game performance across 10 key areas. It validates existing performance systems (PerformanceMonitor, object pools, QualityManager) and provides actionable steps for optimization.

## Getting Started

### 1. Locate the Checklist

The checklist is located at: `docs/perf_checklist.md`

### 2. Understand the Structure

The checklist is organized into 10 major categories:

1. **FPS, Entity Counts & Object Pooling** - Core performance metrics
2. **Physics & Collisions** - Physics optimization
3. **Rendering** - Draw calls, batching, lighting, shadows, particles
4. **Memory** - GC, allocations, arrays, signals
5. **Scene Loading, Resources, Textures** - Asset optimization
6. **Debug vs Production** - Debug logging and profiling
7. **Quality Management** - Adaptive quality settings
8. **Project-Specific Optimizations** - Weapon/enemy/damage systems
9. **Code-Level Optimizations** - GDScript best practices
10. **Testing & Validation** - Performance testing procedures

### 3. Run the Game

Start the game and play for at least 5 minutes to gather performance data.

### 4. Validate Metrics

For each checklist item:

1. **Read the item description** (e.g., "FPS Baseline: Target 60 FPS stable")
2. **Check the referenced system** (e.g., `PerformanceMonitor.get_fps()`)
3. **Compare against target** (e.g., `fps >= 60.0` for target, `>= 30.0` for minimum)
4. **Mark as complete** if metric meets target, or note the actual value

### 5. Example Validation

**Item**: "FPS Baseline: Target 60 FPS stable, minimum 30 FPS under load"

**Validation Steps**:
1. Open Godot editor or check console logs
2. Query: `PerformanceMonitor.get_fps()` or check `PerformanceMonitor.current_fps`
3. Compare: `fps >= 60.0` (target) or `fps >= 30.0` (minimum)
4. Result: If `fps >= 60.0`, mark as complete. If `30.0 <= fps < 60.0`, note as acceptable. If `fps < 30.0`, mark as critical issue.

## Quick Reference: Target Metrics

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| FPS | 60 | 45-60 | < 30 |
| Draw Calls | < 500 | < 1000 | > 1500 |
| Physics Time | < 2ms | < 5ms | > 10ms |
| Process Time | < 5ms | < 10ms | > 20ms |
| Memory | < 200MB | < 500MB | > 1GB |
| Enemies | 300-600 | 200-800 | > 1000 |
| Projectiles | < 300 | < 500 | > 800 |
| Pool Reuse | > 90% | > 80% | < 50% |

## Common Validation Methods

### FPS Validation
```gdscript
var fps: float = PerformanceMonitor.get_fps()
# Target: fps >= 60.0
# Minimum: fps >= 30.0
```

### Draw Calls Validation
```gdscript
var draw_calls: int = PerformanceMonitor.draw_calls
# Target: draw_calls < 500
# Acceptable: draw_calls < 1000
# Critical: draw_calls > 1500
```

### Pool Reuse Validation
```gdscript
var stats: Dictionary = ProjectilePool.get_stats()
var reuse_ratio: float = stats.get("reuse_ratio", 0.0)
# Target: reuse_ratio > 0.9
# Acceptable: reuse_ratio > 0.8
# Critical: reuse_ratio < 0.5
```

### Quality Level Validation
```gdscript
var quality: int = QualityManager.get_current_quality()
# Levels: 0=critical, 1=low, 2=medium, 3=high
# Target: quality >= 2 (medium)
```

## Troubleshooting

### Metrics Not Available

**Issue**: `PerformanceMonitor` autoload not found

**Solution**: Ensure `PerformanceMonitor` is registered in `project.godot` under `[autoload]` section

### Pool Statistics Show Zero

**Issue**: Pool stats show `reuse_ratio = 0.0`

**Solution**: 
1. Verify pools are initialized: `ProjectilePool._ready()` called
2. Check that projectiles are being spawned and returned to pool
3. Verify pool is being used (not direct `instantiate()` calls)

### Quality Level Not Changing

**Issue**: Quality level stuck at one value

**Solution**:
1. Check `QualityManager.auto_adjust = true`
2. Verify FPS thresholds are configured correctly
3. Check that `PerformanceMonitor` is providing FPS data

## Next Steps

After completing the checklist:

1. **Document Issues**: Note any items that fail validation
2. **Prioritize Fixes**: Focus on critical items first (FPS < 30, draw calls > 1500)
3. **Re-validate**: After fixes, re-run checklist to verify improvements
4. **Update Checklist**: Add project-specific items as needed

## Related Documentation

- `docs/perf_checklist.md` - Full checklist document
- `autoload/OPTIMIZATION_README.md` - Detailed optimization documentation
- `autoload/QUICKSTART.md` - Quick start for performance systems
- `specs/004-perf-checklist/contracts/validation-api.md` - API reference

