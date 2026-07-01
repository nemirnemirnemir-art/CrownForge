# Spell AoE Visuals And Takefromthis Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix area buff/debuff spell visuals above units, upgrade `Immortality` to area enter/leave behavior with floor VFX, clean adopted assets out of `assets/takefromthis/`, and strengthen spell verification coverage.

**Architecture:** Keep spell casting orchestration unchanged and fix behavior inside focused effect scripts/scenes. Use reliable group-plus-radius target collection for snapshot AoE buffs/debuffs, keep `Immortality` as a persistent tracked area effect, author floor animation frames through editor-owned `SpriteFrames`, and keep `takefromthis` as temporary intake only.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene composition, `.tres` resources, headless dev tests, debug spell catalog.

---

## Ownership Rules

1. Controller is the only writer for this master plan and execution log.
2. Worker A owns `WeaknessEffect`, `WrathEffect`, and their dedicated tests.
3. Worker B owns `ImmortalityEffect`, `ImmortalityEffect.tscn`, immortality visual assets, and its dedicated tests.
4. Worker C owns `takefromthis` cleanup outside immortality assets and the `BuildingUpgradeVisuals.gd` runtime path cleanup.
5. Worker D owns spell verification coverage files and must not edit A/B/C feature files.
6. Shared docs (`docs/PROJECT_NAVIGATOR.md`, `docs/ARCHITECTURE.md`) are controller-only at the end.

## Task A: Snapshot AoE Buff/Debuff Reliability

**Files:**
- Modify: `scripts/effects/WeaknessEffect.gd`
- Modify: `scripts/effects/WrathEffect.gd`
- Create/Modify: `scripts/dev/tests/test_weakness_effect.gd`
- Create/Modify: `scripts/dev/tests/test_wrath_effect.gd`

**Intent:**
- Replace overlap-only target acquisition with reliable radius-based acquisition.
- Keep snapshot-on-cast semantics.
- Verify overhead status icons add/remove correctly.

## Task B: Immortality Persistent Area + Floor VFX

**Files:**
- Modify: `scripts/effects/ImmortalityEffect.gd`
- Modify: `scenes/spells/effects/ImmortalityEffect.tscn`
- Create/Modify: `scripts/dev/tests/test_immortality_effect.gd`
- Copy assets to: `assets/vfx/spells_visuals/Immortality/`

**Intent:**
- Convert immortality into area enter/leave tracking for the full duration.
- Keep overhead icon above affected heroes.
- Add per-hero floor animation while inside the area.
- Remove effect and visuals cleanly on leave/end/free.

## Task C: Intake Cleanup

**Files:**
- Modify: `scripts/ui/town/buildings/BuildingUpgradeVisuals.gd`
- Copy assets out of: `assets/takefromthis/`
- Delete adopted files from: `assets/takefromthis/`

**Intent:**
- Remove all runtime dependencies on `assets/takefromthis/`.
- Move `stripe*.png` into logical UI asset ownership.
- Delete already adopted duplicates, excluding immortality intake files until Task B has copied them.

## Task D: Spell Verification Coverage

**Files:**
- Modify: `scripts/dev/verify/verify_scenes.gd`
- Create: `scripts/dev/tests/test_spell_scene_smoke_roster.gd`
- Create/Modify as needed: dedicated verification helper files under `scripts/dev/tests/`

**Intent:**
- Keep smoke verification aligned with the spell roster.
- Add a roster-aware regression check without touching A/B/C feature files.
- Leave final full-suite orchestration to controller.

## Execution Log

- 2026-03-29 Controller: Created master plan, assigned file ownership, and prepared 4 parallel work streams.
- 2026-03-29 Worker A: Updated `scripts/effects/WeaknessEffect.gd` and `scripts/effects/WrathEffect.gd` to use reliable snapshot target collection via group-plus-radius fallback instead of overlap-only targeting. Added `scripts/dev/tests/test_weakness_effect.gd` and `scripts/dev/tests/test_wrath_effect.gd`; both passed in headless runs.
- 2026-03-29 Worker B: Upgraded `scripts/effects/ImmortalityEffect.gd` and `scenes/spells/effects/ImmortalityEffect.tscn` to persistent enter/leave area behavior with per-hero overhead icon and floor VFX. Added `scripts/dev/tests/test_immortality_effect.gd`; copied immortality frames into `assets/vfx/spells_visuals/Immortality/`; test passed.
- 2026-03-29 Worker C: Moved `stripe*.png` into `assets/ui/buildings/upgrade_stripes/`, updated `scripts/ui/town/buildings/BuildingUpgradeVisuals.gd`, and deleted adopted duplicates from `assets/takefromthis/` outside immortality-owned assets.
- 2026-03-29 Worker D: Updated `scripts/dev/verify/verify_scenes.gd` smoke roster and added `scripts/dev/tests/test_spell_scene_smoke_roster.gd` to keep spell configs/debug catalog/scene roster aligned.
- 2026-03-29 Controller: Fixed `scripts/effects/shared/StatusIconService.gd` deferred reflow to avoid calling a nonexistent `_deferred_reflow_hack` method on arbitrary targets.
- 2026-03-29 Controller: Fixed headless compile-time autoload access in `scripts/effects/BanishEffect.gd`, `scripts/effects/DeforestationEffect.gd`, and `scripts/effects/HealingPoolEffect.gd` so smoke verification can catch real scene/script failures instead of relying on global identifiers.
- 2026-03-29 Controller: Removed the last adopted assets from `assets/takefromthis/`; the intake directory is now clean.
- 2026-03-29 Controller: Final verification passed for `test_status_icon_service.gd`, `test_weakness_effect.gd`, `test_wrath_effect.gd`, `test_immortality_effect.gd`, `test_spell_scene_smoke_roster.gd`, `test_debug_spawn_menu_catalog.gd`, `test_path_registry_spell_configs.gd`, and `verify_scenes.gd`.
- 2026-03-29 Controller: Updated `docs/PROJECT_NAVIGATOR.md` and `docs/ARCHITECTURE.md` to document the new spell behavior, verification coverage, and `takefromthis` cleanup state.
