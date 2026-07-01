# Special UI, Vzor, And Popcap Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the current regression batch around special-building popups, Vzor drag cancellation, battlefield population cap guards, default damage-number settings, and the slot 10 click blocker.

**Architecture:** Keep `MapSlot.gd` as a facade and push popup/input logic into existing helpers (`MapSlotPopupController`, `MapSlotActionUIFlow`, `VzorZoneDragController`) plus one shared battlefield-capacity helper. Do not scatter one-off checks across callers; centralize popup exclusivity, opener visibility, and population-cap queries.

**Tech Stack:** Godot 4.3, GDScript, scene-authored UI, headless `SceneTree` regression tests in `scripts/dev/tests`

---

### Task 1: Special popup exclusivity, opener visibility, and Vzor drag cancel

**Files:**
- Modify: `scripts/ui/gaze/VzorZoneDragController.gd`
- Modify: `scripts/ui/gaze/VzorZone.gd`
- Modify: `scripts/map_slot/MapSlotPopupController.gd`
- Modify: `scripts/map_slot/MapSlotActionUIFlow.gd`
- Modify: `scripts/map_slot/MapSlotBootstrap.gd`
- Modify: `scripts/map/MapSlot.gd`
- Test: `scripts/dev/tests/test_mapslot_popup_controller.gd`
- Test: `scripts/dev/tests/test_mapslot_action_ui_flow.gd`
- Test: `scripts/dev/tests/test_mapslot_bootstrap.gd`
- Create: `scripts/dev/tests/test_vzorzone_drag_controller.gd`

**Step 1: Write failing tests**
- Add a popup-controller regression: opening a popup on one slot closes other grouped special popups, not just same-slot siblings.
- Add an action-ui regression: opener button/badge hides while its popup is visible and comes back when popup closes.
- Add a Vzor regression: `LEFT release` over UI or forced cancel after popup/pause must stop dragging.

**Step 2: Run tests to verify RED**
Run:
```bash
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_popup_controller.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_action_ui_flow.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_bootstrap.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_vzorzone_drag_controller.gd"
```
Expected: FAIL on missing global popup-close, opener-hide, and drag-cancel behavior.

**Step 3: Write minimal implementation**
- Add explicit `cancel_drag()` to `VzorZoneDragController`.
- Process `LEFT release` before UI-block early-return so drag cannot get stuck.
- Make `VzorZone` cancel drag when paused or when special popup overlay blocks interaction.
- Register special popups into a shared group and close all other special popups before opening a new one.
- Add a thin `MapSlot` refresh wrapper and compute opener visibility from `popup.visible` state.

**Step 4: Run tests to verify GREEN**
Re-run the same four commands and confirm PASS.

### Task 2: Battlefield cap guard must count summons for normal deploy

**Files:**
- Create: `core/population/PopulationBattlefieldQuery.gd`
- Modify: `scripts/map_slot/MapSlotProduction.gd`
- Modify: `scripts/ui/town/barracks/BarracksTransferLogic.gd`
- Modify: `scripts/hero/card/HeroCardBattle.gd`
- Test: `scripts/dev/tests/test_population_battlefield_query.gd`
- Create or modify: `scripts/dev/tests/test_barracks_transfer_logic.gd`
- Create or modify: `scripts/dev/tests/test_mapslot_production_population_cap.gd`
- Create or modify: `scripts/dev/tests/test_hero_card_battle_population_cap.gd`

**Step 1: Write failing tests**
- Add a shared query test: active summons count as occupied battlefield slots for normal deploy checks.
- Add a barracks regression: if field is already `>= cap` because of summons, `can_add_to_field()` must be false.
- Add a military-production regression: battlefield auto-deploy must stop when occupied count is already `>= cap`.
- Add a castle deploy regression: `HeroCardBattle` must not send more normal heroes when the field is already full/overfull.

**Step 2: Run tests to verify RED**
Run the new focused tests with Godot headless and confirm they fail for the expected reasons.

**Step 3: Write minimal implementation**
- Centralize battlefield occupancy into `PopulationBattlefieldQuery.gd`.
- Use that helper in barracks, building production, and hero-card deploy paths.
- Do not route summon creation through the normal deploy guard.

**Step 4: Run tests to verify GREEN**
Re-run the focused population-cap tests and confirm PASS.

### Task 3: Damage numbers off by default

**Files:**
- Modify: `core/game_settings.gd`
- Modify: `scripts/systems/DamagePopupPool.gd`
- Modify: `scripts/ui/settings/OptionsMenu.gd`
- Modify: `scripts/dev/tests/test_game_settings_flags.gd`
- Create: `scripts/dev/tests/test_damage_popup_pool_settings_gate.gd`

**Step 1: Write failing tests**
- Extend game-settings test to assert cold-start default for damage numbers is `false`.
- Add a damage-popup-pool regression: when `GameSettings` is absent/unavailable, runtime fallback matches the same default and does not assume `true`.

**Step 2: Run tests to verify RED**
Run the two focused tests and confirm failure.

**Step 3: Write minimal implementation**
- Change default in `GameSettings` to `false`.
- Align `OptionsMenu` and `DamagePopupPool` fallback behavior with the same source of truth.

**Step 4: Run tests to verify GREEN**
Re-run the focused settings tests and confirm PASS.

### Task 4: Slot 10 click blocker

**Files:**
- Modify: `scripts/map_slot/MapSlotBootstrap.gd`
- Optionally modify: `scripts/ui/town/barracks/BarracksTooltips.gd` (only if tests/evidence still show overlap after slot-local fix)
- Test: `scripts/dev/tests/test_mapslot_bootstrap.gd`
- Create: `scripts/dev/tests/test_mapslot_slot_ui_passthrough.gd`

**Step 1: Write failing tests**
- Add a bootstrap/UI passthrough regression: slot-local unit/durability labels must not intercept clicks.
- If needed, add a layout assertion for the slot-local unit UI offset.

**Step 2: Run tests to verify RED**
Run the focused slot-ui tests and confirm failure.

**Step 3: Write minimal implementation**
- Set slot-local unit/durability overlays to `mouse_filter = IGNORE`.
- Apply the requested right shift if the slot-local UI still visually covers slot content after the passthrough fix.
- Only touch `BarracksTooltips.gd` if remaining evidence shows the blocker is the floating unit tooltip, not slot-local overlays.

**Step 4: Run tests to verify GREEN**
Re-run the slot-ui tests and confirm PASS.

### Task 5: Documentation update and focused verification

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`

**Step 1: Update docs**
- Record the special-popup exclusivity contract.
- Record opener-visibility contract.
- Record the battlefield-cap rule: summons may exceed cap, normal deploy may not.
- Record damage-number default ownership under `GameSettings`.

**Step 2: Run focused verification suite**
Run:
```bash
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_popup_controller.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_action_ui_flow.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_bootstrap.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_vzorzone_drag_controller.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_population_battlefield_query.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_barracks_transfer_logic.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_production_population_cap.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_hero_card_battle_population_cap.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_game_settings_flags.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_damage_popup_pool_settings_gate.gd"
"C:\Godot\Godot_v4.3-stable_win64.exe" --headless -s "res://scripts/dev/tests/test_mapslot_slot_ui_passthrough.gd"
```
Expected: all focused regressions PASS.
