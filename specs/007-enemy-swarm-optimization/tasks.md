# Tasks: Enemy Swarm Optimization

**Feature**: Enemy Swarm Optimization  
**Branch**: `007-enemy-swarm-optimization`  
**Date**: 2025-01-09  
**Status**: Ready for Implementation

## Summary

This document breaks down the Enemy Swarm Optimization feature into actionable, dependency-ordered tasks organized by user story. Each task is specific enough for an LLM to complete without additional context.

**Total Tasks**: 35  
**User Story 1 (P0)**: 15 tasks  
**User Story 2 (P1)**: 12 tasks  
**Foundational**: 5 tasks  
**Polish**: 3 tasks

## Dependencies

### User Story Completion Order

1. **Foundational Phase** (Phase 2) - Must complete before all user stories
   - QualityManager enhancements provide API for culling and enemy limits
   - Blocks: US1, US2

2. **User Story 1** (Phase 3, P0) - Core performance optimization
   - Enemy culling system
   - Spawn limits enforcement
   - Simplified AI integration
   - Independent: Can be tested with 300 enemies, FPS >= 30

3. **User Story 2** (Phase 4, P1) - Visual quality degradation
   - Visual effects optimization
   - Off-screen simplification
   - Depends on: US1 (culling system)

4. **Polish Phase** (Phase 5) - Testing and tuning
   - Performance testing
   - Gameplay validation
   - Documentation updates
   - Depends on: US1, US2

### Parallel Execution Opportunities

**Within User Story 1**:
- T010 [P] [US1] and T011 [P] [US1] can be done in parallel (different properties)
- T012 [P] [US1] and T013 [P] [US1] can be done in parallel (different methods)
- T014 [P] [US1] and T015 [P] [US1] can be done in parallel (different spawner enhancements)

**Within User Story 2**:
- T022 [P] [US2] and T023 [P] [US2] can be done in parallel (different visual effects)
- T024 [P] [US2] and T025 [P] [US2] can be done in parallel (different simplification methods)

**Cross-Story**:
- No parallel execution between US1 and US2 (US2 depends on US1 culling system)

## Implementation Strategy

### MVP Scope
**MVP = User Story 1 (P0) only** - Core performance optimization to achieve 30+ FPS with 300 enemies.

**MVP Deliverables**:
- QualityManager enhancements (culling distance, max enemies)
- Enemy culling system (despawn beyond distance)
- Spawn limits enforcement (300 enemy hard limit)
- Simplified AI integration (already partially implemented)

**Post-MVP**:
- User Story 2 (visual effects optimization)
- Polish phase (testing, tuning, documentation)

### Incremental Delivery

1. **Increment 1**: Foundational (QualityManager API)
   - Enables all subsequent work
   - Test: API methods return correct values

2. **Increment 2**: Enemy Culling (US1 core)
   - Enemies despawn beyond culling distance
   - Test: Enemy count decreases as player moves

3. **Increment 3**: Spawn Limits (US1 enforcement)
   - Hard limit of 300 enemies enforced
   - Test: Spawner stops spawning at limit

4. **Increment 4**: Visual Optimization (US2)
   - Hit effects and damage popups optimized
   - Test: Visual effects disabled/reduced at quality 0-1

5. **Increment 5**: Polish
   - Performance testing and tuning
   - Test: All acceptance scenarios pass

---

## Phase 1: Setup

**Goal**: Verify prerequisites and existing systems are ready for enhancements.

**Independent Test Criteria**: All existing systems (`QualityManager`, `PerformanceMonitor`, `Enemy.gd`, `EnemySpawner`) are accessible and functional.

- [ ] T001 Verify QualityManager autoload exists and quality_settings structure in `autoload/QualityManager.gd`
- [ ] T002 Verify PerformanceMonitor tracks enemy_count_total in `autoload/PerformanceMonitor.gd`
- [ ] T003 Verify Enemy.gd has set_quality_settings method in `gameplay/enemies/Enemy.gd`
- [ ] T004 Verify EnemySpawner manages enemy spawning in `gameplay/enemies/EnemySpawner.gd`

---

## Phase 2: Foundational

**Goal**: Enhance QualityManager with culling distance and max enemies API. These are blocking prerequisites for all user stories.

