# Tasks: Enemy Death FX v1 — Hybrid LOD + Pooling

**Input**: Design documents from `/specs/010-enemy-death-fx/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Manual testing only (FX visuals require in-game verification). No automated test tasks included.

**Organization**: Tasks are grouped by functional requirements to enable independent implementation and testing.

## Format: `[ID] [P?] [Req?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Req]**: Which requirement this task belongs to (e.g., Req1, Req2, Req3)
- Include exact file paths in descriptions

## Path Conventions

- **Game project**: `gameplay/`, `shaders/`, `data/config/` at repository root
- Paths follow existing project structure from plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create `shaders/` directory if missing
- [X] T002 [P] Create `data/config/` directory structure if missing
- [X] T003 [P] Verify `gameplay/enemies/` directory exists

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY requirement can be implemented

**⚠️ CRITICAL**: No requirement work can begin until this phase is complete

- [X] T004 Create `EnemyDeathConfig` resource class in `gameplay/enemies/EnemyDeathConfig.gd`
- [X] T005 Create `data/config/EnemyDeathConfig.tres` resource file with default values
- [X] T006 [P] Create dissolve shader `shaders/enemy_death_dissolve.gdshader` with `dissolve_progress` uniform
- [X] T007 [P] Create shader material resource `shaders/enemy_death_dissolve_material.tres` referencing the shader

**Checkpoint**: Foundation ready - requirement implementation can now begin

---

## Phase 3: Requirement 1 - Unified Death Pipeline 🎯 MVP

**Goal**: Implement centralized death handling that sets enemy state to DYING, disables AI/movement/collisions, and triggers loot/XP/kill counters.

**Independent Test**: Kill an enemy near player → enemy immediately stops moving/attacking, loot/XP triggered, enemy removed after FX.

### Implementation for Requirement 1

- [X] T008 [Req1] Create `EnemyDeathController` class in `gameplay/enemies/EnemyDeathController.gd` with `handle_enemy_death()` method
- [X] T008a [Req1] Ensure all methods in `EnemyDeathController` have explicit type annotations:
  - `handle_enemy_death(enemy: Enemy, from: Node) -> void`
  - `_set_enemy_dying_state(enemy: Enemy) -> void`
  - All variables typed: `var _config: EnemyDeathConfig`
