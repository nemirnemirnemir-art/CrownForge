# Ten Kings Crowd Debug And Stall Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add non-spamming battle diagnostics for the Ten Kings crowd battle and fix the current stalled "run forever without attacking" behavior.

**Architecture:** Keep `TenKingsPrototype.gd` and `TenKingsBattleManager.gd` as orchestrators. Add a focused `TenKingsBattleDebug.gd` helper for throttled diagnostics, keep movement/combat evidence gathering inside `TenKingsCrowdRuntime.gd`, and only then make minimal geometry/runtime fixes proven by tests.

**Tech Stack:** Godot 4.3, GDScript, standalone dev prototype under `res://scripts/dev/ten_kings/`, headless SceneTree tests.

---

### Task 1: Add the debug service and regression scaffolding

**Files:**
- Create: `scripts/dev/ten_kings/TenKingsBattleDebug.gd`
- Create: `scripts/dev/tests/test_ten_kings_crowd_watchdog_reports_stalled_battle.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`

**Step 1: Write the failing watchdog test**
- Create a headless test that sets up a crowd battle with player soldiers and enemy soldiers placed far apart.
- Assert that after a few seconds with both teams still alive and no attacks, the runtime exposes a watchdog event/counter/snapshot instead of silently stalling.

**Step 2: Run the test and verify it fails**
- Run: `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_crowd_watchdog_reports_stalled_battle.gd"`
- Expected: FAIL because no debug watchdog exists yet.

**Step 3: Implement `TenKingsBattleDebug.gd`**
- Create a focused helper with:
  - log levels: `OFF`, `ERRORS`, `SUMMARY`, `COMBAT`, `VERBOSE`
  - feature flags: `battle_enabled`, `crowd_enabled`, `geometry_enabled`, `targeting_enabled`, `watchdog_enabled`
  - throttled `log_once_per_interval(key, interval, message, level)`
  - in-memory counters/snapshots for tests
- Keep output prefix stable: `[TenKingsDebug]`.

**Step 4: Wire the debug service minimally**
- `TenKingsBattleManager.gd`: own a debug helper instance and emit battle-start/battle-end summary hooks.
- `TenKingsCrowdRuntime.gd`: own runtime counters (`attacks_in_window`, `deaths_in_window`, `retargets_in_window`).

**Step 5: Re-run the failing test**
- Run the same headless test.
- Expected: PASS once watchdog evidence exists.

### Task 2: Add runtime heartbeat and stuck diagnostics

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleDebug.gd`
- Test: `scripts/dev/tests/test_ten_kings_crowd_watchdog_reports_stalled_battle.gd`

**Step 1: Write or extend the failing test**
- Add assertions for aggregated heartbeat data:
  - alive counts per team
  - state histogram
  - no-target count
  - stuck count
- Assert these values are exposed through debug snapshots instead of requiring console parsing.

**Step 2: Run test to verify it fails**
- Run the targeted test.
- Expected: FAIL because heartbeat/stuck snapshot fields do not exist yet.

**Step 3: Implement heartbeat aggregation**
- In `TenKingsCrowdRuntime.gd`, aggregate once per second:
  - alive player/enemy
  - `idle`, `walking`, `attacking`, `dying`
  - soldiers with no target
  - average distance to target
- Store latest snapshot on the debug helper.

**Step 4: Implement stuck detection**
- Add soldier runtime fields:
  - `last_position`
  - `last_target_distance`
  - `time_since_progress`
- Mark soldier as stuck if `walking` and target distance barely changes for a threshold.
- Emit throttled warnings plus aggregate stuck counts.

**Step 5: Re-run the test**
- Run targeted watchdog test.
- Expected: PASS with populated snapshot fields.

### Task 3: Add battle-start geometry diagnostics and attack-progress regression test

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_crowd_archer_vs_paladin_progress.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsArenaGeometryService.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`

**Step 1: Write the failing progress test**
- Create a headless `archer vs paladin` crowd battle test.
- Assert that within a bounded time window at least one of these happens:
  - attack event emitted
  - soldier enters `attacking`
  - average distance to target drops below combat threshold
- Current expected result: FAIL if battle stalls forever.

**Step 2: Run test to verify it fails**
- Run: `"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_crowd_archer_vs_paladin_progress.gd"`

**Step 3: Add battle-start geometry summaries**
- Log/store arena rect, spawn zones, formation x positions, unit counts by type, and spawn spread.
- Keep this as one startup summary, not per-frame spam.

**Step 4: Re-run both crowd tests**
- The geometry summaries should now tell us whether the stall is mostly caused by oversized arena/spawn distribution before any fix is applied.

### Task 4: Fix arena sizing and spawn compactness

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Modify: `scripts/dev/ten_kings/TenKingsArenaGeometryService.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- Test: `scripts/dev/tests/test_ten_kings_crowd_archer_vs_paladin_progress.gd`

**Step 1: Adjust runtime arena width**
- Stop using the full viewport width as the effective crowd-battle width.
- Use a capped/intentional width centered in battle space.

**Step 2: Narrow spawn zones**
- Keep player and enemy on their sides but reduce spread so soldiers start in compact formations.

**Step 3: Tighten crowd spawn layouts**
- Bias rows more strongly toward formation lines.
- Keep vertical spread readable without turning the whole viewport into the battlefield.

**Step 4: Re-run the progress test**
- Expected: either PASS or produce improved diagnostics showing the next real blocker.

### Task 5: Fix movement/attack transition stability

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- Test: `scripts/dev/tests/test_ten_kings_crowd_archer_vs_paladin_progress.gd`
- Test: `scripts/dev/tests/test_ten_kings_crowd_battle_does_not_end_early.gd`

**Step 1: Add target progress handling**
- If a walking soldier has no valid target, retarget immediately.
- If a walking soldier remains stuck too long, retarget.

**Step 2: Add attack hysteresis**
- Enter attack at `distance <= attack_range`.
- Return to walking only at `distance > attack_range + buffer`.
- This avoids walk/attack oscillation on the threshold.

**Step 3: Preserve role behavior**
- Melee pushes into contact.
- Ranged stops to fire once in range instead of endlessly micro-adjusting.

**Step 4: Run both crowd tests**
- Expected: no early battle end, and `archer vs paladin` shows real combat progress.

### Task 6: Add renderer diagnostics and update docs

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRenderer.gd`
- Modify: `docs/dev/TEN_KINGS_PROTOTYPE.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`
- Modify: `docs/ARCHITECTURE.md`

**Step 1: Add renderer summaries**
- Report active visuals, pooled visuals, living soldiers, and dropped visuals due to cap.
- Add lightweight state mismatch diagnostics between runtime and renderer.

**Step 2: Update docs**
- Document the new debug helper, heartbeat/watchdog approach, and crowd battle architecture adjustments.

**Step 3: Run final targeted verification**
- `test_ten_kings_crowd_battle_does_not_end_early.gd`
- `test_ten_kings_crowd_watchdog_reports_stalled_battle.gd`
- `test_ten_kings_crowd_archer_vs_paladin_progress.gd`
- `test_ten_kings_battle_flow.gd`

**Step 4: Manual verification**
- Launch `res://scenes/dev/TenKingsPrototype.tscn`.
- Reproduce `archers vs paladins` and verify the debug summaries are readable and the battle reaches real attacks.
