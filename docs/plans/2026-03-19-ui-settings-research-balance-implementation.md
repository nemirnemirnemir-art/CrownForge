# UI Settings, Research Table, and Balance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the broken settings/game-over/economy flows, add the new unit damage flash toggle, rebuild Research Table into a market-style pending-reward producer, and rebalance prophecy/trader behavior without redesigning the whole UI.

**Architecture:** Use focused fixes at authoritative ownership points: persistent settings in `GameSettings`, runtime behavior gates in central managers, map-slot interaction in `MapSlot`, and reward/wave balance in prophecy/trader generators. Avoid one-off UI patches when a central runtime fix exists.

**Tech Stack:** Godot 4.3, GDScript, `.tscn` scene composition, autoload singletons, SceneTree-based dev tests.

---

### Task 1: Update project agent contract and settings persistence

**Files:**
- Modify: `docs/AGENTS.md`
- Modify: `core/game_settings.gd`
- Create: `scripts/dev/tests/test_game_settings_flags.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    var settings := load("res://core/game_settings.gd").new()
    settings.set_damage_numbers_enabled(true)
    settings.set_pause_after_prophecy_enabled(false)
    settings._load_settings()
    assert(settings.is_damage_numbers_enabled() == true)
    assert(settings.is_pause_after_prophecy_enabled() == false)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_game_settings_flags.gd
```

Expected: FAIL because `_load_settings()` does not restore saved values correctly.

**Step 3: Write minimal implementation**

1. In `docs/AGENTS.md`, add two rules:
   - always use relevant superpowers skills
   - if the required action is obvious from request + repo context, do not ask unnecessary questions
2. In `core/game_settings.gd`:
   - fix `_load_settings()` indentation
   - add new boolean key for unit damage flash
   - add getter/setter and persistence for the new key
   - default the new flag to `false`

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_game_settings_flags.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add docs/AGENTS.md core/game_settings.gd scripts/dev/tests/test_game_settings_flags.gd
git commit -m "fix: restore settings persistence and add damage flash flag"
```

### Task 2: Fix OptionsMenu toggles and bottom bar layout

**Files:**
- Modify: `scripts/ui/settings/OptionsMenu.gd`
- Modify: `scenes/ui/settings/OptionsMenu.tscn`
- Create: `scripts/dev/tests/test_options_menu_bottom_bar_layout.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

const OptionsMenuScene := preload("res://scenes/ui/settings/OptionsMenu.tscn")

func _init() -> void:
    var menu := OptionsMenuScene.instantiate()
    get_root().add_child(menu)
    await process_frame
    var main_panel := menu.get_node("CenterRoot/MainPanel") as Control
    var bottom_bar := menu.get_node("CenterRoot/BottomBar") as Control
    assert(bottom_bar.global_position.y >= main_panel.global_position.y + main_panel.size.y - 4.0)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_options_menu_bottom_bar_layout.gd
```

Expected: FAIL because the bottom bar/buttons drift out of the intended container layout.

**Step 3: Write minimal implementation**

1. Add a new toggle node to `OptionsMenu.tscn` for unit damage flash.
2. Wire new onready refs and visual update functions in `OptionsMenu.gd`.
3. Ensure the damage numbers toggle and flash toggle both read/write `GameSettings`.
4. Fix `_recenter_layout()` so it does not fight the VBox-based layout and push `BottomBar` away from `MainPanel`.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_options_menu_bottom_bar_layout.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/ui/settings/OptionsMenu.gd scenes/ui/settings/OptionsMenu.tscn scripts/dev/tests/test_options_menu_bottom_bar_layout.gd
git commit -m "fix: wire settings toggles and anchor options bottom bar"
```

### Task 3: Gate damage popups and add reusable unit hurt flash

**Files:**
- Modify: `scripts/systems/DamagePopupPool.gd`
- Modify: `scripts/mob/components/MobHealth.gd`
- Modify: `scripts/hero/components/HeroFieldHealth.gd`
- Modify: `scripts/hero/HeroOnField.gd`
- Create: `scripts/ui/effects/UnitDamageFlash.gd` if no reusable helper exists
- Create: `scripts/dev/tests/test_damage_popup_respects_settings.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    GameSettings.set_damage_numbers_enabled(false)
    DamagePopupPool.show_damage(Vector2.ZERO, 12, false)
    await process_frame
    var root := get_tree().current_scene
    var container := root.get_node_or_null("DamagePopupContainer")
    assert(container == null or container.get_child_count() == 0)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_damage_popup_respects_settings.gd
```

Expected: FAIL because damage popups are still created with the setting disabled.

**Step 3: Write minimal implementation**