- [X] T009 [Req1] Add `_set_enemy_dying_state()` method to disable AI, movement, collisions in `gameplay/enemies/EnemyDeathController.gd`
- [X] T010 [Req1] Add `_trigger_death_events()` method in `gameplay/enemies/EnemyDeathController.gd` that triggers existing systems:
  - Call existing loot drop logic (check if enemy has loot component or signal)
  - Call existing XP system (e.g., `ExperienceService.add_xp()` or enemy's XP signal)
  - Call existing kill counter (e.g., `GameSession.increment_kill_count()` or signal)
  - Note: Use existing signals/methods, do not duplicate logic
- [X] T011 [Req1] Add `_cleanup_and_release()` method for final cleanup in `gameplay/enemies/EnemyDeathController.gd`
- [X] T012 [Req1] Connect `HealthComponent.died` signal to `EnemyDeathController.handle_enemy_death()` in enemy spawn/ready logic
- [X] T013 [Req1] Add `EnemyDeathController` as autoload singleton in Project Settings (or add to main scene)

**Checkpoint**: At this point, Requirement 1 should be fully functional - enemies die, AI disabled, events triggered

---

## Phase 4: Requirement 2 - LOD Behavior

**Goal**: Implement distance-based LOD decision (near = nice FX, far = cheap FX) with configurable radius.

**Independent Test**: Kill enemy near player (< 500px) → nice FX. Kill enemy far from player (> 500px) → cheap FX.

### Implementation for Requirement 2

- [X] T014 [Req2] Add `_calculate_distance_to_player()` method in `gameplay/enemies/EnemyDeathController.gd`
- [X] T014a [Req2] Ensure LOD methods have explicit type annotations:
  - `_calculate_distance_to_player(enemy: Enemy) -> float`
  - `_should_use_nice_fx(enemy: Enemy) -> bool`
- [X] T015 [Req2] Add `_should_use_nice_fx()` method with distance check and cap check in `gameplay/enemies/EnemyDeathController.gd`
- [X] T016 [Req2] Load `EnemyDeathConfig` resource in `EnemyDeathController._ready()` and cache `_config` variable
- [X] T017 [Req2] Cache player reference in `EnemyDeathController._ready()` via `get_tree().get_first_node_in_group("player")`

**Checkpoint**: At this point, LOD decision logic should work - distance calculated, decision cached

---

## Phase 5: Requirement 3 - Visual FX Behavior

**Goal**: Implement shader-based dissolve FX for near deaths and alpha fade for far deaths, both driven by Tween.

**Independent Test**: Kill enemy near player → dissolve shader effect plays (0.6 sec). Kill enemy far → alpha fade (0.15 sec).

### Implementation for Requirement 3

- [X] T018 [Req3] Add `_get_enemy_sprite()` helper method to find `AnimatedSprite2D` or `Sprite2D` in `gameplay/enemies/EnemyDeathController.gd`
- [X] T018a [Req3] Ensure FX methods have explicit type annotations:
  - `_get_enemy_sprite(enemy: Enemy) -> Node2D`
  - `_start_nice_fx(enemy: Enemy) -> void`
  - `_start_cheap_fx(enemy: Enemy) -> void`
  - All Tween callbacks typed: `func _on_nice_fx_finished(enemy: Enemy) -> void`
- [X] T019 [Req3] Add `_start_nice_fx()` method to apply shader material and start Tween in `gameplay/enemies/EnemyDeathController.gd`
- [X] T020 [Req3] Add `_start_cheap_fx()` method to start alpha fade Tween in `gameplay/enemies/EnemyDeathController.gd`
- [X] T021 [Req3] Add `_on_nice_fx_finished()` callback to cleanup shader material in `gameplay/enemies/EnemyDeathController.gd`
- [X] T022 [Req3] Add `_on_cheap_fx_finished()` callback to cleanup alpha in `gameplay/enemies/EnemyDeathController.gd`
- [X] T023 [Req3] Load shared shader material resource in `EnemyDeathController._ready()` and cache `_shared_shader_material` variable
- [X] T024 [Req3] Implement Tween animation for `dissolve_progress` uniform (0.0 to 1.0) in `_start_nice_fx()`
- [X] T025 [Req3] Implement Tween animation for `modulate.a` (1.0 to 0.0) in `_start_cheap_fx()`
- [X] T025a [Req3] Add timeout safety fallback in `_start_nice_fx()` and `_start_cheap_fx()` methods:
  - Create backup timer (FX duration + 0.5 sec safety margin)
  - If Tween fails or doesn't finish, timer triggers cleanup
  - Prevents enemies stuck in DYING state if FX fails

**Checkpoint**: At this point, both FX variants should work - shader dissolve and alpha fade

---

## Phase 6: Requirement 5 - Performance & Integration

**Goal**: Enforce hard cap on simultaneous "nice" FX (max 30), integrate with existing systems, ensure no regressions.

**Independent Test**: Kill 35 enemies near player simultaneously → first 30 get nice FX, remaining 5 get cheap FX. FPS remains stable.

### Implementation for Requirement 5

- [X] T026 [Req5] Add `_active_nice_fx_count: int = 0` state variable in `gameplay/enemies/EnemyDeathController.gd`
- [X] T026a [Req5] Ensure performance methods have explicit type annotations:
  - All state variables typed: `var _active_nice_fx_count: int = 0`
  - All increment/decrement operations use typed variables
- [X] T027 [Req5] Increment `_active_nice_fx_count` in `_start_nice_fx()` before starting FX
- [X] T028 [Req5] Decrement `_active_nice_fx_count` in `_on_nice_fx_finished()` after cleanup
- [X] T029 [Req5] Add cap check to `_should_use_nice_fx()` method (return false if `_active_nice_fx_count >= max_active_nice_fx`)
- [X] T030 [Req5] Add `@export var debug_logs: bool = false` to `EnemyDeathController` for debugging
- [X] T031 [Req5] Add debug logging for LOD decisions, FX start/finish, cap enforcement in `gameplay/enemies/EnemyDeathController.gd`
- [ ] T032 [Req5] Verify existing loot drop, XP, kill counter systems still work (no regressions)
- [ ] T033 [Req5] Test performance with 50+ simultaneous deaths - FPS should remain stable

**Checkpoint**: At this point, performance constraints should be enforced - cap working, no FPS drops

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple requirements

- [ ] T034 [P] Run type checking: verify all new code has explicit type annotations using `godot --headless --check-only` (no inferred_variant warnings)
- [ ] T035 [P] Verify tab indentation and LF line endings in all new files using `scripts/Fix-Indents.ps1`
- [ ] T036 [P] Run `godot --headless --check-only` to verify no type errors
- [ ] T037 [P] Test all enemy types (Zombie, Skeleton, Werewolf, etc.) with death FX system
- [ ] T038 [P] Tune `EnemyDeathConfig` values (radius, durations, max FX) based on gameplay testing
- [ ] T039 [P] Update documentation if needed (quickstart.md validation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all requirements
- **Requirements (Phase 3-6)**: All depend on Foundational phase completion
  - Requirements can proceed sequentially (Req1 → Req2 → Req3 → Req5)
  - Some tasks within requirements can run in parallel (marked [P])
- **Polish (Phase 7)**: Depends on all requirement phases being complete

### Requirement Dependencies

- **Requirement 1 (Unified Pipeline)**: Can start after Foundational (Phase 2) - No dependencies on other requirements
- **Requirement 2 (LOD)**: Depends on Req1 completion - needs `handle_enemy_death()` entry point
- **Requirement 3 (Visual FX)**: Depends on Req1 and Req2 - needs LOD decision and death pipeline
- **Requirement 5 (Performance)**: Depends on Req1, Req2, Req3 - needs all FX logic to enforce cap

### Within Each Requirement

- Core methods before integration
- Helper methods before main methods
- State variables before methods that use them
- Requirement complete before moving to next requirement

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel (T002, T003)
- All Foundational tasks marked [P] can run in parallel (T006, T007)
- Within Requirement 3: T018, T019, T020 can be worked on in parallel (different methods)
- Within Requirement 5: T030, T031 can run in parallel (different debug features)
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: Requirement 3

```bash
# Launch shader and material creation together:
Task: "Create dissolve shader shaders/enemy_death_dissolve.gdshader" (T006)
Task: "Create shader material resource shaders/enemy_death_dissolve_material.tres" (T007)

# Launch helper methods together:
Task: "Add _get_enemy_sprite() helper method" (T018)
Task: "Add _start_nice_fx() method" (T019)
Task: "Add _start_cheap_fx() method" (T020)
```

---

## Implementation Strategy

### MVP First (Requirements 1-3 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all requirements)
3. Complete Phase 3: Requirement 1 (Unified Pipeline)
4. Complete Phase 4: Requirement 2 (LOD Behavior)
5. Complete Phase 5: Requirement 3 (Visual FX)
6. **STOP and VALIDATE**: Test Requirements 1-3 independently
7. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add Requirement 1 → Test independently → Basic death pipeline works
3. Add Requirement 2 → Test independently → LOD decisions work
4. Add Requirement 3 → Test independently → FX visuals work
5. Add Requirement 5 → Test independently → Performance cap enforced
6. Each requirement adds value without breaking previous requirements

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: Requirement 1 (Unified Pipeline)
   - Developer B: Requirement 2 (LOD) - can start after Req1
   - Developer C: Requirement 3 (Visual FX) - can start after Req2
3. Requirements complete and integrate sequentially

---

## Notes

- [P] tasks = different files, no dependencies
- [Req] label maps task to specific requirement for traceability
- Each requirement should be independently completable and testable
- Manual testing required for FX visuals (in-game verification)
- Commit after each task or logical group
- Stop at any checkpoint to validate requirement independently
- Avoid: vague tasks, same file conflicts, cross-requirement dependencies that break independence
- Requirement 4 (Pooling) is intentionally deferred to Phase 2 (future):
  - Enemy pooling is optional in v1 (spec.md line 121)
  - Current implementation uses `queue_free()` approach
  - Pooling tasks will be added in future iteration
  - See plan.md line 106 for future EnemyPool structure

---

## Task Summary

**Total Tasks**: 44

**Tasks by Requirement**:
- Setup: 3 tasks
- Foundational: 4 tasks
- Requirement 1 (Unified Pipeline): 7 tasks (added T008a for typing)
- Requirement 2 (LOD): 5 tasks (added T014a for typing)
- Requirement 3 (Visual FX): 10 tasks (added T018a for typing, T025a for timeout)
- Requirement 5 (Performance): 9 tasks (added T026a for typing)
- Polish: 6 tasks

**Parallel Opportunities**: 15 tasks marked [P] (typing tasks can be done during implementation)

**Suggested MVP Scope**: Phases 1-5 (Requirements 1-3) = 29 tasks (3 setup + 4 foundational + 7 req1 + 5 req2 + 10 req3)

**Independent Test Criteria**:
- **Req1**: Enemy dies → AI disabled → Events triggered → Cleanup works
- **Req2**: Distance calculated → LOD decision correct → Decision cached
- **Req3**: Near death → Shader dissolve plays → Far death → Alpha fade plays
- **Req5**: 35 enemies die → 30 get nice FX, 5 get cheap FX → FPS stable

