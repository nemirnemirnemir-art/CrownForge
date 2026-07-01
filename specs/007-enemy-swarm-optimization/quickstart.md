# Quick Start: Enemy Swarm Optimization

**Feature**: Enemy Swarm Optimization  
**Date**: 2025-01-09  
**Status**: Design

## Overview

This guide provides a quick start for implementing and testing the Enemy Swarm Optimization feature. It covers key integration points, testing procedures, and common scenarios.

## Prerequisites

- Godot 4.3 installed
- Project with existing systems: `QualityManager`, `PerformanceMonitor`, `Enemy.gd`, `EnemySpawner`
- Access to `docs/perf_checklist.md` for related optimizations

## Implementation Checklist

### Phase 1: QualityManager Enhancements

- [ ] Add `culling_distance` to `quality_settings` for each level (800, 1000, 1200, 1500px)
- [ ] Implement `get_culling_distance() -> float` method
- [ ] Implement `get_max_enemies() -> int` method
- [ ] Test quality level transitions trigger culling distance updates

### Phase 2: Enemy Culling

- [ ] Add `_is_off_screen: bool` property to `Enemy.gd`
- [ ] Add `_distance_to_player: float` property to `Enemy.gd`
- [ ] Implement `_check_culling() -> bool` method
- [ ] Implement `_fade_out_and_despawn() -> void` method (optional, quality 2-3)
- [ ] Implement `_update_off_screen_state() -> void` method
- [ ] Call `_check_culling()` every 0.5-1.0 seconds in `_physics_process()`
- [ ] Test enemies despawn when beyond culling distance

### Phase 3: EnemySpawner Integration

- [ ] Add culling distance check before spawning
- [ ] Enforce 300 enemy hard limit using `QualityManager.get_max_enemies()`
- [ ] Integrate spawn radius with culling distance (1.5-2x relationship)
- [ ] Test spawn zones maintain "attack from all sides" feel
- [ ] Test enemies don't accumulate beyond culling distance

### Phase 4: Visual Effects Optimization

- [ ] Implement hit effect simplification (disable at level 0, reduce particles at level 1)
- [ ] Implement damage popup frequency reduction (disable at level 0, 50% at level 1)
- [ ] Test visual effects don't break gameplay feedback

### Phase 5: Testing & Tuning

- [ ] Performance test: Measure FPS with 300 enemies at each quality level
- [ ] Gameplay test: Verify "attack from all sides" feel is maintained
- [ ] Tune culling distances based on test results
- [ ] Tune spawn radius based on culling distance

## Key Integration Points

### QualityManager → Enemy

```gdscript
# In Enemy.gd _ready()
QualityManager.quality_changed.connect(_on_quality_changed)

func _on_quality_changed(level: int) -> void:
    var settings: Dictionary = QualityManager.quality_settings[level]
    set_quality_settings(settings)
    # Culling distance is accessed via QualityManager.get_culling_distance()
```

### EnemySpawner → QualityManager

```gdscript
# In EnemySpawner._on_timeout()
var max_enemies: int = QualityManager.get_max_enemies()
if PerformanceMonitor.enemy_count_total >= max_enemies:
    return  # Don't spawn

var culling_dist: float = QualityManager.get_culling_distance()
# Use culling_dist for spawn zone calculations
```

### Enemy → QualityManager (Culling)

```gdscript
# In Enemy._physics_process()
var culling_dist: float = QualityManager.get_culling_distance()
var distance: float = global_position.distance_to(_target.global_position)
if distance > culling_dist:
    _check_culling()  # Despawn enemy
```

## Testing Scenarios

### Scenario 1: 300 Enemies on Screen

**Setup**:
1. Spawn 300 enemies
2. Monitor FPS via `PerformanceMonitor`
3. Verify FPS >= 30 (minimum target)

**Expected Results**:
- FPS remains >= 30 FPS
- Physics time < 10ms
- Quality level adjusts to 0 (Critical) if FPS drops
- Simplified AI activates automatically

**Validation**:
```gdscript
# Check PerformanceMonitor logs
assert(PerformanceMonitor.current_fps >= 30.0)
assert(PerformanceMonitor.physics_time_ms < 10.0)
assert(QualityManager.current_quality == 0)  # If FPS < 30
```

---

### Scenario 2: Culling System

**Setup**:
1. Spawn enemies around player
2. Move player away from enemies
3. Monitor enemy count via `PerformanceMonitor.enemy_count_total`

**Expected Results**:
- Enemies beyond culling distance despawn
- Enemy count decreases as player moves
- No accumulation of enemies beyond culling zone

**Validation**:
```gdscript
# In Enemy._check_culling()
var distance: float = global_position.distance_to(player.global_position)
var culling_dist: float = QualityManager.get_culling_distance()
if distance > culling_dist:
    assert(enemy.is_queued_for_deletion())  # Enemy should be despawned
```

---