1. In `DamagePopupPool.show_damage(...)`, early-return when `GameSettings.is_damage_numbers_enabled()` is false.
2. Find the working boss/ogre red damage flash pattern.
3. Reuse that pattern through a small helper or a copied focused function for mobs/heroes.
4. Gate the flash by the new `GameSettings` flag.
5. Apply the flash only to nodes that actually have a visible sprite/canvas item to tint.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_damage_popup_respects_settings.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/systems/DamagePopupPool.gd scripts/mob/components/MobHealth.gd scripts/hero/components/HeroFieldHealth.gd scripts/hero/HeroOnField.gd scripts/ui/effects/UnitDamageFlash.gd scripts/dev/tests/test_damage_popup_respects_settings.gd
git commit -m "feat: gate damage popups and add unit hurt flash toggle"
```

### Task 4: Fix game over reset and restore denarii routing

**Files:**
- Modify: `core/castle_core.gd`
- Modify: `core/economy_core.gd`
- Modify: `scripts/map_slot/MapSlotMarket.gd`
- Modify: denarii/trader reward transaction scripts discovered during implementation
- Create: `scripts/dev/tests/test_castle_reset_game_does_not_call_missing_set_gold.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    CastleCore.reset_game()
    await process_frame
    assert(true)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_castle_reset_game_does_not_call_missing_set_gold.gd
```

Expected: FAIL with invalid call to `EconomyCore.set_gold`.

**Step 3: Write minimal implementation**

1. Replace the invalid `EconomyCore.set_gold(0)` call with existing reset API or add a narrow `reset_progress()`/`reset_gold_only()` usage.
2. Audit denarii-producing flows.
3. Route all actual denarii gains through `EconomyCore.add_gold(...)`.
4. In `MapSlotMarket.gd`, ensure trade outputs use the economy API when the output is denarii/gold instead of `ResourceCore.add_resource(...)`.
5. Verify `DenariiDisplay.gd` remains driven by `EventBus.gold_changed`.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_castle_reset_game_does_not_call_missing_set_gold.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add core/castle_core.gd core/economy_core.gd scripts/map_slot/MapSlotMarket.gd scripts/dev/tests/test_castle_reset_game_does_not_call_missing_set_gold.gd
git commit -m "fix: restore economy reset and denarii reward routing"
```

### Task 5: Rebuild Research Table into a market-style pending reward producer

**Files:**
- Modify: `core/buildings/special/ResearchTable.gd`
- Modify: `scripts/map/MapSlot.gd`
- Create: `scenes/ui/town/ResearchTableUI.tscn`
- Create: `scripts/ui/town/ResearchTableUI.gd`
- Modify: game scene reward-open/enqueue call sites if needed
- Create: `scripts/dev/tests/test_research_table_mode_switch_preserves_progress.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

const ResearchTableScript := preload("res://core/buildings/special/ResearchTable.gd")

func _init() -> void:
    var rt := ResearchTableScript.new()
    var cfg := BuildingConfig.new()
    cfg.cycle_time = 100.0
    rt.initialize(null, cfg)
    rt.set_mode(1)
    rt.tick(40.0)
    rt.set_mode(2)
    var data := rt.tick(0.0)
    assert(float(data.get("progress_ratio", 1.0)) < 1.0)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_research_table_mode_switch_preserves_progress.gd
```

Expected: FAIL because switching modes resets or does not preserve shared progress.

**Step 3: Write minimal implementation**

1. Change `ResearchTable.gd` from per-mode reset behavior to shared-progress behavior for the two real modes.
2. Keep `Nothing` as a manual idle mode.
3. Make cycle time exactly `100.0` seconds for both production modes, regardless of prior config if that config is inconsistent with approved UX.
4. Add a Market-style UI scene with three squares.
5. Hook `MapSlot.gd` so clicking a Research Table opens the selector like Market.
6. Add current-mode visual state using `under.png` plus the real reward visual.
7. On completion, enqueue the correct pending reward and keep the same active mode selected.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_research_table_mode_switch_preserves_progress.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add core/buildings/special/ResearchTable.gd scripts/map/MapSlot.gd scenes/ui/town/ResearchTableUI.tscn scripts/ui/town/ResearchTableUI.gd scripts/dev/tests/test_research_table_mode_switch_preserves_progress.gd
git commit -m "feat: add market-style research table mode selector"
```

### Task 6: Exclude temporary summoned units from building/town assignment flows

**Files:**
- Modify: shared assignment/candidate-selection scripts discovered during implementation
- Likely modify: `scripts/map/MapSlot.gd` and/or town/barracks assignment helpers
- Create: `scripts/dev/tests/test_summons_are_excluded_from_assignment_candidates.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    var candidates := []
    candidates.append({"hero_id":"peasant_1","is_summon":false})
    candidates.append({"hero_id":"","is_summon":true})
    var filtered := []
    for c in candidates:
        if not bool(c.get("is_summon", false)):
            filtered.append(c)
    assert(filtered.size() == 1)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_summons_are_excluded_from_assignment_candidates.gd
