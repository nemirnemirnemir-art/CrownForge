# Implementation Plan: Enemy Swarm Optimization

**Branch**: `007-enemy-swarm-optimization` | **Date**: 2025-01-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-enemy-swarm-optimization/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Optimize game performance to support up to 300 2D enemy mobs simultaneously on screen while maintaining playable frame rates (minimum 30 FPS, target 60 FPS). This feature focuses on enemy-specific optimizations including AI simplification, animation LOD, collision optimization, quality-based degradation, and culling/despawn systems. Key technical approach: integrate with existing `QualityManager` and `PerformanceMonitor` systems, enhance `Enemy.gd` with simplified AI mode, implement culling system for off-screen enemies, and optimize visual effects based on quality levels.

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: 
- `QualityManager` (autoload) - adaptive quality management
- `PerformanceMonitor` (autoload) - FPS, entity counts, physics time tracking
- `Enemy.gd` (base class) - enemy AI and behavior
- `EnemySpawner` - enemy spawning system
- `DamagePopupPool` (autoload) - object pooling for damage popups
- `ProjectilePool` (autoload) - object pooling for projectiles

**Storage**: N/A (runtime-only optimizations)  
**Testing**: Manual testing with performance profiling, Godot profiler, `PerformanceMonitor` logs  
**Target Platform**: Desktop (Windows/Linux/Mac) via Godot 4.3  
**Project Type**: Single project (2D roguelike game)  
**Performance Goals**: 
- Minimum 30 FPS with 300 enemies on screen
- Target 60 FPS with fewer enemies
- Physics time < 10ms critical, < 5ms acceptable, < 2ms target
- Memory < 500MB acceptable, < 200MB target

**Constraints**: 
- Must maintain gameplay feel ("attack from all sides" effect)
- Cannot disable sprite, flip_h, walk animation for on-screen enemies
- Must integrate with existing `QualityManager` quality levels (0-3)
- Hard limit: 300 enemies on screen (visible + culling buffer zone)

**Scale/Scope**: 
- 5-8 enemy types simultaneously (all share same walk/death animations)
- Up to 300 enemies on screen
- Quality levels: 0 (Critical), 1 (Low), 2 (Medium), 3 (High)

**Open Questions (NEEDS CLARIFICATION via research)**:
- TBD-006: Maximum screen size for culling calculations (Viewport size? Fixed buffer? Camera zoom?)
- TBD-007: Optimal culling distance (distance beyond screen bounds where enemies are despawned)
- TBD-008: Despawn system implementation (Immediate despawn? Gradual fade? Queue for next spawn?)
- TBD-009: Spawn zone design to maintain "attack from all sides" feel without accumulating enemies
- TBD-001: Can walk animation be stopped at quality level 0 without breaking gameplay?
- TBD-002: Optimal simplification level for hit effects (disable vs. reduce particles vs. simpler sprite)
- TBD-003: Optimal simplification level for damage popups (disable vs. reduce frequency vs. simpler rendering)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Compliance

✅ **I. Documentation Hierarchy**: Following `.cursorrules` → `main.md` → `MAIN_ORIENTATION_THELASTONE.md` hierarchy. Feature spec references `docs/perf_checklist.md` for related optimizations.

✅ **II. Godot 4.3 Strict Typing**: All GDScript files must be strictly typed. No `Variant` inference. All `var` declarations must have explicit type annotations.

✅ **III. Code Style & Formatting**: Using soft tabs (tab character), LF line endings. `.editorconfig` must be followed.

✅ **IV. Debug Logging System**: Using `@export var debug_logs: bool` pattern. `PerformanceMonitor` already implements this.

