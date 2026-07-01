# Ten Kings Board To Battle Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace placeholder board visuals with on-field presentation, remove battle-time UI obstruction, add restart affordance, and make crowd battles deploy directly from real board-slot origins before combat begins.

**Architecture:** Keep `scripts/dev/ten_kings/TenKingsPrototype.gd` as the orchestrator that prepares preview data and slot-origin dictionaries, while dedicated runtime/view classes own their local behavior. Add a new board-visual library for on-board art lookup, extend board-slot UI to render building sprites and animated troop previews, and extend crowd battle startup with an explicit deploy phase that blocks combat until units finish traveling into formation.

**Tech Stack:** Godot 4.3, GDScript, scene-driven UI in `.tscn`, headless SceneTree tests in `scripts/dev/tests/`

---

### Task 1: Battle UI shell cleanup and restart affordance

**Files:**
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Test: `scripts/dev/tests/test_ten_kings_battle_arena_unobstructed.gd`
- Test: `scripts/dev/tests/test_ten_kings_restart_button_contract.gd`

**Step 1: Write the failing tests**

Add/extend tests that assert:
- battle start hides `UI/Root/Background`
- battle start makes `UI/Root/MainVBox/MiddleHBox/PlayerBoardPanel` non-visible and non-interactive
- a `RestartButton` exists next to `AiBoardButton`
- pressing `RestartButton` calls a prototype restart method that reloads the current scene

**Step 2: Run tests to verify they fail**

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_battle_arena_unobstructed.gd`

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_restart_button_contract.gd`

Expected: FAIL because `PlayerBoardPanel` remains visible in battle and `RestartButton` does not exist.

**Step 3: Write minimal implementation**

Implement in `scripts/dev/ten_kings/TenKingsPrototype.gd`:
- cache `PlayerBoardPanel` and `RestartButton`
- add `_set_player_board_battle_mode(active: bool)` that hides the panel and disables mouse input during battle, then restores it after battle
- add `_on_restart_button_pressed()` that calls `get_tree().reload_current_scene()`
- connect the button in `_ready()`

Implement in `scenes/dev/TenKingsPrototype.tscn`:
- add `RestartButton` beside `AiBoardButton`
- keep existing visual language and font overrides where needed

**Step 4: Run tests to verify they pass**

Run the two tests again and expect PASS.

### Task 2: Projectile travel duration scaling for structures

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsProjectileEffect.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Test: `scripts/dev/tests/test_ten_kings_structure_projectile_duration_scale.gd`

**Step 1: Write the failing test**

Add a test that launches arrow/cannonball effects over the same distance and asserts a `travel_duration_scale` of `2.0` doubles the computed `_travel_duration` versus the default scale.

**Step 2: Run test to verify it fails**

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_structure_projectile_duration_scale.gd`

Expected: FAIL because the effect has no scale parameter yet.

**Step 3: Write minimal implementation**

Implement in `scripts/dev/ten_kings/TenKingsProjectileEffect.gd`:
- optional `travel_duration_scale: float = 1.0` parameter on `launch_arrow()` and `launch_cannonball()`
- store the scale and apply it inside `_configure_duration()` after distance/speed calculation and before impact phase begins

Implement in `scripts/dev/ten_kings/TenKingsBattleManager.gd`:
- pass `2.0` for `CARD_CASTLE` and `CARD_SCOUT_TOWER`
- leave troop arrows unchanged

**Step 4: Run test to verify it passes**

Run the duration-scale test and expect PASS.

### Task 3: On-board visual library and dense troop preview

**Files:**
- Create: `scripts/dev/ten_kings/TenKingsBoardVisualLibrary.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Test: `scripts/dev/tests/test_ten_kings_phase2_board_presentation.gd`
- Test: `scripts/dev/tests/test_ten_kings_board_visual_library_contract.gd`

**Step 1: Write the failing tests**

Add/replace tests that assert:
- a board visual library maps supported cards to `assets/takefromthis/on_field/*`
- occupied troop slots render animated on-field preview nodes instead of 3x3 icon grids
- occupied building slots render a single building sprite
- preview data contract includes `card_id`, `side`, `stack_count`, `level`, `kind`, `damage_total`

**Step 2: Run tests to verify they fail**

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_phase2_board_presentation.gd`

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_board_visual_library_contract.gd`

Expected: FAIL because board slots still use card-hand icons and mini-icon pack previews.

**Step 3: Write minimal implementation**

Implement in `scripts/dev/ten_kings/TenKingsBoardVisualLibrary.gd`:
- on-field texture lookup for castle, tower, farm, blacksmith
- animation frame arrays for soldier, archer, paladin
- fallback behavior for unsupported cards (`wildcard`, `steel_coat`) without touching `TenKingsCardLibrary.gd`

Implement in `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`:
- accept preview dictionaries in a new method or revised `update_display()` contract
- render a building sprite node for structures
- render dense troop preview nodes for units with simple idle frame animation
- keep damage label support intact

Implement in `scripts/dev/ten_kings/TenKingsPrototype.gd`:
- build preview dictionaries from board data
- route board visuals through the new library instead of `_get_slot_icon_texture()` for board cells only

**Step 4: Run tests to verify they pass**

Run both board-presentation tests and expect PASS.

### Task 4: Crowd deploy phase from board-slot origins

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRenderer.gd`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Test: `scripts/dev/tests/test_ten_kings_phase2_battle_deploy.gd`
- Test: `scripts/dev/tests/test_ten_kings_crowd_deploy_from_board_origins.gd`

**Step 1: Write the failing tests**

Add/replace tests that assert:
- crowd battle receives `player_origins` and `ai_origins`
- crowd soldiers and fixed structures start at their slot origins
- runtime remains inactive during deploy
- deploy lasts about 3 seconds before combat starts
- after deploy, soldiers move into formation and runtime starts

**Step 2: Run tests to verify they fail**

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_phase2_battle_deploy.gd`

Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_crowd_deploy_from_board_origins.gd`

Expected: FAIL because crowd mode currently starts immediately from formation and ignores passed origins.

**Step 3: Write minimal implementation**

Implement in `scripts/dev/ten_kings/TenKingsBattleManager.gd`:
- pass slot-origin dictionaries into the crowd path
- add explicit deploy state and timer/tween orchestration for crowd mode

Implement in `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`:
- include slot-origin metadata in generated soldier/fixed-structure dictionaries

Implement in `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`:
- support setup without immediate activation
- expose a `start()` call only after deploy completes

Implement in `scripts/dev/ten_kings/TenKingsCrowdRenderer.gd`:
- render from origin positions during deploy, then interpolate into formation positions

Implement in `scripts/dev/ten_kings/TenKingsPrototype.gd`:
- keep orchestration-only responsibility and provide the real board-slot origins already computed from UI slots

**Step 4: Run tests to verify they pass**

Run both deploy tests and expect PASS.

### Task 5: Final targeted regression run

**Files:**
- Test only; no production files unless regressions are found

**Step 1: Run targeted regression suite**

Run:
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_battle_arena_unobstructed.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_restart_button_contract.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_structure_projectile_duration_scale.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_phase2_board_presentation.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_board_visual_library_contract.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_phase2_battle_deploy.gd`
- `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script scripts/dev/tests/test_ten_kings_crowd_deploy_from_board_origins.gd`

Expected: all PASS.

**Step 2: If a regression appears**

Write a focused failing regression test first, then patch the minimal production code, then re-run the affected test and the targeted suite.