```

Expected: FAIL after wiring the test into the real candidate provider, because summons are currently not filtered everywhere they should be.

**Step 3: Write minimal implementation**

1. Identify the shared candidate provider for barracks/town/building occupancy.
2. Exclude units marked as summon/temporary from that provider.
3. Reuse existing indicators such as `is_summon`, summon groups, or permanent hero registration where available.
4. Avoid scattering UI-only checks.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_summons_are_excluded_from_assignment_candidates.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/dev/tests/test_summons_are_excluded_from_assignment_candidates.gd [shared assignment files]
git commit -m "fix: exclude summoned units from permanent assignment flows"
```

### Task 7: Cap artifact frequency across full prophecy sets

**Files:**
- Modify: `scripts/resources/ProphecyPatternPool.gd`
- Modify: `scripts/ui/prophecy/modules/ProphecyOptionGenerator.gd`
- Modify: other final option-set assembly scripts if needed
- Create: `scripts/dev/tests/test_prophecy_artifact_cap.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    var artifact_count := 4
    assert(artifact_count <= 3)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_prophecy_artifact_cap.gd
```

Expected: FAIL until the test is replaced with the real generated option set and the generator is capped.

**Step 3: Write minimal implementation**

1. Apply a final-set artifact cap after pattern candidates are generated.
2. Treat artifact and legendary artifact as part of the same global artifact budget unless the code strongly requires separate counters.
3. Implement rarity distribution:
   - common budget: 1
   - rarer budget: 2
   - very rare budget: 3
   - never 4
4. Preserve non-artifact reward diversity when replacing overflow artifacts.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_prophecy_artifact_cap.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/resources/ProphecyPatternPool.gd scripts/ui/prophecy/modules/ProphecyOptionGenerator.gd scripts/dev/tests/test_prophecy_artifact_cap.gd
git commit -m "balance: cap artifact rewards across prophecy sets"
```

### Task 8: Rebalance trader waves against one next-wave pattern

**Files:**
- Modify: `scripts/game_scene/modules/TraderWaveSpawner.gd`
- Modify: `scripts/prophecy/ProphecyWaveGenerator.gd` if needed
- Create: `scripts/dev/tests/test_trader_wave_targets_single_next_pattern_power.gd`

**Step 1: Write the failing test**

```gdscript
extends SceneTree

func _init() -> void:
    var trader_power := 999.0
    var target_power := 300.0
    assert(trader_power <= target_power * 1.2)
    quit()
```

**Step 2: Run test to verify it fails**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_trader_wave_targets_single_next_pattern_power.gd
```

Expected: FAIL until the real generated trader wave is compared against the intended target band.

**Step 3: Write minimal implementation**

1. Generate the trader pattern using the upcoming next-wave single-pattern target, not an unconstrained current-level spike.
2. Clamp the selected pattern to a reasonable power band around one next-wave pattern.
3. Add an extra sanity guard against extreme all-caster outcomes if the generator allows them.

**Step 4: Run test to verify it passes**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_trader_wave_targets_single_next_pattern_power.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/game_scene/modules/TraderWaveSpawner.gd scripts/prophecy/ProphecyWaveGenerator.gd scripts/dev/tests/test_trader_wave_targets_single_next_pattern_power.gd
git commit -m "balance: align trader waves to one next-wave pattern"
```

### Task 9: Update docs and run final verification

**Files:**
- Modify: `docs/PROJECT_NAVIGATOR.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: relevant pages under `docs/wiki/systems/`

**Step 1: Update docs**

Document:
1. the new settings toggle
2. the corrected damage-number behavior
3. Research Table market-style selection and pending-reward flow
4. summon exclusion rule for permanent assignment
5. trader-wave balancing expectations

**Step 2: Run targeted verification**

Run:
```bash
godot4 --headless --path . -s scripts/dev/tests/test_game_settings_flags.gd
godot4 --headless --path . -s scripts/dev/tests/test_options_menu_bottom_bar_layout.gd
godot4 --headless --path . -s scripts/dev/tests/test_damage_popup_respects_settings.gd
godot4 --headless --path . -s scripts/dev/tests/test_castle_reset_game_does_not_call_missing_set_gold.gd
godot4 --headless --path . -s scripts/dev/tests/test_research_table_mode_switch_preserves_progress.gd
godot4 --headless --path . -s scripts/dev/tests/test_summons_are_excluded_from_assignment_candidates.gd
godot4 --headless --path . -s scripts/dev/tests/test_prophecy_artifact_cap.gd
godot4 --headless --path . -s scripts/dev/tests/test_trader_wave_targets_single_next_pattern_power.gd
```

Expected: PASS for all.

**Step 3: Manual Godot verification**

1. Open Options and test both toggles.
2. Confirm `Reload` and `Continue` placement.
3. Trigger combat to verify damage numbers and damage flash behavior.
4. Build Research Table and verify all three mode choices plus pending rewards.
5. Trigger game over and confirm reset succeeds.
6. Inspect trader wave and prophecy reward distributions.

**Step 4: Commit**

```bash
git add docs/PROJECT_NAVIGATOR.md docs/ARCHITECTURE.md docs/wiki/systems/
git commit -m "docs: update settings research table and balance docs"
```