✅ **V. Damage Calculation Order**: Not applicable (this feature doesn't modify damage calculation).

✅ **VI. Modifier Recalculation**: Not applicable (this feature doesn't add new modifiers).

✅ **VII. Project Validation**: Must run `godot --headless --check-only` before commit. All changes must pass validation.

### Architecture Compliance

✅ **System Integration**: Feature integrates with existing systems (`QualityManager`, `PerformanceMonitor`, `Enemy.gd`, `EnemySpawner`) without breaking changes.

✅ **File Structure**: Changes fit within existing structure:
- `autoload/QualityManager.gd` - enhancements
- `gameplay/enemies/Enemy.gd` - simplified AI mode
- `gameplay/enemies/EnemySpawner.gd` - culling/despawn integration
- New files (if needed) in appropriate directories

✅ **Complexity Justification**: Feature adds optimizations but doesn't introduce new architectural patterns. Changes are incremental enhancements to existing systems.

**Gate Status**: ✅ **PASS** - All constitution principles satisfied. Proceed to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
autoload/
├── QualityManager.gd          # Enhance: culling settings, enemy count limits
└── PerformanceMonitor.gd     # Already tracks enemy_count_total

gameplay/enemies/
├── Enemy.gd                    # Enhance: simplified AI mode (already partially implemented)
├── EnemySpawner.gd            # Enhance: culling/despawn integration, spawn zone management
└── EnemySpawnConfig.gd         # May need: culling distance settings

# New files (if needed):
gameplay/systems/
└── CullingManager.gd          # Optional: dedicated culling system (if not integrated into EnemySpawner)

# Testing/Profiling:
scripts/
└── Test-EnemySwarm.ps1        # Optional: performance test script
```

**Structure Decision**: Single project structure maintained. Changes are enhancements to existing files in `autoload/` and `gameplay/enemies/`. No new major systems required - feature integrates with existing `QualityManager` and `EnemySpawner` systems. Optional `CullingManager` may be created if culling logic becomes too complex for `EnemySpawner`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. All changes are incremental enhancements to existing systems.

---

## Phase 0 & 1 Completion Report

**Date**: 2025-01-09  
**Status**: ✅ Complete

### Phase 0: Research (Complete)

**Output**: `research.md`

**Research Questions Resolved**:
- ✅ TBD-006: Maximum screen size for culling calculations → Viewport size with configurable buffer multiplier
- ✅ TBD-007: Optimal culling distance → Quality-dependent distances (800-1500px)
- ✅ TBD-008: Despawn system implementation → Immediate despawn with optional fade
- ✅ TBD-009: Spawn zone design → Dynamic spawn zones around player, 1.5-2x culling distance
- ✅ TBD-001: Walk animation at quality level 0 → Keep at 0.5x speed (no stopping)
- ✅ TBD-002: Optimal simplification for hit effects → Quality-dependent (disable/reduce/full)
- ✅ TBD-003: Optimal simplification for damage popups → Quality-dependent (disable/reduce frequency/full)

**All open questions resolved. No remaining NEEDS CLARIFICATION items.**

### Phase 1: Design & Contracts (Complete)

**Outputs**:
- ✅ `data-model.md` - Data structures, entities, relationships, state transitions
- ✅ `contracts/quality-manager-api.md` - QualityManager API enhancements
- ✅ `contracts/enemy-culling-api.md` - Enemy culling API contract
- ✅ `quickstart.md` - Implementation checklist, testing scenarios, common issues

**Design Artifacts**:
- Data model defines: Enemy Quality Settings, Culling State, Spawn Zone Configuration, Culling Zone Calculation
- API contracts define: QualityManager enhancements, Enemy culling methods, integration points
- Quick start provides: Step-by-step implementation checklist, testing scenarios, performance targets

**Agent Context Updated**: ✅ Cursor IDE context file updated with GDScript (Godot 4.3) technology.

### Constitution Check (Post-Design)

**Re-evaluation**: ✅ **PASS** - All constitution principles still satisfied after Phase 1 design.

**No new violations introduced. Design artifacts comply with all principles.**

---

## Next Steps

**Ready for Phase 2**: `/speckit.tasks` command to break down implementation into tasks.

**Generated Artifacts**:
- `specs/007-enemy-swarm-optimization/plan.md` (this file)
- `specs/007-enemy-swarm-optimization/research.md`
- `specs/007-enemy-swarm-optimization/data-model.md`
- `specs/007-enemy-swarm-optimization/quickstart.md`
- `specs/007-enemy-swarm-optimization/contracts/quality-manager-api.md`
- `specs/007-enemy-swarm-optimization/contracts/enemy-culling-api.md`

**Branch**: `007-enemy-swarm-optimization`  
**IMPL_PLAN Path**: `specs/007-enemy-swarm-optimization/plan.md`
