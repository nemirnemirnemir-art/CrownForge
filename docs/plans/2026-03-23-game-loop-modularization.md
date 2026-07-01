# Game Loop Modularization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn the game-loop layer into a conductor-style architecture where `GameScene` coordinates specialized modules instead of owning gameplay flow logic directly.

**Architecture:** Keep all existing public scene hooks and signals stable while extracting tightly scoped controllers from `GameScene.gd` and `GameSceneWaves.gd`. Use delegation first, not rewrites: `GameScene` remains the facade and scene entrypoint, while new helper scripts own encounter flow, wave completion flow, startup/bootstrap wiring, and wave spawning/reward assembly.

**Tech Stack:** Godot 4.3, GDScript, existing `scripts/game_scene/*` manager pattern, headless SceneTree tests in `scripts/dev/tests`

---

### Task 1: Extract GameScene encounter flow controller

**Files:**
- Create: `scripts/game_scene/GameSceneEncounterFlow.gd`
- Modify: `scripts/game/GameScene.gd`
- Test: `scripts/dev/tests/test_gamescene_encounter_flow.gd`

**Step 1: Write the failing test**

Create a focused SceneTree test that instantiates `GameSceneEncounterFlow`, injects fake pause/wave/encounter/menu dependencies, then verifies:
- prophecy confirm delegates queue setup,
- encounter pause transfer happens when encounter opens,
- UI action queue drains in order,
- closing encounter releases pause and unpauses waves.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_encounter_flow.gd`
Expected: FAIL because `GameSceneEncounterFlow.gd` does not exist yet.

**Step 3: Write minimal implementation**

Implement `GameSceneEncounterFlow.gd` as a pure helper/controller that owns:
- prophecy confirmation flow,
- encounter open/close flow,
- pending encounter UI action queue,
- helper methods for reward-menu visibility checks.

Keep `GameScene.gd` methods as thin wrappers that delegate into the controller so scene connections do not change.

**Step 4: Run test to verify it passes**

Run the same test again.
Expected: PASS.

**Step 5: Run nearby regression checks**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd`
Expected: PASS.

### Task 2: Extract GameScene wave completion / reward bridge

**Files:**
- Create: `scripts/game_scene/GameSceneWaveFlow.gd`
- Modify: `scripts/game/GameScene.gd`
- Test: `scripts/dev/tests/test_gamescene_wave_flow.gd`

**Step 1: Write the failing test**

Create a test that verifies a wave completion helper:
- pauses waves,
- opens `WaveRewardMenu`,
- preserves the prophecy-first-wave branch,
- resumes waves correctly after reward menu close when prophecy is not pending.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_wave_flow.gd`
Expected: FAIL because helper does not exist yet.

**Step 3: Write minimal implementation**

Implement `GameSceneWaveFlow.gd` and move the policy from:
- `_on_wave_completed`,
- `_on_wave_reward_menu_closed`,
- `_on_prophecy_batch_finished`.

Keep `GameScene.gd` as the forwarding facade.

**Step 4: Run tests to verify pass**

Run the new test plus:
- `scripts/dev/tests/test_mob_lane_assault_runtime.gd`
- `scripts/dev/tests/test_mob_wall_attack_stop_distance_override.gd`

Expected: PASS.

### Task 3: Extract GameScene startup/bootstrap wiring

**Files:**
- Create: `scripts/game_scene/GameSceneBootstrap.gd`
- Modify: `scripts/game/GameScene.gd`
- Test: `scripts/dev/tests/test_gamescene_bootstrap.gd`

**Step 1: Write the failing test**

Cover:
- module initialization order,
- wave timer hookup,
- map layout / building menu signal connection,
- spell panel setup delegation.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_gamescene_bootstrap.gd`
Expected: FAIL because bootstrap helper does not exist yet.

**Step 3: Write minimal implementation**

Move bootstrap logic from `_initialize_modules()` and `_setup_wave_timer_bar()` into `GameSceneBootstrap.gd`. Keep `GameScene` owning exported values and node refs, but let the helper execute wiring.

**Step 4: Run tests to verify pass**

Run the bootstrap test and a small smoke chain around waves and map initialization.

### Task 4: Split GameSceneWaves spawn and reward assembly

**Files:**
- Create: `scripts/game_scene/modules/WaveMobRegistry.gd`
- Create: `scripts/game_scene/modules/WaveSpawnService.gd`
- Create: `scripts/game_scene/modules/WaveRewardBuilder.gd`
- Modify: `scripts/game_scene/GameSceneWaves.gd`
- Test: `scripts/dev/tests/test_gamescenewaves_spawn_service.gd`
- Test: `scripts/dev/tests/test_gamescenewaves_reward_builder.gd`

**Step 1: Write failing tests**

Cover:
- mob lookup by id,
- spawn position and lane assignment,
- wall attack stop distance propagation,
- reward extraction / placeholder behavior.

**Step 2: Run tests to verify fail**

Run both new tests headless.
Expected: FAIL because services do not exist yet.

**Step 3: Write minimal implementation**

Keep `GameSceneWaves` as lifecycle orchestrator, but move:
- scene registry / mob lookup,
- mob instantiation and spawn placement,
- reward normalization / current-wave reward assembly
into dedicated modules.

**Step 4: Run tests to verify pass**

Run both new tests and existing `scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd`.

### Task 5: Architectural cleanup and regression sweep

**Files:**
- Modify only files touched by Tasks 1-4
- Test: existing relevant `scripts/dev/tests/*.gd`

**Step 1: Run focused regression suite**

Run:
- `scripts/dev/tests/test_gamescene_encounter_flow.gd`
- `scripts/dev/tests/test_gamescene_wave_flow.gd`
- `scripts/dev/tests/test_gamescene_bootstrap.gd`
- `scripts/dev/tests/test_gamescenewaves_spawn_service.gd`
- `scripts/dev/tests/test_gamescenewaves_reward_builder.gd`
- `scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd`
- `scripts/dev/tests/test_mob_lane_assault_runtime.gd`
- `scripts/dev/tests/test_mob_wall_attack_stop_distance_override.gd`

**Step 2: Inspect for leftover direct policy in GameScene**

Confirm `GameScene.gd` now mostly delegates for:
- encounter flow,
- wave completion flow,
- bootstrap wiring.

**Step 3: Commit in small slices**

Suggested commit sequence:
- `refactor: extract encounter flow from game scene`
- `refactor: extract wave reward flow from game scene`
- `refactor: extract game scene bootstrap wiring`
- `refactor: split wave spawning and reward assembly`
