# Hero Base Scene Deduplication Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove remaining root-vs-entry hero scene filename duplicates while preserving runtime behavior and strict `HeroSceneRegistry` routing.

**Architecture:** Move legacy reusable hero base scenes from `res://scenes/` into a dedicated namespace `res://scenes/hero_bases/`. Keep entry routing canonical through `res://scenes/heroes/<unit_id>.tscn`, and update all hero entry wrappers to reference new base paths. Validate by checking no stale root base references remain in project assets and by headless Godot launch.

**Tech Stack:** Godot 4.3, `.tscn` scene resources, Python one-off verification scripts, headless Godot CLI.

---

### Task 1: Move duplicate base scenes to `hero_bases`

**Files:**
- Modify (move): `scenes/Archer.tscn`
- Modify (move): `scenes/Assassin.tscn`
- Modify (move): `scenes/Peasant.tscn`
- Modify (move): `scenes/SmallBones.tscn`
- Modify (move): `scenes/Light_Legionary.tscn`
- Modify (move): `scenes/Light_Spearman.tscn`
- Modify (move): `scenes/Mercenary.tscn`

**Step 1: Create target namespace**

Run: `mkdir scenes/hero_bases` (if not present).

**Step 2: Move each base scene**

Move files to:
- `scenes/hero_bases/archer_base.tscn`
- `scenes/hero_bases/assassin_base.tscn`
- `scenes/hero_bases/peasant_base.tscn`
- `scenes/hero_bases/small_bones_base.tscn`
- `scenes/hero_bases/light_legionary_base.tscn`
- `scenes/hero_bases/light_spearman_base.tscn`
- `scenes/hero_bases/mercenary_base.tscn`

**Step 3: Verify moved files exist**

Run a file listing for `scenes/hero_bases/*.tscn`.

### Task 2: Rewrite hero entry wrapper base paths

**Files:**
- Modify: `scenes/heroes/*.tscn` (affected subset referencing old root base scenes)

**Step 1: Write a path mapping**

Map old to new:
- `res://scenes/dev/ArcherSample.tscn` -> `res://scenes/hero_bases/archer_base.tscn`
- `res://scenes/Assassin.tscn` -> `res://scenes/hero_bases/assassin_base.tscn`
- `res://scenes/Peasant.tscn` -> `res://scenes/hero_bases/peasant_base.tscn`
- `res://scenes/SmallBones.tscn` -> `res://scenes/hero_bases/small_bones_base.tscn`
- `res://scenes/Light_Legionary.tscn` -> `res://scenes/hero_bases/light_legionary_base.tscn`
- `res://scenes/Light_Spearman.tscn` -> `res://scenes/hero_bases/light_spearman_base.tscn`
- `res://scenes/Mercenary.tscn` -> `res://scenes/hero_bases/mercenary_base.tscn`

**Step 2: Apply bulk replacement in hero wrappers**

Only replace `ext_resource` `PackedScene` paths in `scenes/heroes/*.tscn`.

**Step 3: Verify there are no references to old root base paths outside editor cache files**

Run grep across project (excluding `.godot`) for old paths.

### Task 3: Validation and docs sync

**Files:**
- Modify: `audit/SCENES_MAP.md`

**Step 1: Runtime validation**

Run headless launch:
- `Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer --quit`

Expected: no missing-scene errors for moved base files.

**Step 2: Duplicate-name validation**

Run script to compare `scenes/*.tscn` vs `scenes/heroes/*.tscn` basenames.

Expected: duplicate count is `0`.

**Step 3: Update audit map**

Replace old root base scene entries with `res://scenes/hero_bases/*.tscn` entries.