**Independent Test Criteria**: `QualityManager.get_culling_distance()` and `QualityManager.get_max_enemies()` return correct values for each quality level (0-3).

- [ ] T005 Add culling_distance to quality_settings for each level (800, 1000, 1200, 1500px) in `autoload/QualityManager.gd`
- [ ] T006 Implement get_culling_distance() -> float method returning quality-dependent distance in `autoload/QualityManager.gd`
- [ ] T007 Implement get_max_enemies() -> int method returning quality-dependent limit in `autoload/QualityManager.gd`
- [ ] T008 Add error handling for invalid quality levels in get_culling_distance() and get_max_enemies() in `autoload/QualityManager.gd`
- [ ] T009 Test quality level transitions trigger culling distance and max enemies updates in `autoload/QualityManager.gd`

---

## Phase 3: User Story 1 - Maintain Playable FPS with 300 Enemies (P0)

**Goal**: As a player, I need the game to maintain playable frame rates (minimum 30 FPS) when 300 enemies are on screen so I can continue playing without severe lag.

**Independent Test Criteria**:
1. Given 300 enemies are spawned, When game runs, Then FPS remains >= 30 FPS
2. Given 300 enemies are active, When player moves and fights, Then physics time < 10ms
3. Given 300 enemies are on screen, When quality auto-adjusts, Then simplified AI activates automatically

### Enemy Culling System

- [ ] T010 [P] [US1] Add _is_off_screen: bool property to track off-screen state in `gameplay/enemies/Enemy.gd`
- [ ] T011 [P] [US1] Add _distance_to_player: float property to cache distance calculation in `gameplay/enemies/Enemy.gd`
- [ ] T012 [P] [US1] Implement _check_culling() -> bool method for distance-based despawn in `gameplay/enemies/Enemy.gd`
- [ ] T013 [P] [US1] Implement _fade_out_and_despawn() -> void method for quality 2-3 visual polish in `gameplay/enemies/Enemy.gd`
- [ ] T014 [P] [US1] Implement _update_off_screen_state() -> void method for viewport-based off-screen detection in `gameplay/enemies/Enemy.gd`
- [ ] T015 [P] [US1] Add culling check timer (0.5-1.0s interval) and call _check_culling() in _physics_process() in `gameplay/enemies/Enemy.gd`

### Spawn Limits Enforcement

- [ ] T016 [US1] Add max_enemies check using QualityManager.get_max_enemies() before spawning in `gameplay/enemies/EnemySpawner.gd`
- [ ] T017 [US1] Integrate spawn radius with culling distance (1.5-2x relationship) in `gameplay/enemies/EnemySpawner.gd`
- [ ] T018 [US1] Add spawn throttling when approaching 300 enemy hard limit in `gameplay/enemies/EnemySpawner.gd`

### Simplified AI Integration

- [ ] T019 [US1] Verify simplified AI activates at quality level 0 or enemy_count >= 200 in `gameplay/enemies/Enemy.gd`
- [ ] T020 [US1] Verify simplified AI skips neighbor cache, steering, and soft constraints in `gameplay/enemies/Enemy.gd`
- [ ] T021 [US1] Verify _update_anim(velocity) is called in simplified AI mode to maintain sprite flip_h in `gameplay/enemies/Enemy.gd`

### Testing & Validation

- [ ] T022 [US1] Test enemies despawn when beyond culling distance (spawn 300, move player away, verify count decreases)
- [ ] T023 [US1] Test spawn limits enforce 300 enemy hard limit (verify spawner stops at limit)
- [ ] T024 [US1] Test simplified AI activates automatically when FPS drops below 30 (verify _use_simplified_ai = true)

---

## Phase 4: User Story 2 - Adaptive Quality Degradation (P1)

**Goal**: As a player, I need visual quality to degrade gracefully when performance drops so the game remains playable even on lower-end hardware.

**Independent Test Criteria**:
1. Given FPS drops below 30, When quality adjusts, Then simplified AI and animation LOD activate
2. Given quality level 0 is active, When enemies are off-screen, Then animations are disabled
3. Given quality level changes, When settings broadcast, Then all enemies receive updated settings

### Visual Effects Optimization

