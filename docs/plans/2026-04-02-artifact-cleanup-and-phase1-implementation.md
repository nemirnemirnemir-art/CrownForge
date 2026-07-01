# Artifact Cleanup And Phase 1 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove broken artifact content from player-facing flows and implement the first real batch of artifact mechanics that already match existing runtime systems.

**Architecture:** Keep `artifact_core.gd` as a facade and add narrow helper modules for new artifact-specific responsibilities instead of appending mixed logic into monoliths. Route new behavior through existing ownership points: artifact pool filtering in reward/trader generators, market behavior in `MapSlotMarket`/`MarketUI`, king ability cooldown behavior in focused helpers, and artifact event wiring through small artifact flow modules.

**Tech Stack:** Godot 4.3, GDScript, headless SceneTree tests under `scripts/dev/tests/`

---

### Task 1: Remove broken artifact entries from player-facing pools

**Files:**
- Modify: `core/artifacts/artifact_catalog.gd`
- Modify: `scripts/ui/rewards/RewardMenuArtifacts.gd`
- Modify: `scripts/ui/rewards/modules/TraderOfferGenerator.gd`
- Test: `scripts/dev/tests/test_artifact_available_pool_filtering.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_artifact_available_pool_filtering.gd` that verifies:
- artifact reward pool excludes `implemented:false` artifacts
- trader artifact pool excludes `implemented:false` artifacts
- removed catalog ids (`boiling_rage`, `demon_wings`, `extra_103`..`extra_109`) are not available

**Step 2: Run test to verify it fails**

Run: `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_available_pool_filtering.gd`

Expected: FAIL because the current reward/trader pools still include unavailable artifacts.

**Step 3: Write minimal implementation**

- Remove `boiling_rage`, `demon_wings`, and `extra_103`..`extra_109` from `artifact_catalog.gd`
- Add a canonical helper on `ArtifactCatalog` for player-available artifact ids
- Make `RewardMenuArtifacts.gd` use the filtered helper
- Make `TraderOfferGenerator.gd` use the filtered helper

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

### Task 2: Add trader artifact support helpers for coupon and market unlocks

**Files:**
- Create: `core/artifacts/ArtifactTraderBenefits.gd`
- Modify: `core/artifacts/artifact_core.gd`
- Test: `scripts/dev/tests/test_artifact_trader_benefits.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_artifact_trader_benefits.gd` that verifies:
- `free_coupon` provides exactly one 100% trader discount charge while active
- spending that charge consumes it
- `suspicious_pile` reports that extended market trades are unlocked while active

**Step 2: Run test to verify it fails**

Run: `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_trader_benefits.gd`

Expected: FAIL because the facade exposes no such behavior yet.

**Step 3: Write minimal implementation**

- Add `ArtifactTraderBenefits.gd` as the narrow owner for trader discount charge and market unlock queries
- Keep `artifact_core.gd` thin with wrapper methods only
- Add wrappers such as `has_trader_free_coupon()`, `consume_trader_free_coupon()`, and `has_extended_market_trades()`

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

### Task 3: Apply free coupon in Trader transaction flow

**Files:**
- Modify: `scripts/ui/rewards/modules/TraderTransactionLogic.gd`
- Test: `scripts/dev/tests/test_trader_transaction_logic_artifact_coupon.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_trader_transaction_logic_artifact_coupon.gd` that verifies:
- when `ArtifactCore.has_trader_free_coupon()` is true, trader purchase costs 0 gold once
- the coupon is consumed through `ArtifactCore.consume_trader_free_coupon()`
- later purchases revert to normal gold spending

**Step 2: Run test to verify it fails**

Run: `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_trader_transaction_logic_artifact_coupon.gd`

Expected: FAIL because trader purchases always spend full gold right now.

**Step 3: Write minimal implementation**

- Update `TraderTransactionLogic.gd` to resolve `ArtifactCore`
- Apply zero-price purchase when a coupon charge is available
- Preserve existing buy flow and affordability refresh behavior

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

### Task 4: Apply suspicious pile to market trade options

**Files:**
- Modify: `scripts/ui/town/MarketUI.gd`
- Modify: `scripts/map_slot/MapSlotMarket.gd`
- Test: `scripts/dev/tests/test_market_ui_artifact_unlocks.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_market_ui_artifact_unlocks.gd` that verifies:
- default market options remain unchanged without artifact unlock
- with `suspicious_pile`, the market includes clay, grapes, and crystal options
- runtime market trade rates support those extra resources

**Step 2: Run test to verify it fails**

Run: `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_market_ui_artifact_unlocks.gd`

Expected: FAIL because the market only exposes the base four trades now.

**Step 3: Write minimal implementation**

- Make `MarketUI` build its trade list dynamically from runtime availability
- Make `MapSlotMarket` expose artifact-aware trade-rate resolution
- Use safe default rates for clay, grapes, and crystal consistent with current market economy balance (1 input -> 1 gold unless repo evidence requires otherwise)

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

### Task 5: Add early artifact runtime helper for gaze/cooldown/capacity/unit-create

**Files:**
- Create: `core/artifacts/ArtifactProgressionFlow.gd`
- Modify: `core/artifacts/artifact_core.gd`
- Modify: `core/king_spell_state.gd`
- Modify: `core/building_upgrade_core.gd`
- Modify: `scripts/map_slot/MapSlotProduction.gd`
- Test: `scripts/dev/tests/test_artifact_progression_flow.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_artifact_progression_flow.gd` that verifies:
- `moon_talisman` reacts to gaze upgrade and grants 3 healer mages
- `royal_rune` reduces all active king ability cooldowns by 25%
- `rune_shard_red/blue/green` reduce only their targeted slot cooldowns by 25%
- `comfy_bed` adds +1 capacity to troop buildings
- `wooden_key` grants +3 wood when a unit is created through the normal unit-production path

**Step 2: Run test to verify it fails**

Run: `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_progression_flow.gd`

Expected: FAIL because these hooks and wrappers do not exist yet.

**Step 3: Write minimal implementation**

- Add `ArtifactProgressionFlow.gd` as the owner for these early runtime hooks
- Keep `artifact_core.gd` wrappers thin
- Add artifact-aware cooldown query helpers in `king_spell_state.gd` without breaking current API
- Add artifact-aware capacity helper in `building_upgrade_core.gd` as a wrapper over the existing capacity system
- Trigger unit-created artifact side effects from the normal production path in `MapSlotProduction.gd`

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

### Task 6: Update documentation

**Files:**
- Modify: `docs/PROJECT_NAVIGATOR.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/project_description.md` (only if runtime scope wording needs refresh)

**Step 1: Update docs**

Document:
- filtered player-available artifact pool behavior
- new artifact trader helper ownership
- new artifact progression/runtime helper ownership
- market artifact unlock path

**Step 2: Verify docs mention the right owners**

Check that the new helper modules and changed behavior are reflected in navigator + architecture.

### Task 7: Final verification

**Files:**
- Verify touched files for indentation consistency

**Step 1: Run targeted tests**

Run:
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_available_pool_filtering.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_trader_benefits.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_trader_transaction_logic_artifact_coupon.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_market_ui_artifact_unlocks.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_artifact_progression_flow.gd`

**Step 2: Run existing nearby regression tests**

Run:
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_market_ui.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_trader_offer_roller.gd`
- `C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_king_spell_state.gd`

**Step 3: Check indentation consistency**

Verify all modified files keep consistent indentation and do not mix tabs/spaces inside the same file.
