# Hero Speed Variance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Give heroes a persistent intrinsic move speed variance using the same `+-20%` variant set as mobs, while keeping temporary effects on `speed_multiplier` untouched.

**Architecture:** Store a new per-hero `intrinsic_speed_multiplier` inside `HeroData` so it persists through existing save/load flows automatically. Apply that multiplier during field bootstrap for regular heroes and during `SmallBones.initialize()` for permanent skeleton heroes that read stats from `HeroCore`.

**Tech Stack:** Godot 4.3, GDScript, SceneTree test scripts.

---

### Task 1: Lock behavior with failing tests

**Files:**
- Create: `scripts/dev/tests/test_hero_intrinsic_speed_variance.gd`
- Read: `core/hero/HeroData.gd`
- Read: `scripts/hero/modules/HeroOnFieldBootstrap.gd`
- Read: `scripts/hero/types/SmallBones.gd`

**Step 1: Write the failing test**

Cover three behaviors:
- `HeroData.create_hero()` assigns `intrinsic_speed_multiplier` from the mob-like variants.
- `HeroData.revalidate_all_heroes()` backfills the field for old save data that lacks it.
- Runtime spawn paths apply the intrinsic multiplier without mutating `speed_multiplier`.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_hero_intrinsic_speed_variance.gd`

Expected: FAIL because the field does not exist yet and runtime spawn speed is unchanged.

### Task 2: Add persistent intrinsic speed storage

**Files:**
- Modify: `core/hero/HeroData.gd`
- Test: `scripts/dev/tests/test_hero_intrinsic_speed_variance.gd`

**Step 1: Add a shared variant list and roll helper**

Add a helper that picks from `[0.80, 0.85, 0.90, 0.95, 1.05, 1.10, 1.15, 1.20]`.

**Step 2: Save it on hero creation**

Store `intrinsic_speed_multiplier` inside each new hero dictionary.

**Step 3: Backfill old heroes**

In `_revalidate_hero_stats()` or `revalidate_all_heroes()`, assign the field when missing without rerolling existing values.

**Step 4: Run the focused test again**

Expected: data-level assertions pass, runtime assertions still fail until spawn application is added.

### Task 3: Apply intrinsic speed on spawn

**Files:**
- Modify: `scripts/hero/modules/HeroOnFieldBootstrap.gd`
- Modify: `scripts/hero/types/SmallBones.gd`
- Test: `scripts/dev/tests/test_hero_intrinsic_speed_variance.gd`

**Step 1: Regular heroes**

After existing base/ranged speed setup, multiply runtime move speed by the stored intrinsic value from `HeroCore.get_hero(hero_id)`.

**Step 2: Permanent SmallBones heroes**

When `SmallBones.initialize(id)` loads from `HeroCore`, apply the same intrinsic multiplier to `move_speed`.

**Step 3: Preserve temporary effects**

Do not modify `hero.speed_multiplier`; it must stay reserved for effects like Wrath/Freeze/Weakness/Quicksand.

**Step 4: Run the focused test again**

Expected: PASS.

### Task 4: Regression verification

**Files:**
- Test: `scripts/dev/tests/test_hero_on_field_bootstrap.gd`
- Test: `scripts/dev/tests/test_herocore_persistence_flow.gd`

**Step 1: Run related tests**

Run:
- `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_hero_intrinsic_speed_variance.gd`
- `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_hero_on_field_bootstrap.gd`
- `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_herocore_persistence_flow.gd`

**Step 2: Confirm green output**

Only claim completion once all three tests pass.