- [ ] T025 [P] [US2] Implement hit effect simplification (disable at level 0, reduce particles at level 1) in `gameplay/enemies/Enemy.gd`
- [ ] T026 [P] [US2] Implement damage popup frequency reduction (disable at level 0, 50% at level 1) in damage popup system
- [ ] T027 [US2] Add hit_effects_enabled flag to quality_settings for each level in `autoload/QualityManager.gd`
- [ ] T028 [US2] Test visual effects don't break gameplay feedback (verify player can still see damage numbers at level 1)

### Off-screen Simplification

- [ ] T029 [US2] Implement _apply_off_screen_simplifications() method to disable animations and use simplified AI in `gameplay/enemies/Enemy.gd`
- [ ] T030 [US2] Implement _remove_off_screen_simplifications() method to re-enable animations and full AI in `gameplay/enemies/Enemy.gd`
- [ ] T031 [US2] Integrate off-screen simplification with _update_off_screen_state() in `gameplay/enemies/Enemy.gd`
- [ ] T032 [US2] Test off-screen enemies disable animations at quality levels 0-2 (verify _anim.stop() called)

### Quality Settings Broadcasting

- [ ] T033 [US2] Verify quality_changed signal is connected in Enemy._ready() in `gameplay/enemies/Enemy.gd`
- [ ] T034 [US2] Verify set_quality_settings() updates all enemy properties (simplified_ai, animation_lod, etc.) in `gameplay/enemies/Enemy.gd`
- [ ] T035 [US2] Test quality level changes broadcast to all enemies (change quality, verify all enemies update)

---

## Phase 5: Polish & Cross-Cutting Concerns

**Goal**: Performance testing, gameplay validation, and documentation updates.

**Independent Test Criteria**: All acceptance scenarios from US1 and US2 pass, performance targets met, documentation updated.

- [ ] T036 Performance test: Measure FPS with 300 enemies at each quality level (target: >= 30 FPS at level 0)
- [ ] T037 Gameplay test: Verify "attack from all sides" feel is maintained (spawn enemies, move player, verify distribution)
- [ ] T038 Tune culling distances and spawn radii based on test results (adjust values in QualityManager and EnemySpawner)
- [ ] T039 Update docs/perf_checklist.md with new optimization techniques (add culling system, spawn limits, visual effects optimization)

---

## Task Summary

### By Phase
- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 5 tasks
- **Phase 3 (User Story 1)**: 15 tasks
- **Phase 4 (User Story 2)**: 12 tasks
- **Phase 5 (Polish)**: 4 tasks

### By Priority
- **P0 (User Story 1)**: 15 tasks
- **P1 (User Story 2)**: 12 tasks
- **Foundational**: 5 tasks
- **Setup/Polish**: 8 tasks

### By File
- `autoload/QualityManager.gd`: 8 tasks (T005-T009, T027)
- `gameplay/enemies/Enemy.gd`: 18 tasks (T010-T015, T019-T021, T025, T029-T034)
- `gameplay/enemies/EnemySpawner.gd`: 3 tasks (T016-T018)
- Damage popup system: 1 task (T026)
- Testing/validation: 5 tasks (T022-T024, T028, T032, T035-T037)

### Parallel Opportunities
- **Within US1**: 6 tasks can be done in parallel (T010-T015)
- **Within US2**: 2 tasks can be done in parallel (T025, T026)
- **Total parallelizable**: 8 tasks

---

## Next Steps

1. **Start with Phase 2 (Foundational)**: Complete QualityManager enhancements first
2. **Then Phase 3 (US1)**: Implement core culling and spawn limits
3. **Then Phase 4 (US2)**: Add visual optimizations
4. **Finally Phase 5 (Polish)**: Test, tune, and document

**MVP Scope**: Phases 1-3 only (Setup + Foundational + User Story 1)

---

## References

- Feature spec: `specs/007-enemy-swarm-optimization/spec.md`
- Implementation plan: `specs/007-enemy-swarm-optimization/plan.md`
- Data model: `specs/007-enemy-swarm-optimization/data-model.md`
- API contracts: `specs/007-enemy-swarm-optimization/contracts/`
- Quick start: `specs/007-enemy-swarm-optimization/quickstart.md`
- Research: `specs/007-enemy-swarm-optimization/research.md`