### Scenario 3: Quality Level Transitions

**Setup**:
1. Start with 300 enemies (FPS should drop)
2. Monitor quality level changes
3. Verify settings apply to all enemies

**Expected Results**:
- Quality level drops to 0 when FPS < 30
- Simplified AI activates for all enemies
- Animation LOD reduces to 0.5x speed
- Culling distance adjusts to 800px

**Validation**:
```gdscript
# Check QualityManager
assert(QualityManager.current_quality == 0)  # When FPS < 30
assert(QualityManager.get_culling_distance() == 800.0)

# Check Enemy settings
for enemy in get_tree().get_nodes_in_group("enemies"):
    assert(enemy._use_simplified_ai == true)  # At quality 0
```

---

### Scenario 4: Spawn Zone Management

**Setup**:
1. Spawn enemies around player
2. Move player in different directions
3. Monitor spawn zones and enemy distribution

**Expected Results**:
- Enemies spawn in circular pattern around player
- Spawn radius is 1.5-2x culling distance
- Enemies don't accumulate beyond culling zone
- "Attack from all sides" feel is maintained

**Validation**:
```gdscript
# In EnemySpawner
var spawn_radius: float = 480.0  # From config
var culling_dist: float = QualityManager.get_culling_distance()
assert(spawn_radius >= culling_dist * 1.5)  # Spawn radius should be 1.5-2x culling distance
```

---

## Performance Targets

### FPS Targets
- **Minimum**: 30 FPS with 300 enemies (quality level 0)
- **Target**: 60 FPS with fewer enemies (quality level 3)

### Physics Time Targets
- **Critical**: < 10ms (quality level 0)
- **Acceptable**: < 5ms (quality level 1-2)
- **Target**: < 2ms (quality level 3)

### Memory Targets
- **Acceptable**: < 500MB
- **Target**: < 200MB

### Enemy Count Limits
- **Hard Limit**: 300 enemies on screen (visible + culling buffer)
- **Per Quality**: 300 (level 0), 400 (level 1), 500 (level 2), 600 (level 3)

---

## Common Issues & Solutions

### Issue: Enemies Not Despawning

**Symptoms**: Enemy count accumulates beyond 300, FPS drops

**Solution**:
1. Verify `_check_culling()` is called regularly (every 0.5-1.0s)
2. Check `QualityManager.get_culling_distance()` returns correct value
3. Verify distance calculation: `global_position.distance_to(_target.global_position)`

**Debug Code**:
```gdscript
func _check_culling() -> bool:
    if _target == null:
        push_error("[Enemy] _check_culling -> target is null")
        return false
    
    var distance: float = global_position.distance_to(_target.global_position)
    var culling_dist: float = QualityManager.get_culling_distance()
    
    if debug_logs:
        print("[Enemy] _check_culling -> distance=%.1f culling=%.1f" % [distance, culling_dist])
    
    if distance > culling_dist:
        queue_free()
        return true
    return false
```

---

### Issue: Quality Level Not Adjusting

**Symptoms**: FPS drops but quality level stays at 3

**Solution**:
1. Verify `QualityManager.auto_adjust` is `true`
2. Check `QualityManager.check_interval_sec` is reasonable (0.5s)
3. Verify `PerformanceMonitor.current_fps` is being read correctly

**Debug Code**:
```gdscript
# In QualityManager
if debug_logs:
    print("[QualityManager] _check_and_adjust_quality -> fps=%.1f quality=%d" % [current_fps, current_quality])
```

---

### Issue: Spawn Zones Not Working

**Symptoms**: Enemies spawn in wrong locations or accumulate

**Solution**:
1. Verify spawn radius is 1.5-2x culling distance
2. Check `EnemySpawner` uses `QualityManager.get_max_enemies()` for limits
3. Verify spawn position calculation uses correct player position

**Debug Code**:
```gdscript
# In EnemySpawner
if debug_logs:
    print("[EnemySpawner] spawn -> radius=%.1f culling=%.1f max_enemies=%d" % 
          [spawn_radius_px, QualityManager.get_culling_distance(), QualityManager.get_max_enemies()])
```

---

## Next Steps

After completing the implementation checklist:

1. **Performance Testing**: Run performance tests with 300 enemies and measure FPS/physics time
2. **Gameplay Testing**: Verify "attack from all sides" feel is maintained
3. **Tuning**: Adjust culling distances and spawn radii based on test results
4. **Documentation**: Update `docs/perf_checklist.md` with new optimization techniques

## References

- Feature spec: `specs/007-enemy-swarm-optimization/spec.md`
- Implementation plan: `specs/007-enemy-swarm-optimization/plan.md`
- Research findings: `specs/007-enemy-swarm-optimization/research.md`
- Data model: `specs/007-enemy-swarm-optimization/data-model.md`
- API contracts: `specs/007-enemy-swarm-optimization/contracts/`
- Performance checklist: `docs/perf_checklist.md`

