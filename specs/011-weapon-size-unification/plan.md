# Implementation Plan: Weapon Size Unification - Phase 7

**Branch**: `011-weapon-size-unification` | **Date**: 2025-11-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-weapon-size-unification/spec.md`

**Note**: This plan focuses on Phase 7 (Testing) of the weapon size unification feature. Previous phases (1-6) have been completed.

## Summary

Phase 7 implements comprehensive testing for all 20 weapons to verify unified size behavior. The goal is to ensure that:
- All weapons use the unified size formula: `scale_factor = 1.0 + size_level * 0.05`
- Visual sprites and collision shapes match in both 2D editor and runtime
- No accumulation bugs remain (size doesn't grow on respawn/restart)
- All tome effects (Size, Count, Pierce) are properly documented for each weapon

**Technical Approach**: Manual testing with debug logging, systematic documentation of results, and immediate fixes for critical bugs.

## Technical Context

**Language/Version**: GDScript (Godot 4.3)  
**Primary Dependencies**: Godot Engine 4.3, existing weapon system (`WeaponConfig`, `Projectile`, `NormalizedWeaponController`)  
**Storage**: `.tres` resource files for weapon configs, `.tscn` scene files for projectiles  
**Testing**: Manual testing in-game with debug logs, visual inspection, collision verification  
**Target Platform**: Windows (Godot 4.3)  
**Project Type**: Single game project (Godot 4.3 roguelike)  
**Performance Goals**: No performance impact (size calculation is O(1) per projectile)  
**Constraints**: 
- Must not change damage/speed/fire rate balance
- Must not modify base art (PNG) sizes, only scale and collisions
- Must preserve existing weapon behavior except for size scaling
**Scale/Scope**: 20 weapons to test, 3 tome types (Size, Count, Pierce) per weapon

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Gate 1: No Synthesis/Hallucinations
**Status**: PASS  
**Rationale**: Phase 7 is testing phase - no new code synthesis required, only verification of existing implementation

### ✅ Gate 2: Strict Typing (Godot 4.3)
**Status**: PASS  
**Rationale**: All existing code already uses strict typing. Testing phase doesn't introduce new code.

### ✅ Gate 3: Modifier Recalculation (Principle VI)
**Status**: PASS  
**Rationale**: Previous phases (1-6) already implemented recalculation from base values. Phase 7 verifies this works correctly.

### ✅ Gate 4: Editor Synchronization
**Status**: PASS  
**Rationale**: Phase 6 already fixed editor synchronization. Phase 7 verifies it works.

### ✅ Gate 5: Documentation
**Status**: PASS  
**Rationale**: Phase 7 explicitly requires documentation of test results and tome effects.

**Overall Status**: ✅ ALL GATES PASSED

## Project Structure

### Documentation (this feature)

```text
specs/011-weapon-size-unification/
├── plan.md                    # This file (/speckit.plan command output)
├── spec.md                    # Feature specification
├── research.md                # Phase 0 output (completed)
├── data-model.md             # Phase 1 output (completed)
├── inventory.md              # Task 1 output (completed)
├── quickstart.md             # Phase 1 output (completed)
├── contracts/                # Phase 1 output (completed)
│   └── weapon-size-api.md
├── tasks.md                 # Phase 2 output (completed)
├── weapon-test-list.md       # Phase 7: Test tracking
├── phase7-test-results.md    # Phase 7: Detailed test reports (to be created)
└── 20_weapons_ready_to_go.md # Phase 7: Completion document (to be created)
```

### Source Code (repository root)

```text
gameplay/
├── weapons/
│   ├── WeaponConfig.gd       # Extended with size_level field
│   ├── Projectile.gd         # Base class with unified size system
│   ├── Arrow.tres            # Weapon configs (20 total)
│   ├── ArrowNormalized.tres
│   ├── [18 more weapon configs]
│   └── [weapon-specific projectile scripts]
│       ├── ArrowProjectile.gd
│       ├── AuraWeaponProjectile.gd
│       ├── BoulderWeaponProjectile.gd
│       └── [17 more projectile scripts]
├── player/
│   └── NormalizedWeaponController.gd  # Weapon firing controller
└── tomes/
    ├── TomeSize.gd           # Size tome effect
    ├── TomeCount.gd          # Count tome effect
    ├── TomePierce.gd         # Pierce tome effect
    └── TomeMods.gd           # Tome modifiers resource
