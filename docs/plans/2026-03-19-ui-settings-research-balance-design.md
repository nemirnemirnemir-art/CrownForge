# UI, Settings, Research Table, and Balance Design

Date: 2026-03-19
Status: Approved

## Scope

This design covers the following requested changes:

1. Add project-level agent rules to always use relevant superpowers skills and avoid unnecessary clarification when the intended action is already obvious.
2. Fix the non-working `Show Damage Numbers` setting.
3. Add a new settings toggle, default OFF, that enables red damage flash feedback on units that take damage, reusing the boss-style hurt flash behavior.
4. Fix OptionsMenu layout so `Reload` and `Continue` remain under the main menu panel rather than drifting to the left side of the screen.
5. Restore denarii/gold gain logic where it was broken by inconsistent reward/resource routing.
6. Reduce artifact frequency across prophecy pattern sets so artifact count is globally constrained per full set of patterns.
7. Rework Research Table into a market-style mode selector with persistent mode, shared progress, and pending-reward output.
8. Ensure spell-summoned units are excluded from town/building assignment logic intended only for permanently hired units.
9. Fix the game-over reset flow crash caused by an invalid economy API call.
10. Rebalance trader waves so a trader wave is approximately equal in power to one pattern from the upcoming next wave, not an oversized spike.

## Goals

1. Fix broken settings behavior at the root cause instead of applying UI-only patches.
2. Keep scene ownership in `.tscn` files and behavior in focused scripts.
3. Avoid unrelated refactors while touching central systems.
4. Preserve existing player-facing UX patterns where they already work well, especially Market-like selection and pending reward flows.

## Non-Goals

1. Full redesign of the settings menu art/layout.
2. Full rewrite of prophecy generation architecture.
3. Full rewrite of map-slot interaction or town population systems.
4. Reworking all summon behaviors beyond the filtering needed for assignment/building logic.

## Approved UX Decisions

### Settings

1. `Show Damage Numbers` remains a toggle in Options.
2. A new toggle is added for unit damage flash behavior.
3. The new toggle defaults to OFF.
4. `Reload` and `Continue` stay visually attached to the lower panel under the main options panel.

### Research Table

1. Clicking the building opens a Market-style selector.
2. The selector contains exactly three choices:
   - `Nothing`
   - `Basic Production`
   - `Levy Barracks`
3. On initial construction, the active mode is `Nothing`.
4. The building uses `under.png` as a background under the current mode visual.
5. The visual for `Basic Production` and `Levy Barracks` should use the real reward visuals already used by prophecy/reward presentation.
6. Producing a reward does not change the current mode.
7. Selecting `Nothing` is manual; it is not forced after production completes.
8. `Basic Production` and `Levy Barracks` share the same 100 second cycle and switching between them preserves progress.
9. Output is delivered as a pending reward and opened through the same delayed reward flow as other reward cards.
10. Research Table must not inject random recipes directly into the normal building reward pools.

## Root Causes Identified

### 1. Damage Numbers Setting

`GameSettings._load_settings()` currently returns early on load failure correctly, but the actual settings application lines are incorrectly indented under the failure branch. This means saved UI settings are not restored on successful loads.

### 2. Denarii Logic

The project mixes economy-style denarii/gold handling with resource-style gain in some places. UI such as `DenariiDisplay` listens to `EconomyCore`, so any feature that grants denarii via resource APIs or incorrect ids will not appear correctly.

### 3. Game Over Crash

`CastleCore.reset_game()` calls `EconomyCore.set_gold(0)`, but `EconomyCore` does not expose `set_gold`. This causes the invalid-call crash after game over.

### 4. Research Table Missing UX

`ResearchTable.gd` currently supports only internal mode/timer logic. It does not yet provide the map-slot interaction UX, mode selector UI, persisted shared progress behavior, or visual presentation the user described.

### 5. Trader Wave Overtuning

`TraderWaveSpawner` currently generates a pattern by direct level generation without constraining it to the intended вЂњsingle next-wave patternвЂќ target power.

### 6. Artifact Overfrequency

Artifact availability is currently driven by local pattern generation rules rather than a final-set global cap. This allows artifact rewards to appear too often across a full pattern selection set.

## Architecture and Implementation Strategy

## 1. Agent Rules and Project Contract

### Files

- `docs/AGENTS.md`

### Changes

Add project-level instructions:

1. Always use relevant superpowers skills for tasks in this repository.
2. If the intended action is already clear from the user request and repository context, do not ask unnecessary clarification questions.

These are documentation/policy changes only.

## 2. Settings and Runtime Damage Feedback

### Files

- `core/game_settings.gd`
- `scripts/ui/settings/OptionsMenu.gd`
- `scenes/ui/settings/OptionsMenu.tscn`
- damage feedback call sites/scripts discovered during implementation

### Changes

#### Persistence

1. Fix `_load_settings()` indentation so saved values are actually read.
2. Add a new boolean setting key for unit damage flash feedback.
3. Default the new damage flash setting to `false`.

#### OptionsMenu

1. Bind the existing damage numbers toggle to the corrected persisted state.
2. Add a second toggle for damage flash.
3. Keep the same visual style as existing toggles.

#### Runtime Gate for Damage Numbers

1. Centralize the decision to show popup damage numbers.
2. `DamagePopupPool.show_damage(...)` should no-op when the setting is disabled.
3. Existing call sites should not each need local toggle checks.

#### Runtime Gate for Red Damage Flash

1. Reuse the boss/ogre-style hurt flash pattern for units/heroes.
2. Apply the effect only when the new setting is enabled.
3. Keep the effect visual-only; no gameplay change.

## 3. Settings Menu Layout

### Files

