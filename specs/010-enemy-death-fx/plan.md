# Implementation Plan: Enemy Death FX v1 — Hybrid LOD + Pooling

**Branch**: `010-enemy-death-fx` | **Date**: 2025-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-enemy-death-fx/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a unified enemy death pipeline with hybrid LOD (near/far behavior) and optional pooling. Near deaths use shader-based dissolve FX on enemy sprite for minimal FPS impact (1 draw call). Far deaths use fast alpha fade-out (0.1–0.2 sec). System enforces hard cap on simultaneous "nice" FX (max 30) to prevent FPS drops during mass death scenarios. Enemy pooling is optional in v1 (can start with `queue_free()`, add pooling later).

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: Godot 4.3 engine, existing systems:
- `HealthComponent` (death signal: `died`)
- `Enemy.gd` base class (AI, movement, status effects)
- `EnemySpawner` (spawn management)
- `ProjectilePool` (reference pattern for future enemy pooling)

**Storage**: N/A (runtime only, no persistence)  
**Testing**: Godot 4.3 built-in testing (optional, manual testing for FX visuals)  
**Target Platform**: Godot 4.3 (Windows/Linux/Mac, desktop focus)  
**Project Type**: Game (top-down 2D roguelike auto-shooter)  
**Performance Goals**: 
- 60 FPS target
- Dozens of simultaneous deaths without noticeable FPS drops
- No GC spikes from constant `queue_free()/instantiate()` (when pooling added)

**Constraints**: 
- Max 30 active "nice" death FX (hard cap, mandatory)
- Shader-based FX only (no separate nodes to minimize draw calls)
- LOD decision made once per death event (no per-frame switching)
- All configurable constants in single configuration module

**Scale/Scope**: 
- All enemy types in game (Zombie, Skeleton, Werewolf, etc.)
- Centralized death handling (one module/class)
- Integration with existing loot drop, XP, kill counter systems

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Principle I: Documentation Hierarchy
- **Status**: PASS
- **Check**: Spec exists, plan follows template, will generate research.md, data-model.md, contracts/, quickstart.md
- **Notes**: Will reference `docs/MAIN_ORIENTATION_THELASTONE.md` for detailed rules

### ✅ Principle II: Godot 4.3 Strict Typing
- **Status**: PASS
- **Check**: All new `.gd` files will use explicit type annotations (no `Variant` inference)
- **Notes**: `EnemyDeathController`, shader material access, Tween callbacks must be typed

### ✅ Principle III: Code Style & Formatting
- **Status**: PASS
- **Check**: Tab indentation, LF line endings, `.editorconfig` compliance
- **Notes**: Will use `scripts/Fix-Indents.ps1` if needed

### ✅ Principle IV: Debug Logging System
- **Status**: PASS
- **Check**: `@export var debug_logs: bool = false` in `EnemyDeathController` and related nodes
- **Notes**: Log death events, LOD decisions, FX cap enforcement

### ✅ Principle V: Damage Calculation Order
- **Status**: N/A (not modifying damage calculation)
- **Check**: Death FX system does not change damage pipeline
- **Notes**: Reuses existing `HealthComponent.apply_damage()` → `died` signal

### ✅ Principle VI: Modifier Recalculation
- **Status**: PASS
- **Check**: Shader uniforms reset on enemy reuse (if pooling added later)
- **Notes**: Death FX state must be reset: `dissolve_progress = 0.0`, `modulate.a = 1.0`

### ✅ Principle VII: Project Validation
- **Status**: PASS
- **Check**: Will run `godot --headless --check-only` before completion
- **Notes**: All new code must pass type checking

**Overall Gate Status**: ✅ **PASS** — All principles satisfied, no violations detected.

## Project Structure

### Documentation (this feature)

```text
specs/010-enemy-death-fx/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
gameplay/
├── enemies/
│   ├── Enemy.gd                    # Existing: base enemy class
│   ├── EnemyDeathController.gd     # NEW: centralized death handling
│   └── EnemyDeathConfig.gd         # NEW: configuration resource
│
├── systems/
│   └── [future: EnemyPool.gd]      # Phase 2: optional pooling (not in v1)
│
shaders/
└── enemy_death_dissolve.gdshader   # NEW: dissolve shader for "nice" FX

autoload/
└── [future: EnemyPool.gd]         # Phase 2: optional autoload pool (not in v1)
```

**Structure Decision**: 
- Death controller lives in `gameplay/enemies/` alongside `Enemy.gd` for logical grouping
- Shader in `shaders/` directory (create if missing) for centralized shader management
- Configuration resource (`EnemyDeathConfig.gd`) follows existing pattern (e.g., `WeaponConfig`, `EnemySpawnConfig`)
- Future pooling can be autoload or system component (decision deferred to Phase 2)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | No violations detected | All principles satisfied |
