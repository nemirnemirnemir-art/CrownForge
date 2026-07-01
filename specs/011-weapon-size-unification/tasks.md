# Tasks: Weapon Size Unification

**Input**: Design documents from `/specs/011-weapon-size-unification/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Manual testing via Debug scenes (no automated test tasks - manual verification required per spec)

**Organization**: Tasks are organized by implementation phases (Task 1-5 from spec) to ensure correct execution order.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which task phase this belongs to (T1, T2, T3, T4, T5)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `gameplay/weapons/` at repository root
- Weapon configs: `gameplay/weapons/*.tres`
- Weapon scenes: `gameplay/weapons/*Projectile.tscn`
- Weapon scripts: `gameplay/weapons/*Projectile.gd` and `gameplay/weapons/Projectile.gd`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare base classes for size system extension

- [ ] T001 Add `size_level: int = 0` field to `WeaponConfig` class in `gameplay/weapons/WeaponConfig.gd`
- [ ] T002 Add base value storage fields to `Projectile` class in `gameplay/weapons/Projectile.gd`: `_base_visual_scale: Vector2`, `_base_collider_scale: Vector2`, `_base_collider_size: Variant`, `_size_level: int`, `_other_size_modifiers: float`
- [ ] T003 Add `SIZE_STEP: float = 0.05` constant to `Projectile` class in `gameplay/weapons/Projectile.gd`

**Checkpoint**: Base classes extended with size system fields

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before weapon-specific work

**⚠️ CRITICAL**: No weapon-specific work can begin until this phase is complete

- [ ] T004 Add `_store_base_values() -> void` method stub to `Projectile` class in `gameplay/weapons/Projectile.gd` (implementation will be per-weapon)
- [ ] T005 Add `_apply_size_scale(scale_factor: float) -> void` method stub to `Projectile` class in `gameplay/weapons/Projectile.gd` (implementation will be per-weapon)
- [ ] T006 Update `Projectile.setup()` method signature in `gameplay/weapons/Projectile.gd` to read `size_level` from config and calculate `scale_factor`

**Checkpoint**: Foundation ready - weapon inventory and implementation can now begin

---

## Phase 3: Task 1 - Weapon Inventory (Priority: P1) 🎯 MVP

**Goal**: Document current state of all 20 weapons: visual nodes, collision nodes, and current scale logic

**Independent Test**: Inventory document exists with all 20 weapons documented, showing visual nodes, collider nodes, and current scale logic patterns

### Implementation for Task 1

- [ ] T007 [P] [T1] Scan `gameplay/weapons/` directory and list all `.tres` files (WeaponConfig resources)
- [ ] T008 [P] [T1] For each weapon config, identify corresponding `.tscn` file (projectile scene) in `gameplay/weapons/`
- [ ] T009 [P] [T1] For Arrow weapon: Document visual nodes and collision nodes in `gameplay/weapons/Arrow.tres` and corresponding scene/script
- [ ] T010 [P] [T1] For AuraWeapon: Document visual nodes and collision nodes in `gameplay/weapons/AuraWeapon.tres` and corresponding scene/script
- [ ] T011 [P] [T1] For Banana weapon: Document visual nodes and collision nodes in `gameplay/weapons/Banana.tres` and corresponding scene/script
- [ ] T012 [P] [T1] For BoulderWeapon: Document visual nodes and collision nodes in `gameplay/weapons/BoulderWeapon.tres` and corresponding scene/script
- [ ] T013 [P] [T1] For BubbleWeapon: Document visual nodes and collision nodes in `gameplay/weapons/BubbleWeapon.tres` and corresponding scene/script
- [ ] T014 [P] [T1] For ChainLighting: Document visual nodes and collision nodes in `gameplay/weapons/ChainLighting.tres` and corresponding scene/script
- [ ] T015 [P] [T1] For ChaosAround: Document visual nodes and collision nodes in `gameplay/weapons/ChaosAround.tres` and corresponding scene/script
- [ ] T016 [P] [T1] For DroneWeapon: Document visual nodes and collision nodes in `gameplay/weapons/DroneWeapon.tres` and corresponding scene/script
- [ ] T017 [P] [T1] For FireBallWeapon: Document visual nodes and collision nodes in `gameplay/weapons/FireBallWeapon.tres` and corresponding scene/script
- [ ] T018 [P] [T1] For FrozenCloud: Document visual nodes and collision nodes in `gameplay/weapons/FrozenCloud.tres` and corresponding scene/script
- [ ] T019 [P] [T1] For LaserSkyWeapon: Document visual nodes and collision nodes in `gameplay/weapons/LaserSkyWeapon.tres` and corresponding scene/script
- [ ] T020 [P] [T1] For MinesWeapon: Document visual nodes and collision nodes in `gameplay/weapons/MinesWeapon.tres` and corresponding scene/script
- [ ] T021 [P] [T1] For PingPongWeapon: Document visual nodes and collision nodes in `gameplay/weapons/PingPongWeapon.tres` and corresponding scene/script
- [ ] T022 [P] [T1] For Poisonflask: Document visual nodes and collision nodes in `gameplay/weapons/Poisonflask.tres` and corresponding scene/script
- [ ] T023 [P] [T1] For Saw: Document visual nodes and collision nodes in `gameplay/weapons/Saw.tres` and corresponding scene/script
- [ ] T024 [P] [T1] For Shotgun: Document visual nodes and collision nodes in `gameplay/weapons/Shotgun.tres` and corresponding scene/script
- [ ] T025 [P] [T1] For Shuriken: Document visual nodes and collision nodes in `gameplay/weapons/Shuriken.tres` and corresponding scene/script
- [ ] T026 [P] [T1] For SwingAttack: Document visual nodes and collision nodes in `gameplay/weapons/SwingAttack.tres` and corresponding scene/script
- [ ] T027 [P] [T1] For SwordToTheMouse: Document visual nodes and collision nodes in `gameplay/weapons/SwordToTheMouse.tres` and corresponding scene/script
- [ ] T028 [P] [T1] For WeaponCircle: Document visual nodes and collision nodes in `gameplay/weapons/WeaponCircle.tres` and corresponding scene/script
- [ ] T029 [T1] Create inventory document in `specs/011-weapon-size-unification/inventory.md` with table: `weapon_name | visual_nodes | collider_nodes | current_scale_logic`

**Checkpoint**: All 20 weapons documented with visual nodes, collision nodes, and current scale logic patterns

---

## Phase 4: Task 3 - Fix Accumulation Bugs (Priority: P1) 🎯 MVP

**Goal**: Remove all `scale *=` patterns and restore base value logic BEFORE implementing unified system

**Independent Test**: Search for `scale *=`, `size *=`, `radius *=` patterns - all should be replaced with base-based calculation. No accumulation on respawn.

**⚠️ CRITICAL**: This phase MUST complete before Phase 5 (Unified System) to avoid conflicts

### Implementation for Task 3

- [ ] T030 Search for all `scale *=` patterns in `gameplay/weapons/` directory
- [ ] T031 Search for all `size *=` patterns in `gameplay/weapons/` directory
- [ ] T032 Search for all `radius *=` patterns in `gameplay/weapons/` directory
- [ ] T033 [P] [T3] Fix accumulation bug in `gameplay/weapons/Projectile.gd` (lines 201-204: `spr.scale = Vector2(spr.scale.x * k.x, spr.scale.y * k.y)`)
- [ ] T034 [P] [T3] Fix accumulation bug in `gameplay/weapons/LaserSkyProjectile.gd` (lines 138, 161: scale application)
- [ ] T035 [P] [T3] Fix accumulation bug in `gameplay/weapons/ChaosAroundOrb.gd` (line 92: `_sprite.scale = _base_sprite_scale * scale_vec`)
- [ ] T036 [P] [T3] Fix accumulation bug in `gameplay/weapons/BoulderWeaponProjectile.gd` (line 585: `_visual_sprite.scale = _base_sprite_scale * scale_vec`)
- [ ] T037 [P] [T3] Fix accumulation bug in `gameplay/weapons/PoisonflaskProjectile.gd` (line 307: `node2d.scale = node2d.scale * Vector2(_size_scale, _size_scale)`)
- [ ] T038 [P] [T3] Review and fix any accumulation patterns in `gameplay/weapons/DroneShot.gd`
- [ ] T039 [P] [T3] Review and fix any accumulation patterns in `gameplay/weapons/MinesWeaponProjectile.gd`
- [ ] T040 [T3] Verify all `_ready()` methods restore base values before applying modifiers in all weapon scripts

**Checkpoint**: All accumulation bugs fixed, base values stored and restored correctly

---

## Phase 5: Task 2 - Unified Size System (Priority: P1) 🎯 MVP

**Goal**: Implement unified size calculation system for all 20 weapons using formula `scale_factor = (1.0 + size_level * 0.05) * other_modifiers`

**Independent Test**: All weapons use unified formula, visual and collision scale proportionally, no accumulation on respawn

### Implementation for Task 2

- [ ] T041 [T2] Update `Projectile.setup()` in `gameplay/weapons/Projectile.gd` to read `size_level` from config and calculate `scale_factor`
- [ ] T042 [P] [T2] Implement `_store_base_values()` for Arrow weapon in corresponding projectile script
- [ ] T043 [P] [T2] Implement `_apply_size_scale()` for Arrow weapon in corresponding projectile script
- [ ] T044 [P] [T2] Implement `_store_base_values()` for AuraWeapon in `gameplay/weapons/AuraWeaponProjectile.gd`
- [ ] T045 [P] [T2] Implement `_apply_size_scale()` for AuraWeapon in `gameplay/weapons/AuraWeaponProjectile.gd`
- [ ] T046 [P] [T2] Implement `_store_base_values()` for Banana weapon in corresponding projectile script
- [ ] T047 [P] [T2] Implement `_apply_size_scale()` for Banana weapon in corresponding projectile script
- [ ] T048 [P] [T2] Implement `_store_base_values()` for BoulderWeapon in `gameplay/weapons/BoulderWeaponProjectile.gd`
- [ ] T049 [P] [T2] Implement `_apply_size_scale()` for BoulderWeapon in `gameplay/weapons/BoulderWeaponProjectile.gd`
- [ ] T050 [P] [T2] Implement `_store_base_values()` for BubbleWeapon in `gameplay/weapons/BubbleProjectile.gd`
- [ ] T051 [P] [T2] Implement `_apply_size_scale()` for BubbleWeapon in `gameplay/weapons/BubbleProjectile.gd`
- [ ] T052 [P] [T2] Implement `_store_base_values()` for ChainLighting in corresponding projectile script
- [ ] T053 [P] [T2] Implement `_apply_size_scale()` for ChainLighting in corresponding projectile script
- [ ] T054 [P] [T2] Implement `_store_base_values()` for ChaosAround in `gameplay/weapons/ChaosAroundOrb.gd`
- [ ] T055 [P] [T2] Implement `_apply_size_scale()` for ChaosAround in `gameplay/weapons/ChaosAroundOrb.gd`
- [ ] T056 [P] [T2] Implement `_store_base_values()` for DroneWeapon in `gameplay/weapons/DroneWeaponProjectile.gd`
- [ ] T057 [P] [T2] Implement `_apply_size_scale()` for DroneWeapon in `gameplay/weapons/DroneWeaponProjectile.gd`
- [ ] T058 [P] [T2] Implement `_store_base_values()` for FireBallWeapon in `gameplay/weapons/FireBallProjectile.gd`
- [ ] T059 [P] [T2] Implement `_apply_size_scale()` for FireBallWeapon in `gameplay/weapons/FireBallProjectile.gd`
- [ ] T060 [P] [T2] Implement `_store_base_values()` for FrozenCloud in `gameplay/weapons/FrozenCloudProjectile.gd`
- [ ] T061 [P] [T2] Implement `_apply_size_scale()` for FrozenCloud in `gameplay/weapons/FrozenCloudProjectile.gd`
- [ ] T062 [P] [T2] Implement `_store_base_values()` for LaserSkyWeapon in `gameplay/weapons/LaserSkyProjectile.gd`
- [ ] T063 [P] [T2] Implement `_apply_size_scale()` for LaserSkyWeapon in `gameplay/weapons/LaserSkyProjectile.gd`
- [ ] T064 [P] [T2] Implement `_store_base_values()` for MinesWeapon in `gameplay/weapons/MinesWeaponProjectile.gd`
- [ ] T065 [P] [T2] Implement `_apply_size_scale()` for MinesWeapon in `gameplay/weapons/MinesWeaponProjectile.gd`
- [ ] T066 [P] [T2] Implement `_store_base_values()` for PingPongWeapon in corresponding projectile script
- [ ] T067 [P] [T2] Implement `_apply_size_scale()` for PingPongWeapon in corresponding projectile script
- [ ] T068 [P] [T2] Implement `_store_base_values()` for Poisonflask in `gameplay/weapons/PoisonflaskProjectile.gd`
- [ ] T069 [P] [T2] Implement `_apply_size_scale()` for Poisonflask in `gameplay/weapons/PoisonflaskProjectile.gd`
- [ ] T070 [P] [T2] Implement `_store_base_values()` for Saw in corresponding projectile script
- [ ] T071 [P] [T2] Implement `_apply_size_scale()` for Saw in corresponding projectile script
- [ ] T072 [P] [T2] Implement `_store_base_values()` for Shotgun in `gameplay/weapons/ShotgunProjectile.gd`
- [ ] T073 [P] [T2] Implement `_apply_size_scale()` for Shotgun in `gameplay/weapons/ShotgunProjectile.gd`
- [ ] T074 [P] [T2] Implement `_store_base_values()` for Shuriken in corresponding projectile script
- [ ] T075 [P] [T2] Implement `_apply_size_scale()` for Shuriken in corresponding projectile script
- [ ] T076 [P] [T2] Implement `_store_base_values()` for SwingAttack in `gameplay/weapons/SwingAttackProjectile.gd`
- [ ] T077 [P] [T2] Implement `_apply_size_scale()` for SwingAttack in `gameplay/weapons/SwingAttackProjectile.gd`
- [ ] T078 [P] [T2] Implement `_store_base_values()` for SwordToTheMouse in `gameplay/weapons/SwordToTheMouseProjectile.gd`
- [ ] T079 [P] [T2] Implement `_apply_size_scale()` for SwordToTheMouse in `gameplay/weapons/SwordToTheMouseProjectile.gd`
- [ ] T080 [P] [T2] Implement `_store_base_values()` for WeaponCircle in corresponding projectile script
- [ ] T081 [P] [T2] Implement `_apply_size_scale()` for WeaponCircle in corresponding projectile script
- [ ] T082 [T2] Verify all weapons call `_store_base_values()` before `_apply_size_scale()` in `setup()` or `_ready()`

**Checkpoint**: All 20 weapons use unified size system with base value storage and scale application

---

## Phase 6: Task 4 - Editor Synchronization (Priority: P2)

**Goal**: Ensure 2D editor view matches runtime behavior at size_level = 0

**Independent Test**: Open each weapon scene in 2D editor, visual and collision match. Run game, verify same appearance at level 0.

### Implementation for Task 4

- [ ] T083 [P] [T4] Set base scale for Arrow weapon visual nodes in `gameplay/weapons/*ArrowProjectile.tscn` (if exists)
- [ ] T084 [P] [T4] Set base scale for AuraWeapon visual nodes in `gameplay/weapons/AuraWeaponProjectile.tscn`
- [ ] T085 [P] [T4] Set base scale for Banana weapon visual nodes in corresponding scene file
- [ ] T086 [P] [T4] Set base scale for BoulderWeapon visual nodes in `gameplay/weapons/BoulderWeaponProjectile.tscn`
- [ ] T087 [P] [T4] Set base scale for BubbleWeapon visual nodes in `gameplay/weapons/BubbleProjectile.tscn`
- [ ] T088 [P] [T4] Set base scale for ChainLighting visual nodes in corresponding scene file
- [ ] T089 [P] [T4] Set base scale for ChaosAround visual nodes in `gameplay/weapons/ChaosAroundManager.tscn`
- [ ] T090 [P] [T4] Set base scale for DroneWeapon visual nodes in `gameplay/weapons/DroneWeaponProjectile.tscn`
- [ ] T091 [P] [T4] Set base scale for FireBallWeapon visual nodes in `gameplay/weapons/FireBallProjectile.tscn`
- [ ] T092 [P] [T4] Set base scale for FrozenCloud visual nodes in `gameplay/weapons/FrozenCloudProjectile.tscn`
- [ ] T093 [P] [T4] Set base scale for LaserSkyWeapon visual nodes in `gameplay/weapons/LaserSkyProjectile.tscn`
- [ ] T094 [P] [T4] Set base scale for MinesWeapon visual nodes in `gameplay/weapons/MinesWeaponProjectile.tscn`
- [ ] T095 [P] [T4] Set base scale for PingPongWeapon visual nodes in corresponding scene file
- [ ] T096 [P] [T4] Set base scale for Poisonflask visual nodes in `gameplay/weapons/PoisonflaskProjectile.tscn`
- [ ] T097 [P] [T4] Set base scale for Saw visual nodes in corresponding scene file
- [ ] T098 [P] [T4] Set base scale for Shotgun visual nodes in `gameplay/weapons/ShotgunProjectile.tscn`
- [ ] T099 [P] [T4] Set base scale for Shuriken visual nodes in corresponding scene file
- [ ] T100 [P] [T4] Set base scale for SwingAttack visual nodes in `gameplay/weapons/SwingAttackProjectile.tscn`
- [ ] T101 [P] [T4] Set base scale for SwordToTheMouse visual nodes in `gameplay/weapons/SwordToTheMouseProjectile.tscn`
- [ ] T102 [P] [T4] Set base scale for WeaponCircle visual nodes in corresponding scene file
- [ ] T103 [P] [T4] Adjust collision shapes to match visual size for all 20 weapons in their `.tscn` files
- [ ] T104 [T4] Verify `_ready()` methods don't override editor values (store from editor state, only apply if size_level > 0)

**Checkpoint**: Editor view matches runtime at size_level = 0 for all weapons

---

## Phase 7: Task 5 - Testing (Priority: P2)

**Goal**: Verify unified behavior across all 20 weapons with manual testing

**Independent Test**: All test cases pass for all weapons: base level matches, size upgrades work, no accumulation on respawn

### Test Cases for Task 5

- [ ] T105 [P] [T5] Test Arrow weapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T106 [P] [T5] Test AuraWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T107 [P] [T5] Test Banana weapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T108 [P] [T5] Test BoulderWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T109 [P] [T5] Test BubbleWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T110 [P] [T5] Test ChainLighting: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T111 [P] [T5] Test ChaosAround: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T112 [P] [T5] Test DroneWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T113 [P] [T5] Test FireBallWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T114 [P] [T5] Test FrozenCloud: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T115 [P] [T5] Test LaserSkyWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T116 [P] [T5] Test MinesWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T117 [P] [T5] Test PingPongWeapon: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T118 [P] [T5] Test Poisonflask: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T119 [P] [T5] Test Saw: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T120 [P] [T5] Test Shotgun: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T121 [P] [T5] Test Shuriken: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T122 [P] [T5] Test SwingAttack: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T123 [P] [T5] Test SwordToTheMouse: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T124 [P] [T5] Test WeaponCircle: Base level (size_level = 0) - visual and collision match in editor and runtime
- [ ] T125 [T5] Test all weapons: Multiple spawns (10 spawns with same size_level = same size, no accumulation)
- [ ] T126 [T5] Test all weapons: Size upgrades (0 → 1 → 2 → ...) - visual and collision increase proportionally, no jumps
- [ ] T127 [T5] Test all weapons: At level 10, size ≈ 1.5x base (10 × 5%)
- [ ] T128 [T5] Verify all weapons use unified formula: `scale_factor = 1.0 + size_level * 0.05`

**Checkpoint**: All test cases pass for all 20 weapons

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation updates

- [ ] T129 Run `godot --headless --check-only` and verify exit code 0 (no errors)
- [ ] T130 Verify no `inferred_variant` warnings in all modified weapon scripts
- [ ] T131 [P] Update `docs/BUGS_PATTERNS.md` if new accumulation bug patterns discovered during implementation
- [ ] T132 [P] Document any weapon-specific quirks or deviations in weapon documentation
- [ ] T133 Verify all 20 weapons have `size_level: int = 0` field in their `.tres` config files
- [ ] T134 Remove deprecated `_size_scale` variable usage from all weapon scripts (if any remain)
- [ ] T135 Run `scripts/Check-Project-Errors.ps1` and verify no errors
- [ ] T136 Validate quickstart.md checklist: All items completed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all weapon-specific work
- **Task 1 - Inventory (Phase 3)**: Depends on Foundational completion - Can start after Phase 2
- **Task 3 - Bug Fixes (Phase 4)**: Depends on Task 1 completion - **MUST complete before Task 2**
- **Task 2 - Unified System (Phase 5)**: Depends on Task 3 completion - **CRITICAL**: Cannot start until bugs fixed
- **Task 4 - Editor Sync (Phase 6)**: Depends on Task 2 completion - Requires unified system in place
- **Task 5 - Testing (Phase 7)**: Depends on Task 4 completion - Tests all previous work
- **Polish (Phase 8)**: Depends on all previous phases completion

### Task Dependencies

- **Task 1 (Inventory)**: Can start after Foundational (Phase 2) - No dependencies on other tasks
- **Task 3 (Bug Fixes)**: Can start after Task 1 - Must complete before Task 2
- **Task 2 (Unified System)**: **MUST wait for Task 3** - Cannot start until accumulation bugs fixed
- **Task 4 (Editor Sync)**: Depends on Task 2 - Requires unified system implemented
- **Task 5 (Testing)**: Depends on Task 4 - Tests all previous work

### Within Each Task

- Inventory: All weapons can be documented in parallel [P]
- Bug Fixes: All weapon bug fixes can be done in parallel [P] (different files)
- Unified System: `_store_base_values()` and `_apply_size_scale()` can be implemented per weapon in parallel [P]
- Editor Sync: All weapon scene adjustments can be done in parallel [P]
- Testing: All weapon base level tests can be done in parallel [P]

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks can run sequentially (they modify same base class)
- Task 1: All weapon inventory tasks marked [P] can run in parallel
- Task 3: All weapon bug fixes marked [P] can run in parallel (different files)
- Task 2: All weapon implementations marked [P] can run in parallel (different files)
- Task 4: All weapon scene adjustments marked [P] can run in parallel
- Task 5: All weapon base level tests marked [P] can run in parallel

---

## Parallel Example: Task 2 (Unified System)

```bash
# Launch all weapon implementations in parallel (different files):
Task: "Implement _store_base_values() for Arrow weapon"
Task: "Implement _store_base_values() for AuraWeapon"
Task: "Implement _store_base_values() for Banana weapon"
Task: "Implement _store_base_values() for BoulderWeapon"
# ... (all 20 weapons can be done in parallel)
```

---

## Implementation Strategy

### MVP First (Core Functionality)

1. Complete Phase 1: Setup (base class extensions)
2. Complete Phase 2: Foundational (method stubs)
3. Complete Phase 3: Task 1 (Inventory) - Document all weapons
4. Complete Phase 4: Task 3 (Bug Fixes) - Fix accumulation bugs
5. Complete Phase 5: Task 2 (Unified System) - Implement for all weapons
6. **STOP and VALIDATE**: Test unified system works, no accumulation
7. Continue with Phase 6-8 if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add Task 1 (Inventory) → Document all weapons
3. Add Task 3 (Bug Fixes) → Fix all accumulation bugs → Validate
4. Add Task 2 (Unified System) → Implement for all weapons → Validate
5. Add Task 4 (Editor Sync) → Align editor with runtime → Validate
6. Add Task 5 (Testing) → Verify all weapons → Validate
7. Add Polish → Final validation

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: Task 1 (Inventory) - Document weapons 1-7
   - Developer B: Task 1 (Inventory) - Document weapons 8-14
   - Developer C: Task 1 (Inventory) - Document weapons 15-20
3. Once Task 1 complete:
   - Developer A: Task 3 (Bug Fixes) - Fix weapons 1-7
   - Developer B: Task 3 (Bug Fixes) - Fix weapons 8-14
   - Developer C: Task 3 (Bug Fixes) - Fix weapons 15-20
4. Once Task 3 complete:
   - Developer A: Task 2 (Unified System) - Implement weapons 1-7
   - Developer B: Task 2 (Unified System) - Implement weapons 8-14
   - Developer C: Task 2 (Unified System) - Implement weapons 15-20
5. Continue with Task 4, 5, and Polish

---

## Notes

- [P] tasks = different files, no dependencies
- [T1], [T2], [T3], [T4], [T5] labels map task to specific phase for traceability
- **CRITICAL**: Task 3 (Bug Fixes) MUST complete before Task 2 (Unified System)
- Each weapon can be worked on independently (different files)
- Verify no accumulation on respawn after each phase
- Commit after each task or logical group
- Stop at any checkpoint to validate phase independently
- Avoid: modifying same file in parallel, skipping bug fixes before unified system

---

## Summary

- **Total Tasks**: 136
- **Task Count by Phase**:
  - Phase 1 (Setup): 3 tasks
  - Phase 2 (Foundational): 3 tasks
  - Phase 3 (Task 1 - Inventory): 23 tasks (20 weapons + 3 setup)
  - Phase 4 (Task 3 - Bug Fixes): 11 tasks
  - Phase 5 (Task 2 - Unified System): 42 tasks (20 weapons × 2 methods + 2 verification)
  - Phase 6 (Task 4 - Editor Sync): 22 tasks (20 weapons + 2 verification)
  - Phase 7 (Task 5 - Testing): 24 tasks (20 weapons + 4 integration tests)
  - Phase 8 (Polish): 8 tasks

- **Parallel Opportunities**: High - most weapon-specific tasks can run in parallel (different files)
- **Independent Test Criteria**: Each phase has clear checkpoint criteria
- **Suggested MVP Scope**: Phases 1-5 (Setup through Unified System) - core functionality complete

