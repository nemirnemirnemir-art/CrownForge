# Feature Specification: Enemy Swarm Optimization

**Feature Branch**: `007-enemy-swarm-optimization`  
**Created**: 2025-01-09  
**Status**: Clarified (ready for tasks breakdown)  
**Input**: User description: "Enemy Swarm Optimization (up to 300 2D mobs on screen)"

## Overview

Optimize game performance to support up to 300 2D enemy mobs simultaneously on screen while maintaining playable frame rates (minimum 30 FPS, target 60 FPS). This feature focuses on enemy-specific optimizations including AI simplification, animation LOD, collision optimization, and quality-based degradation.

## Context

- **Current State**: Game supports ~200-300 enemies but experiences FPS drops to 6-30 FPS under load
- **Target State**: Stable 30+ FPS with 300 enemies, 60 FPS with fewer enemies
- **Related Systems**: `QualityManager`, `Enemy.gd`, `EnemySpawner`, `PerformanceMonitor`
- **Reference**: `docs/perf_checklist.md` sections 1 (Enemy Count), 2 (Physics & Collisions), 3 (Rendering), 7 (Quality), 8 (Enemy System)

## User Scenarios & Testing

### User Story 1 - Maintain Playable FPS with 300 Enemies (Priority: P0)

As a player, I need the game to maintain playable frame rates (minimum 30 FPS) when 300 enemies are on screen so I can continue playing without severe lag.

**Acceptance Scenarios**:
1. **Given** 300 enemies are spawned, **When** game runs, **Then** FPS remains >= 30 FPS
2. **Given** 300 enemies are active, **When** player moves and fights, **Then** physics time < 10ms
3. **Given** 300 enemies are on screen, **When** quality auto-adjusts, **Then** simplified AI activates automatically

### User Story 2 - Adaptive Quality Degradation (Priority: P1)

As a player, I need visual quality to degrade gracefully when performance drops so the game remains playable even on lower-end hardware.

**Acceptance Scenarios**:
1. **Given** FPS drops below 30, **When** quality adjusts, **Then** simplified AI and animation LOD activate
2. **Given** quality level 0 is active, **When** enemies are off-screen, **Then** animations are disabled
3. **Given** quality level changes, **When** settings broadcast, **Then** all enemies receive updated settings

## Functional Requirements

### FR-001: Enemy Count Limits
- **Hard limit: 300 enemies on screen** (visible + culling buffer zone)
- Max enemy types simultaneously: 5-8 types (no hard limit on types, only on total count)
- All enemy types share same walk animation and death animation (reduces draw calls)
- Spawn rate throttles when approaching limits
- Enemy count tracked via `PerformanceMonitor.enemy_count_total`
- ⚠️ **TODO**: Determine max screen size and culling distance (distance at which enemies are considered off-screen)
- ⚠️ **TODO**: Implement enemy despawn system when enemies are far enough off-screen
- ⚠️ **TODO**: Design spawn system to create "attack from all sides" effect without accumulating hundreds/thousands off-screen

### FR-002: Simplified AI System
- Simplified AI activates at quality level 0 or when enemy count >= 200
- Simplified AI skips neighbor cache, steering, and soft constraints
- Simplified AI uses direct movement toward target only

### FR-003: Animation LOD
- All enemy types share same walk animation (optimization: single SpriteFrames resource)
- Death animation shared across types (to be determined)
- **MANDATORY for on-screen enemies**: sprite, flip_h (direction), walk animation (cannot be disabled)
- Level 0: Animation speed reduced to 0.5x (but still active)
- Level 1: Animation speed reduced to 0.5x
- Level 2: Animation speed reduced to 0.5x
- Level 3: Full animation speed (1.0x)
- ⚠️ **TODO**: Performance test to determine if walk animation can be stopped at level 0 without breaking gameplay

### FR-004: Off-screen Simplification & Culling
- Enabled at quality levels 0-2
- Off-screen enemies disable animations and reduce processing
- Off-screen enemies use simplified AI
- On-screen enemies: sprite, flip_h, walk animation always active (mandatory)
- ⚠️ **TODO**: Define culling zone (buffer distance beyond screen bounds)
- ⚠️ **TODO**: Implement enemy despawn when beyond culling zone (to prevent accumulation)
- ⚠️ **TODO**: Design spawn zones around player to maintain "attack from all sides" feel
- ⚠️ **TODO**: Test and tune culling distance to balance performance vs. gameplay feel

### FR-005: Visual Effects Optimization
- Hit effects (particles/sprites on damage): Can be disabled or simplified at quality levels 0-1
- Damage popups (numbers): Can be disabled or simplified at quality levels 0-1
- ⚠️ **TODO**: Performance test to determine optimal simplification levels for hit effects and damage popups
- ⚠️ **TODO**: Break down into smaller tasks for visual testing (test each effect separately)

### FR-006: Physics Optimization
- Neighbor cache update interval increases with enemy count (0.12s base, 0.28s crowded, 0.5s very crowded)
- Simplified AI disables neighbor cache completely
- Collision monitoring disabled for off-screen enemies

