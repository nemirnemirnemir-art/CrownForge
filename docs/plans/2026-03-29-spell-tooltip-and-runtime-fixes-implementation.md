# Spell Tooltip And Runtime Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enlarge the runtime hover spell description tooltip and fix the reported broken spell behaviors across Frailty, Quicksand, Roots, Poison Puddle, Landmine, Tornado, Armageddon, Freeze, and Incineration.

**Architecture:** Keep `GameSceneSpells.gd` as a thin cast orchestrator and repair behavior inside focused effect scripts/scenes/configs. Use scene-authored animation resources where the project requires them, strengthen runtime detection with reliable overlap and radius fallback patterns, and back every bugfix/new effect with targeted headless tests plus smoke verification updates.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene composition, `.tres` spell configs, headless dev tests, spell smoke verification.

---

## Ownership Rules

1. Controller is the only writer for this plan and execution log.
2. Worker A owns runtime hover tooltip changes only.
3. Worker B owns `Frailty`, `Quicksand`, and `Roots` plus their dedicated tests/scenes.
4. Worker C owns `PoisonPuddle`, `Landmine`, and `Tornado` plus their dedicated tests/scenes/configs.
5. Worker D owns `Armageddon`, `Freeze`, and `Incineration` plus their dedicated tests/scenes/configs.
6. Controller owns final doc updates, shared verification updates, and any integration fixes that cross worker boundaries.

## Task A: Runtime Spell Hover Tooltip Enlargement

**Files:**
- Modify: `scripts/ui/spells/SpellPanel.gd`
- Test: create or update dedicated tooltip-focused test under `scripts/dev/tests/`

**Intent:**
- Enlarge the runtime hover popup shown when the mouse hovers a spell slot.
- Double readability of that popup (panel width, title/description font sizing, margins/padding as needed) without changing spell slot sizes.

## Task B: Frailty / Quicksand / Roots

**Files:**
- Modify: `scripts/effects/FrailtyEffect.gd`
- Modify: `scenes/spells/effects/FrailtyEffect.tscn`
- Modify: `scripts/effects/QuicksandEffect.gd`
- Modify: `scripts/effects/RootsEffect.gd`
- Modify: `scenes/spells/effects/RootsEffect.tscn`
- Test: dedicated tests under `scripts/dev/tests/`

**Intent:**
- Fix Frailty visual placement so it lands where targeted.
- Fix Quicksand runtime enemy detection/slow application.
- Fix Roots spawning, target detection, and visible/runtime effect path.

## Task C: Poison Puddle / Landmine / Tornado

**Files:**
- Modify: `scripts/effects/PoisonPuddleEffect.gd`
- Modify: `scripts/effects/LandmineEffect.gd`
- Modify: `scripts/effects/LandmineSpawner.gd`
- Modify: `scenes/spells/effects/LandmineEffect.tscn`
- Modify: `scripts/effects/TornadoEffect.gd`
- Modify: `resources/spells/configs/tornado.tres` if required by root cause
- Test: dedicated tests under `scripts/dev/tests/`

**Intent:**
- Add poison visual state on affected mobs and clean restore.
- Double mine size and fix trigger/explosion behavior so enemies do not walk through.
- Restore Tornado capture, orbit, and damage behavior.

## Task D: Armageddon / Freeze / Incineration

**Files:**
- Modify: `scripts/effects/ArmageddonEffect.gd` and/or `assets/vfx/spells_visuals/Armageddon/*`
- Create: `scripts/effects/FreezeEffect.gd`
- Create: `scenes/spells/effects/FreezeEffect.tscn`
- Modify: `resources/spells/configs/freeze.tres`
- Create: `scripts/effects/IncinerationEffect.gd`
- Create: `scenes/spells/effects/IncinerationEffect.tscn`
- Modify: `resources/spells/configs/incineration.tres`
- Test: dedicated tests under `scripts/dev/tests/`

**Intent:**
- Fix Armageddon start VFX resource loading.
- Implement working Freeze behavior: 1 second full freeze, then 8 second 25% slow with blue visual state.
- Implement working Incineration AoE effect and damage path.

## Execution Log

- 2026-03-29 Controller: Created master plan and assigned 4 independent worker scopes.
- 2026-03-29 Worker A: Enlarged the runtime spell hover tooltip in `scripts/ui/spells/SpellPanel.gd` without changing slot sizes. Added `scripts/dev/tests/test_spell_panel_tooltip_readability_runtime.gd`; targeted tooltip runtime test passed.
- 2026-03-29 Worker B: Fixed `Frailty`, `Quicksand`, and `Roots` runtime behavior and visuals in their owned effect/scene files. Added dedicated tests for all three and passed headless verification.
- 2026-03-29 Worker C: Added poison green visual state to `PoisonPuddleEffect`, enlarged/fixed landmine trigger behavior, and restored tornado capture/orbit/damage reliability. Added dedicated runtime regression test and passed it.
- 2026-03-29 Worker D: Fixed `Armageddon` start VFX loading via authored `SpriteFrames` resource, created working `Freeze` and `Incineration` effects/scenes/config bindings, and passed targeted tests for all three.
- 2026-03-29 Controller: Added `FreezeEffect.tscn` and `IncinerationEffect.tscn` to `scripts/dev/verify/verify_scenes.gd` so smoke verification includes the newly bound spell scenes.
- 2026-03-29 Controller: Updated `docs/PROJECT_NAVIGATOR.md` and `docs/ARCHITECTURE.md` to document the enlarged runtime spell hover tooltip, poison tint, control-spell fixes, and newly implemented `Freeze`/`Incineration` effects.
- 2026-03-29 Controller: Final verification passed for `test_spell_panel_tooltip_readability_runtime.gd`, `test_frailty_effect.gd`, `test_quicksand_effect.gd`, `test_roots_effect.gd`, `test_spell_effects_task_c_runtime.gd`, `test_armageddon_start_vfx_resource.gd`, `test_freeze_effect.gd`, `test_incineration_effect.gd`, `test_spell_scene_smoke_roster.gd`, and `verify_scenes.gd`.
