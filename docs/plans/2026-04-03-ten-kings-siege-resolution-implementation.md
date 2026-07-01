# Ten Kings Siege Resolution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Ten Kings battles visually resolve through a short siege/chase window after field victory instead of ending immediately when one side loses all non-building troops.

**Architecture:** Keep the battle manager responsible for battle presentation state only. Split the old coarse chase handling into an explicit field-result lock plus siege-resolution phase that retargets winners to the losing castle, lets defender buildings keep shooting, and emits `battle_ended` only after castle contact or a short timeout.

**Tech Stack:** Godot 4.3, GDScript, prototype scene-tree tests under `scripts/dev/tests/`

---

### Task 1: Add a failing siege regression test

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_phase2_siege_resolution.gd`
- Modify: none
- Test: `scripts/dev/tests/test_ten_kings_phase2_siege_resolution.gd`

**Step 1: Write the failing test**

Cover one tight behavior bundle: after field victory is locked, a winning troop chases the losing castle, defender buildings keep a valid siege target, and `battle_ended` waits for castle contact instead of firing immediately.

**Step 2: Run test to verify it fails**

Run: `"C:/Godot/Godot_v4.3-stable_win64.exe" --headless --path "C:/Godot/clickcer" --script "res://scripts/dev/tests/test_ten_kings_phase2_siege_resolution.gd"`

Expected: FAIL because the current chase phase does not retarget defender buildings and only ends on timeout.

### Task 2: Implement explicit siege resolution in BattleManager

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Test: `scripts/dev/tests/test_ten_kings_phase2_siege_resolution.gd`

**Step 1: Add explicit state**

Track field-result lock, siege timer, siege winner, losing castle node, and whether siege resolution already completed.

**Step 2: Lock field result without ending battle**

When one side has no living non-building troops, enter siege once and stop normal field-end re-evaluation from re-triggering.

**Step 3: Retarget siege participants**

Force surviving winning mobile units onto the losing castle and put them into castle-chase movement. Allow losing buildings to retarget nearest surviving attackers during siege.

**Step 4: Resolve siege**

End battle when an attacker reaches castle range, otherwise fall back to the short timeout.

**Step 5: Re-run focused test**

Run: `"C:/Godot/Godot_v4.3-stable_win64.exe" --headless --path "C:/Godot/clickcer" --script "res://scripts/dev/tests/test_ten_kings_phase2_siege_resolution.gd"`

Expected: PASS

### Task 3: Verify prototype still boots cleanly

**Files:**
- Modify: none
- Test: `scenes/dev/TenKingsPrototype.tscn`

**Step 1: Run required verification**

Run: `"C:/Godot/Godot_v4.3-stable_win64.exe" --headless --path "C:/Godot/clickcer" --scene "res://scenes/dev/TenKingsPrototype.tscn" --quit-after 2`

Expected: clean startup with no script errors or warnings introduced by the siege-flow change.