```

**Structure Decision**: Existing Godot 4.3 project structure. Phase 7 adds documentation files only, no code changes (except bug fixes found during testing).

## Complexity Tracking

> **No violations detected - all gates passed**

## Phase 0: Research (COMPLETED)

All research tasks from initial implementation have been completed. See `research.md` for details.

**Key Decisions**:
- Automatic weapon discovery via project structure scanning
- `size_level` stored in `.tres` config files
- Individual node mapping per weapon
- Separate `size_level` from other modifiers
- Fix accumulation bugs before applying new system

## Phase 1: Design & Contracts (COMPLETED)

Data model and API contracts have been defined. See `data-model.md` and `contracts/weapon-size-api.md` for details.

**Key Artifacts**:
- Extended `WeaponConfig` with `size_level` field
- Extended `Projectile` with base value storage and size application methods
- Unified size calculation formula: `scale_factor = 1.0 + size_level * 0.05`
- Metadata-based base value storage to prevent accumulation

## Phase 2: Implementation (COMPLETED)

All implementation phases (1-6) have been completed:
- Phase 1: Setup - Added `size_level` to `WeaponConfig`, base values to `Projectile`
- Phase 2: Foundational - Added `_store_base_values()` and `_apply_size_scale()` methods
- Phase 3: Inventory - Documented all 20 weapons
- Phase 4: Bug Fixes - Fixed accumulation bugs in all weapons
- Phase 5: Unified System - Implemented unified size system for all weapons
- Phase 6: Editor Sync - Fixed `_ready()` methods to preserve editor settings

## Phase 7: Testing (CURRENT)

**Goal**: Verify unified behavior across all 20 weapons with manual testing

### Test Execution Strategy

1. **Test Environment**: In-game testing with debug logs enabled
2. **Test Order**: 
   - Priority 1: Weapons with `[yes]` status for all tome types (8 weapons)
   - Priority 2: Weapons with `[clarify]` status (12 weapons)
3. **Test Cases per Weapon**:
   - Base level (size_level = 0): Visual and collision match
   - Multiple spawns: No accumulation (10 spawns = same size)
   - Size upgrades: Proportional increase (0 → 1 → 2 → ...)
   - Tome effects: Document how Size, Count, Pierce tomes affect the weapon

### Documentation Requirements

1. **weapon-test-list.md**: Update with test results (`[yes]` → `[pass]`, `[clarify]` → `[fail]`/`[fixed]`)
2. **phase7-test-results.md**: Detailed reports per weapon (logs, screenshots, bugs found, fixes applied)
3. **20_weapons_ready_to_go.md**: Final completion document confirming all 20 weapons are ready

### Bug Handling

- **Critical bugs** (accumulation, visual/collision desync): Fix immediately
- **Non-critical bugs** (visual artifacts): Document for post-Phase 7 fixes

### Completion Criteria

Phase 7 is complete when:
- ✅ All 20 weapons tested
- ✅ All critical bugs fixed
- ✅ Results documented in `weapon-test-list.md` and `phase7-test-results.md`
- ✅ Tome effects documented for all weapons (Size, Count, Pierce)
- ✅ `20_weapons_ready_to_go.md` created

## Next Steps

1. Begin systematic testing of all 20 weapons
2. Document results in `weapon-test-list.md` and `phase7-test-results.md`
3. Fix critical bugs as they are discovered
4. Create `20_weapons_ready_to_go.md` upon completion