- `scenes/ui/settings/OptionsMenu.tscn`
- `scripts/ui/settings/OptionsMenu.gd`

### Changes

1. Keep `Continue` and `Reload` inside `BottomBar`.
2. Fix recentering logic so container layout remains authoritative and the bottom bar stays under the main panel.
3. Avoid absolute repositioning that fights the `VBoxContainer` hierarchy.

## 4. Denarii / Gold Flow

### Files

- likely `core/economy_core.gd`
- market/trader/reward transaction scripts
- any building scripts or reward handlers using the wrong API/path

### Changes

1. Treat denarii display as economy-backed.
2. Ensure all denarii-giving actions route into `EconomyCore.add_gold(...)`.
3. Remove/replace any invalid resource ids or resource-based denarii grants.
4. Verify UI updates still rely on `EventBus.gold_changed`.

## 5. Prophecy Artifact Distribution

### Files

- `scripts/resources/ProphecyPatternPool.gd`
- prophecy option generation/final set assembly scripts

### Changes

Apply global artifact caps to a full generated pattern set:

1. Most cases: exactly or at most 1 artifact-type reward across the whole set.
2. Rarer cases: allow 2 artifact-type rewards across the whole set.
3. Very rare cases: allow 3 artifact-type rewards across the whole set.
4. Never allow 4.

Artifact-type here includes both normal and legendary artifacts unless implementation evidence requires separate caps.

The cap should be applied at the final option-set construction layer so local generation randomness cannot exceed the global rule.

## 6. Research Table

### Files

- `core/buildings/special/ResearchTable.gd`
- `scripts/map/MapSlot.gd`
- likely scene/UI helpers already used by Market
- reward presentation helpers if needed
- pending reward open/enqueue call sites in GameScene

### Changes

#### Data/logic

1. Keep three modes: `Nothing`, `Basic Production`, `Levy Barracks`.
2. Use a single shared progress value for the two real research modes.
3. Preserve progress when switching between `Basic Production` and `Levy Barracks`.
4. Reset timer only when switching to `Nothing` if needed by approved behavior.
5. Cycle time is fixed at 100s shared between both researchable outputs.

#### UI/interaction

1. Clicking the building opens a Market-style selector anchored to the slot.
2. The selector contains exactly three squares.
3. The slot button/visual shows `under.png` plus the current mode icon.
4. `Nothing` is shown initially.

#### Reward output

1. On completion, enqueue a pending reward matching the active mode.
2. Use existing pending reward methods already exposed on the game scene.
3. Do not add these rewards directly into random global building pools.

## 7. Summoned Unit Filtering

### Files

- hero/unit assignment scripts discovered during implementation
- any map-slot, barracks, or town selectors that accept unit candidates

### Changes

1. Exclude temporary spell summons from systems intended for permanently hired units.
2. Use existing markers where available, e.g. `is_summon`, summon groups, or empty `hero_id` conventions.
3. Apply filtering at shared candidate selection points, not by patching every UI individually.

## 8. Game Over Reset

### Files

- `core/castle_core.gd`
- related reset helpers if needed

### Changes

1. Replace invalid `EconomyCore.set_gold(0)` call.
2. Use existing reset API or add a narrow economy reset helper only if necessary.
3. Ensure the scene reload still occurs after state reset.

## 9. Trader Wave Balance

### Files

- `scripts/game_scene/modules/TraderWaveSpawner.gd`
- wave generation utilities if needed

### Changes

1. Trader wave enemy power should be aligned to roughly one pattern from the next wave.
2. Avoid full-wave or overstacked caster spikes.
3. Keep trader rewards unchanged unless balancing evidence requires otherwise.

## Error Handling

1. New settings must safely fall back to defaults if config keys are missing.
2. Research Table UI should fail gracefully if reward icons or UI helper scenes are missing.
3. Pending reward enqueue calls should remain guarded by `has_method` checks where the existing code uses them.
4. Summon filtering should fail open only for truly permanent units, never by accidentally allowing all temporary summons.

## Testing and Verification

1. Launch game with existing settings file and confirm damage settings load correctly.
2. Toggle damage numbers OFF and verify no popup numbers appear.
3. Toggle unit damage flash ON and verify regular units/heroes flash red like boss-style damage feedback.
4. Open settings and confirm `Reload` and `Continue` are positioned under the main panel.
5. Trigger denarii gain and confirm `DenariiDisplay` updates.
6. Generate prophecy option sets repeatedly and confirm artifact count across a full set never exceeds 3 and usually stays at 1.
7. Build Research Table and confirm:
   - initial mode is `Nothing`
   - clicking opens 3-mode selector
   - switching between production and levy preserves progress
   - completion adds pending reward
   - mode remains selected after completion
8. Confirm summoned units cannot be assigned to town/barracks/building occupancy paths intended for hired units.
9. Trigger game over and confirm no invalid-call crash occurs.
10. Inspect trader waves around later stages and confirm they are closer to one next-wave pattern instead of extreme spikes.

## Documentation Updates Required During Implementation

If mechanics are changed, update at minimum:

- `docs/PROJECT_NAVIGATOR.md`
- `docs/ARCHITECTURE.md`
- relevant system pages under `docs/wiki/systems/`

Potential system docs likely affected:

- UI/settings documentation
- prophecy/rewards documentation
- building/infrastructure or map-slot flow documentation

## Recommended Execution Order

1. Fix settings persistence and add new flash setting.
2. Fix options layout.
3. Fix game over economy reset.
4. Fix denarii routing.
5. Implement runtime damage popup/flash gating.
6. Implement Research Table UX and pending reward flow.
7. Implement summon filtering.
8. Apply artifact distribution cap.
9. Rebalance trader wave generation.
10. Update documentation and verify all touched flows.