## Non-Functional Requirements

### NFR-001: Performance Targets
- **FPS**: Minimum 30 FPS with 300 enemies, target 60 FPS with fewer enemies
- **Physics Time**: < 10ms critical, < 5ms acceptable, < 2ms target
- **Memory**: < 500MB acceptable, < 200MB target

### NFR-002: Quality Level Thresholds
- Quality 0 (Critical): FPS < 30
- Quality 1 (Low): FPS 30-45
- Quality 2 (Medium): FPS 45-55
- Quality 3 (High): FPS >= 55

## Data Model

### Enemy Quality Settings
```gdscript
{
    "animation_lod": int,  # 0=full, 1=reduced, 2=minimal
    "simplified_ai": bool,  # Skip complex AI calculations
    "neighbor_limit": int,  # Max neighbors for steering (3-11)
    "off_screen_simplification": bool  # Simplify off-screen enemies
}
```

### Quality Level Configuration
- Level 0: `animation_lod=2`, `simplified_ai=true`, `neighbor_limit=3`
- Level 1: `animation_lod=1`, `simplified_ai=false`, `neighbor_limit=5`
- Level 2: `animation_lod=1`, `simplified_ai=false`, `neighbor_limit=8`
- Level 3: `animation_lod=0`, `simplified_ai=false`, `neighbor_limit=11`

## Edge Cases

- **EC-001**: What if enemy count exceeds 300 but FPS is still good? (Answer: Allow but monitor)
- **EC-002**: What if simplified AI causes visual issues? (Answer: Ensure sprite flip_h still updates - **FIXED**: `_update_anim(velocity)` called in simplified AI)
- **EC-003**: What if quality switches rapidly? (Answer: Use history smoothing with 5 samples)
- **EC-004**: What if disabling hit effects/damage popups breaks player feedback? (Answer: ⚠️ **TODO**: Visual testing required)

## Open Questions / Requires Testing

### Visual Effects Testing
- **TBD-001**: Can walk animation be stopped at quality level 0 without breaking gameplay? (Currently set to 0.5x speed)
- **TBD-002**: What is the optimal simplification level for hit effects? (Disable completely vs. reduce particle count vs. simpler sprite)
- **TBD-003**: What is the optimal simplification level for damage popups? (Disable vs. reduce frequency vs. simpler rendering)
- **TBD-004**: Performance test plan: Test each visual effect separately to measure FPS impact
- **TBD-005**: Break down visual optimization into smaller tasks for iterative testing

### Culling & Spawn System (⚠️ Requires Analysis & Testing)
- **TBD-006**: What is the maximum screen size to consider for culling calculations? (Viewport size? Fixed buffer? Camera zoom?)
- **TBD-007**: What is the optimal culling distance? (Distance beyond screen bounds where enemies are despawned)
- **TBD-008**: How to implement despawn system? (Immediate despawn? Gradual fade? Queue for next spawn?)
- **TBD-009**: How to design spawn zones to maintain "attack from all sides" feel without accumulating enemies?
- **TBD-010**: Performance test: Measure FPS impact of different culling distances and spawn strategies
- **TBD-011**: Gameplay test: Verify that culling/despawn doesn't break immersion or create visual glitches
- **TBD-012**: Break down culling/spawn system into smaller implementation tasks

## Out of Scope

- Projectile optimization (covered in separate feature)
- Damage popup optimization (covered in separate feature)
- Rendering optimizations beyond enemy-specific (covered in perf_checklist.md section 3)

## Clarifications

### Session 2025-01-09

- Q: Сколько типов врагов и анимаций одновременно допускается на экране? → A: 5-8 видов врагов, все используют одну анимацию walk и анимацию смерти (которую определим позже)

- Q: Что нельзя отключать визуально? → A: Враг на экране видимости: нельзя отключать flip, walk, спрайт. Можно отключить/упростить эффект попадания или цифры урона (damage popups). ⚠️ **ТРЕБУЕТСЯ УТОЧНЕНИЕ/ТЕСТИРОВАНИЕ**: Нужно определить разбитие на более мелкие таски либо провести тест производительности, где будут убираться/ослабляться определенные моменты для визуального теста.

- Q: Жесткие лимиты для каждого уровня качества? → A: 300 врагов на экране. ⚠️ **ТРЕБУЕТСЯ УТОЧНЕНИЕ/РАЗБИТИЕ НА ТАСКИ + АНАЛИЗ/ТЕСТЫ**: Нужно определить максимальный размер экрана и расстояние, при котором мобы не попадают в экран. Определить момент их удаления из игры, если их не видно. Цель: создать эффект, что мобы нападают со всех сторон, куда бы ты не пошел, но не копятся сотнями и тысячами за экраном.

- Q: Требования к качеству для каждого уровня? → A: Option B - Минимальные требования к FPS: Level 0 >= 30 FPS, Level 1 >= 45 FPS, Level 2 >= 55 FPS, Level 3 >= 60 FPS (соответствует NFR-002)

