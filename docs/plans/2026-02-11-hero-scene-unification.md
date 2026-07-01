# Hero Scene Unification Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce a strict project-wide rule that every hero/unit id resolves to a dedicated entry `.tscn` scene, with centralized scene resolution and updated canonical documentation.

**Architecture:** Introduce a single hero scene registry utility that resolves normalized unit ids to `res://scenes/heroes/<unit_id>.tscn`. Replace branch-based scene routing in runtime/debug tools with registry calls. Ensure each relevant unit id has a dedicated entry scene (thin wrappers are allowed) while preserving compatibility with legacy ids and clone suffixes.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene resources, markdown docs.

---

### Task 1: Add Hero Scene Registry Core

**Files:**
- Create: `scripts/hero/HeroSceneRegistry.gd`

**Step 1: Write failing verification test plan**

Define expected behaviors for registry API:
- normalize clone ids (`foo_3` -> `foo`)
- normalize aliases (`assasin` -> `assassin`)
- resolve scene path by convention `res://scenes/heroes/<unit_id>.tscn`

**Step 2: Implement minimal registry API**

Implement:
- `resolve_unit_id(hero_id: String) -> String`
- `get_scene_path(hero_id: String) -> String`
- `has_scene(hero_id: String) -> bool`
- `load_scene(hero_id: String) -> PackedScene`
- `get_registered_unit_ids() -> Array[String]`

**Step 3: Verify by script output**

Run a local validation script that loads registry and checks a sample set.

### Task 2: Create Dedicated Entry Hero Scenes

**Files:**
- Create: `scenes/heroes/<unit_id>.tscn` for all required ids from building outputs + active unit configs + legacy compatibility ids.

**Step 1: Generate scene file list**

Use ids from:
- `data/buildings/**.tres` (`produced_unit_id`)
- `data/units/*.tres`
- legacy ids (`swordsman`, `militia`, `assasin`, `archer`, etc.)

**Step 2: Generate thin wrapper scenes**

Each file should instance one base scene (`Peasant/Archer/Slinger/etc.` or `HeroOnField.tscn`).

**Step 3: Verify file existence**

Run script to confirm every required id has `res://scenes/heroes/<unit_id>.tscn`.

### Task 3: Replace Hardcoded Scene Routing

**Files:**
- Modify: `scripts/game_scene/GameSceneHeroes.gd`
- Modify: `scripts/CombatTest.gd`
- Modify: `scripts/ui/DebugSpawnMenu.gd`

**Step 1: Use registry in runtime spawn**

Replace branch routing with `HeroSceneRegistry.load_scene(hero_id)`.

**Step 2: Use registry in debug/test spawns**

Replace hardcoded hero scene dictionary/preloads where applicable.

**Step 3: Verify no branch-based routing remains**

Search and confirm removal of old hero-id `begins_with(...)` scene branches in target files.

### Task 4: Documentation Canon and Strict Rules

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/policies/ENGINEERING_STANDARDS.md`
- Modify: `docs/policies/DOCUMENTATION_POLICY.md`
- Modify: `docs/wiki/systems/HEROES.md`
- Modify: `docs/HERO_ADDING_CHECKLIST.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`

**Step 1: Add strict вЂњone hero id = one scene fileвЂќ policy**

Document canonical path and prohibition of branch-based scene routing.

**Step 2: Add Context7 policy for external API validation**

Define when Context7 is mandatory and what fallback is required if unavailable.

**Step 3: Update implementation references**

Ensure docs point to `scripts/hero/HeroSceneRegistry.gd` and `scenes/heroes/`.

### Task 5: Verification and Delivery

**Files:**
- Modify/Create: optional helper script if needed for validation output

**Step 1: Run deterministic checks**

Check:
- all required unit ids have dedicated scene files
- registry resolves scene paths
- key runtime files compile syntactically

**Step 2: Record evidence in final report**

Provide:
- changed files list
- verification command outputs summary
- explicit statement that docs were updated

