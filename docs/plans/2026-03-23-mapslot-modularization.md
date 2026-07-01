# MapSlot Modularization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn `MapSlot.gd` into a coordinator that delegates popup/UI flow, building lifecycle, and special runtime mechanics to focused helpers without changing existing slot behavior.

**Architecture:** Keep `MapSlot` as the scene-owned facade and signal surface, but move self-contained feature branches into `scripts/map_slot/*` helpers behind stable wrapper methods. Start with popup/UI flow first because it is the lowest-risk extraction seam, then follow with building lifecycle and special runtime persistence.

**Tech Stack:** Godot 4.3, GDScript, `MapSlot.tscn`, existing `scripts/map_slot/*.gd` helper pattern, headless SceneTree tests in `scripts/dev/tests`

---

### Task 1: Extract popup/UI flow controller

**Files:**
- Create: `scripts/map_slot/MapSlotPopupController.gd`
- Modify: `scripts/map/MapSlot.gd`
- Test: `scripts/dev/tests/test_mapslot_popup_controller.gd`

**Step 1: Write the failing test**

Cover:
- basic construction popup toggles only when ready,
- research popup hides other popups and uses correct title/options,
- popup positioning flips left/right near viewport edges,
- `wall_attack_range`-style hidden logic is not introduced here; controller must only manage popup flow.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_mapslot_popup_controller.gd`
Expected: FAIL because controller does not exist yet.

**Step 3: Write minimal implementation**

Implement a focused popup controller for:
- `_toggle_basic_construction_ui`,
- `_toggle_research_table_ui`,
- `_position_popup_near_slot`,
- close/hide coordination between market/basic/research popups.

Keep existing `MapSlot` methods as wrappers.

**Step 4: Run test to verify it passes**

Run the new popup-controller test.

### Task 2: Extract special-building runtime persistence

**Files:**
- Create: `scripts/map_slot/MapSlotSpecialRuntime.gd`
- Modify: `scripts/map/MapSlot.gd`
- Test: `scripts/dev/tests/test_mapslot_special_runtime.gd`

**Step 1: Write the failing test**

Cover:
- `persist` only when building/special handler support runtime state,
- `restore` only loads non-empty state,
- request-save flag propagates correctly.

**Step 2: Run test to verify it fails**

Run the new runtime-state test headless.

**Step 3: Write minimal implementation**

Move:
- `_persist_special_runtime_state`,
- `_restore_special_runtime_state`

into the helper while preserving current behavior.

**Step 4: Run tests to verify pass**

Run the new runtime-state test and `scripts/dev/tests/test_mapslot_preserves_external_gaze_on_build.gd`.

### Task 3: Extract building lifecycle coordinator

**Files:**
- Create: `scripts/map_slot/MapSlotBuildingLifecycle.gd`
- Modify: `scripts/map/MapSlot.gd`
- Test: `scripts/dev/tests/test_mapslot_building_lifecycle.gd`

**Step 1: Write the failing test**

Cover:
- preserving king/external gaze across `set_building`,
- reset/hide UI on clear,
- setup/clear path keeps slot state consistent.

**Step 2: Run test to verify it fails**

Run the lifecycle test headless.

**Step 3: Write minimal implementation**

Extract orchestration around:
- `set_building`,
- `_clear_building`,
- `_setup_building`,
- `_apply_building_config`

while leaving rendering details and specialized handlers untouched initially.

**Step 4: Run tests to verify pass**

Run lifecycle test plus `scripts/dev/tests/test_mapslot_preserves_external_gaze_on_build.gd`.

### Task 4: Extract click-tool and destroy flow

**Files:**
- Create: `scripts/map_slot/MapSlotInteractionController.gd`
- Modify: `scripts/map/MapSlot.gd`
- Test: `scripts/dev/tests/test_mapslot_interaction_controller.gd`

**Step 1: Write the failing test**

Cover:
- destroy tool delegates correctly,
- default click still emits `slot_clicked`,
- shift-click still emits `move_started`,
- research/basic buildings still open their popup flows instead of generic click.

**Step 2: Run test to verify it fails**

Run the interaction controller test headless.

**Step 3: Write minimal implementation**

Extract:
- `_handle_click_tool`,
- `_execute_destroy`,
- related menu lookup logic.

**Step 4: Run tests to verify pass**

Run interaction test and a focused subset of existing `MapSlot` regressions.
