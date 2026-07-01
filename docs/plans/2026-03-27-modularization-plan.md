# Project-Wide Modularization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn the remaining large gameplay, UI, and autoload scripts into facade-style orchestrators that delegate focused behavior to narrow modules without breaking existing scene contracts.

**Architecture:** Keep scene roots and autoloads as stable public entrypoints, but move editor tooling, UI routing, economy rules, reward execution, validation rules, spawn flow, and repeated hero/spell helpers into dedicated modules. Prefer delegation wrappers over rewrites, batch related extractions together, and use focused regression tests before and after each extraction.

**Tech Stack:** Godot 4.3, GDScript, existing helper-module patterns under `scripts/game_scene/`, `scripts/map_slot/`, `core/hero/`, `core/town/`, headless SceneTree tests in `scripts/dev/tests`

---

## Execution Log

Use this section as the single source of truth for parallel execution status. Only the controller agent should update this section after reviewing each agent result, so reports do not collide.

### Batch A - `BuildingRegistry.gd` / Tasks 1-2

- Status: partial
- Agent scope: `BuildingScaleInspector`, `BuildingCostService`, `BuildingIconResolver`, related tests, `BuildingRegistry.gd`
- Done:
  - added `core/buildings/BuildingScaleInspector.gd`
  - added `core/buildings/BuildingCostService.gd`
  - added `core/buildings/BuildingIconResolver.gd`
  - updated `core/buildings/BuildingRegistry.gd` to delegate scale/cost/icon responsibilities through wrappers
  - added `scripts/dev/tests/test_building_scale_inspector.gd`
  - added `scripts/dev/tests/test_building_cost_service.gd`
  - added `scripts/dev/tests/test_building_icon_resolver.gd`
  - targeted RED/GREEN cycle reported PASS for all 3 new tests
- Stopped at:
  - docs update intentionally deferred
  - clean repo-level verification blocked by unrelated pre-existing startup/compile errors outside scope (`HeroRecruitmentFlow`, `hero_core`, `save_core`, `DamagePopupPool`)
  - spec review found one gap: scale-inspector category subgroup order is not explicitly stabilized/tested; add stable category-ordering and extend test coverage for subgroup order
  - fix iteration applied: `BuildingScaleInspector.gd` now enforces canonical subgroup order derived from `CATEGORY_LABELS`, and `test_building_scale_inspector.gd` now proves subgroup order remains stable regardless of input building order
  - spec re-review: compliant
  - quality review found 2 issues: markup percent was hardcoded to `20`, and placed-building counting was too tightly coupled to a hardcoded scene path
  - quality fix iteration applied: `BuildingCostService.gd` now derives markup percent from the configured step and first checks a `_get_map_layout_node()` seam before the legacy scene-path fallback

### Batch B - `WaveRewardMenu.gd` / Tasks 3-4

- Status: partial
- Agent scope: `WaveRewardSubmenuRouter`, `WaveRewardCardBuilder`, `WaveRewardExecutor`, related tests, `WaveRewardMenu.gd`
- Done:
  - added `scripts/ui/rewards/modules/WaveRewardSubmenuRouter.gd`
  - added `scripts/ui/rewards/modules/WaveRewardCardBuilder.gd`
  - added `scripts/ui/rewards/modules/WaveRewardExecutor.gd`
  - updated `scripts/ui/rewards/WaveRewardMenu.gd` to keep scene facade responsibilities and delegate submenu routing / card building / reward execution
  - added `scripts/dev/tests/test_wave_reward_submenu_router.gd`
  - added `scripts/dev/tests/test_wave_reward_card_builder.gd`
  - added `scripts/dev/tests/test_wave_reward_executor.gd`
  - focused regressions reported PASS: `test_wave_reward_menu_prophecy_defaults.gd`, `test_reward_menu_building_category_filters.gd`
- Stopped at:
  - docs update intentionally deferred
  - clean repo-level verification blocked by unrelated pre-existing startup/compile errors outside scope and one unrelated failing test in `test_mine_visual_and_runtime_guards.gd`
  - spec review found two test gaps: add pause-semantics coverage for submenu-open path and add claimed-card-state update coverage for executor/menu interaction
  - fix iteration applied: added interaction regression covering submenu pause semantics and claim-state progression; production fix in `WaveRewardMenu.gd` changed remaining-card counting to ignore already-claimed cards queued for free so the final immediate claim closes correctly
  - spec re-review: compliant
  - quality review found 1 blocker: submenu-open failure can leave a claimed submenu reward stuck if `SceneTree` or `game_scene` is missing and recovery never fires
  - quality fix iteration applied: `WaveRewardSubmenuRouter.gd` now calls `recover_from_wait` before returning on missing `SceneTree` / `game_scene`, and new regression tests cover the missing-host failure path plus clean submenu-claim recovery

### Batch C - `SmallBones.gd` + `HeroOnField.gd` / Task 5

- Status: partial
- Agent scope: `HeroSelectionOutline`, `HeroHurtboxUI`, `HeroAnimationHelper`, related tests, `SmallBones.gd`, `HeroOnField.gd`
- Done:
  - added `scripts/hero/shared/HeroSelectionOutline.gd`
  - added `scripts/hero/shared/HeroHurtboxUI.gd`
  - added `scripts/hero/shared/HeroAnimationHelper.gd`
  - updated `scripts/hero/types/SmallBones.gd`
  - updated `scripts/hero/HeroOnField.gd`
  - added `scripts/dev/tests/test_hero_selection_outline.gd`
  - added `scripts/dev/tests/test_hero_hurtbox_ui.gd`
  - added `scripts/dev/tests/test_hero_animation_helper.gd`
  - focused regression reported PASS: `test_necromancy_skeleton_chase_enemy.gd`
- Stopped at:
  - docs update intentionally deferred
  - clean repo-level verification blocked by unrelated pre-existing startup/compile errors outside scope (`HeroRecruitmentFlow`, `hero_core`, `DamagePopupPool`, `save_core`, `BuildingRegistry` at time of run)
  - spec review found remaining gap: shared animation helper is not the full shared owner for HeroOnField path and does not cover `default`-only fallback used by `small_bones.tscn`; also add test coverage for that asset contract
  - fix iteration applied: `HeroAnimationHelper.gd` now resolves `primary -> fallback -> default`, `HeroOnField.gd` normalizes dual-sprite playback through the shared helper on wrapper path, and new tests cover the real `small_bones.tscn` default-only contract plus HeroOnField shared-helper path
  - spec re-review: compliant
  - quality review: approved with notes only; no blocker found in scoped code
  - current stop point: safe to leave as-is for now; next likely seam is summon bootstrap/runtime cleanup if `SmallBones.gd` grows again

### Batch D - `king_spell_state.gd` / Task 6

- Status: partial
- Agent scope: `SpellAvailabilityChecker`, `SpellUpgradeService`, related tests, `king_spell_state.gd`
- Done:
  - added `core/king_spell/SpellAvailabilityChecker.gd`
  - added `core/king_spell/SpellUpgradeService.gd`
  - updated `core/king_spell_state.gd` to keep runtime state ownership and delegate validation/upgrade logic
  - added `scripts/dev/tests/test_king_spell_availability_checker.gd`
  - added `scripts/dev/tests/test_king_spell_upgrade_service.gd`
  - focused regression reported PASS: `test_kings_statue_reduces_cooldowns_with_crystal.gd`
- Stopped at:
  - docs update intentionally deferred
  - clean repo-level verification blocked by unrelated pre-existing startup/compile errors outside scope (`HeroRecruitmentFlow`, `hero_core`, `DamagePopupPool`, `save_core`)
  - spec review found remaining gap: move upgrade-rule constants and passive requirement rule payloads out of `king_spell_state.gd` into services, and add cooldown-gating coverage to tests
  - fix iteration applied: passive requirement payloads moved into `SpellAvailabilityChecker.gd`, upgrade rule constants/cost table moved into `SpellUpgradeService.gd`, and cooldown gating is now covered via `test_king_spell_state.gd`
  - spec re-review: compliant
  - quality review found 2 blockers: hard compile fragility from direct `CharacterCreationState` identifier use in `king_spell_state.gd`, and non-atomic resource spending in `SpellUpgradeService.gd`
  - quality fix iteration applied: `king_spell_state.gd` now resolves character-creation state dynamically instead of hard class references, and `SpellUpgradeService.gd` now rolls back already-spent resources on mid-transaction debit failure

### Batch E - `MoraleSystem.gd` / Task 7

- Status: partial
- Agent scope: `MoraleCalculator`, `BuildingSlotQuery`, related tests, `MoraleSystem.gd`
- Done:
  - added `scripts/systems/morale/MoraleCalculator.gd`
  - added `scripts/systems/morale/BuildingSlotQuery.gd`
  - updated `scripts/systems/MoraleSystem.gd` to keep event-router/state-facade role and delegate calculation/query helpers
  - added `scripts/dev/tests/test_morale_calculator.gd`
  - added `scripts/dev/tests/test_morale_building_slot_query.gd`
  - focused regression reported PASS: `test_morale_system_wine_consumption.gd`
- Stopped at:
  - docs update intentionally deferred
  - clean repo-level verification blocked by unrelated pre-existing startup/compile errors outside scope (`HeroRecruitmentFlow`, `hero_core`, `DamagePopupPool`, `save_core`)
  - spec review found remaining gap: `_get_warrior_count_on_field()` is still a scene-query concern inside `MoraleSystem.gd`; move it into a query helper and keep facade role narrow
  - fix iteration applied: warrior field scan moved into `BuildingSlotQuery.gd`, `MoraleSystem.gd` now delegates through a thin wrapper, and dedicated facade/query tests were added
  - spec re-review: compliant
  - quality review found 1 blocker: warrior counting uses global `hero` group scan and can overcount off-scene/persistent heroes; query should be scoped to the active scene when possible
  - quality fix iteration applied: `BuildingSlotQuery.gd` now counts only living `hero` group members attached to `tree.current_scene`, and regression coverage includes an off-scene contamination case

### Batch F - `GameSceneWaves.gd` / Task 8

- Status: partial
- Agent scope: `MobSceneRegistry`, `WaveStartFlow`, `MobContainerQuery`, `GameSceneWaves.gd`, `WaveSpawnService.gd`, `TraderWaveSpawner.gd`, `WaveTimerController.gd`, related tests, docs ownership updates
- Done:
  - added `scripts/game_scene/modules/MobSceneRegistry.gd`
  - added `scripts/game_scene/modules/WaveStartFlow.gd`
  - added `scripts/game_scene/modules/MobContainerQuery.gd`
  - updated `scripts/game_scene/GameSceneWaves.gd` to keep lifecycle/facade ownership and delegate mob lookup, wave-start bookkeeping, mob-container iteration, wave interval timing, trader spawn branch, and prophecy spawn iteration through helpers
  - updated `scripts/game_scene/modules/WaveSpawnService.gd`, `scripts/game_scene/modules/TraderWaveSpawner.gd`, `scripts/game_scene/modules/WaveTimerController.gd`
  - added `scripts/dev/tests/test_gamescenewaves_mob_scene_registry.gd`
  - added `scripts/dev/tests/test_gamescenewaves_wave_start_flow.gd`
  - added `scripts/dev/tests/test_gamescenewaves_mob_container_query.gd`
  - added focused helper regressions for `ProphecyWaveSpawner`, `TraderWaveSpawner`, and `WaveTimerController`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md` for new GameSceneWaves ownership split
- Stopped at:
  - initial spec review found one blocker: `WaveStartFlow` reset only a temporary facade copy and did not clear authoritative `_wave_state`, which risked reward/count carry-over between waves
  - spec fix iteration applied: `WaveStartFlow.gd` now updates both facade state and authoritative wave state; `GameSceneWaves.gd` resyncs facade fields from `_wave_state`, and `test_gamescenewaves_wave_start_flow.gd` now proves no carry-over for counts/rewards/alive ids
  - spec re-review: compliant
  - quality review found 4 notes: direct reads of `ProphecyWaveSpawner` private fields, missing direct tests for `TraderWaveSpawner` and `WaveTimerController`, unused `RewardPresentationRegistryScript` residue in `GameSceneWaves.gd`, and a confusing compatibility flag in `WaveSpawnService.gd`
  - quality fix iteration applied: `ProphecyWaveSpawner.gd` now exposes narrow getters for selection-pending/display-index state, `GameSceneWaves.gd` uses those getters, targeted tests were added for `TraderWaveSpawner` / `WaveTimerController` / `ProphecyWaveSpawner`, and `WaveSpawnService.gd` kept backward-compatible `spawn_mob_scene()` signature while removing duplicate mob-scene lookup ownership
  - quality re-review: approved
  - scoped verification PASS: `test_gamescenewaves_mob_scene_registry.gd`, `test_gamescenewaves_wave_start_flow.gd`, `test_gamescenewaves_mob_container_query.gd`, `test_gamescenewaves_spawn_service.gd`, `test_gamescenewaves_trader_wave_spawner.gd`, `test_gamescenewaves_wave_timer_controller.gd`, `test_gamescenewaves_safe_singleton_lookup.gd`
  - clean repo-level verification still blocked by unrelated pre-existing startup/compile noise outside scope (`HeroRecruitmentFlow`, `hero_core`, `save_core`, `DamagePopupPool`)

### Batch G1 - `GameScene.gd` + `GameSceneBootstrap.gd` / Task 9a

- Status: partial
- Agent scope: `GameSceneProcessLoop`, `GameSceneBootstrap.gd`, `GameScene.gd`, related tests, docs ownership updates
- Done:
  - added `scripts/game_scene/GameSceneProcessLoop.gd`
  - updated `scripts/game/GameScene.gd` to delegate `_process()` routing and keep compatibility wrapper for `_setup_wave_timer_bar()`
  - updated `scripts/game_scene/GameSceneBootstrap.gd` to own wave-timer bootstrap/setup and process-loop wiring
  - added `scripts/dev/tests/test_gamescene_process_loop.gd`
  - updated `scripts/dev/tests/test_gamescene_bootstrap.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - spec review found one blocker: wave-timer setup still lived inside `GameScene.gd` and bootstrap only proxied a callback
  - spec fix iteration applied: ownership of wave-timer setup moved into `GameSceneBootstrap.gd`, regression coverage expanded, and `GameScene.gd` kept a thin compatibility wrapper only
  - quality review: approved with one note; current tests do not directly prove bootstrap-to-facade `_process_loop_manager` hookup through a full `GameScene` runtime boot
  - scoped verification PASS: `test_gamescene_process_loop.gd`, `test_gamescene_bootstrap.gd`

### Batch G2 - `MapSlot.gd` / Task 9b

- Status: partial
- Agent scope: `MapSlotRecoveryFlow`, `MapSlot.gd`, related tests, docs ownership updates
- Done:
  - added `scripts/map_slot/MapSlotRecoveryFlow.gd`
  - updated `scripts/map/MapSlot.gd` to keep `recover_after_encounter_pause()` as a thin facade wrapper
  - added `scripts/dev/tests/test_mapslot_recovery_flow.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - spec review found 3 gaps: no facade-wrapper regression, no touched-slot assertions through facade path, and no helper fallback coverage when `production_flow == null`
  - spec fix iteration applied: `test_mapslot_recovery_flow.gd` now covers helper fallback, facade delegation, touched-slot behavior for producing regular buildings, vzor animation restart, special/market cases, and non-producing regular recovery
  - quality review initially blocked on test-harness leak noise; follow-up cleanup removed scope-specific `BuildingConfig`/`BuildingCostEntry`/`BuildingProductionEntry` resource warnings and the typed fake-config warning from the test harness
  - quality re-review: approved; remaining `ObjectDB`/orphan `StringName` exit noise is treated as generic harness/project-exit noise rather than a scoped recovery-flow defect
  - scoped verification PASS: `test_mapslot_recovery_flow.gd`

### Batch G3 - `Mob.gd` / Task 9c

- Status: partial
- Agent scope: `Mob.gd`, `MobWallTargetingFlow.gd`, `MobMovement.gd`, `MobBootstrap.gd`, `MobDeathFlow.gd`, related tests, docs ownership updates
- Done:
  - updated `scripts/mob/Mob.gd` to keep facade/wrapper role while delegating wall targeting and death/corpse behavior into existing mob modules
  - updated `scripts/mob/modules/MobWallTargetingFlow.gd`, `scripts/mob/modules/MobBootstrap.gd`, `scripts/mob/modules/MobDeathFlow.gd`
  - updated `scripts/dev/tests/test_mob_wall_targeting_flow.gd`, `scripts/dev/tests/test_mob_death_flow.gd`, `scripts/dev/tests/test_mob_bootstrap.gd`, `scripts/dev/tests/test_mob_wall_attack_stop_distance_override.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - spec review found two blockers: residual wall-rule ownership still lived in `Mob.gd`, and corpse spawn coverage did not prove parent/position through the delegated death path
  - spec fix iteration applied: duplicated wall-rule constants/math were removed from `Mob.gd`, and death-flow coverage now proves corpse routing with parent/position assertions
  - quality review found one blocker: pre-`_ready()` wall-stop overrides were lost because `WaveSpawnService` sets them before `add_child()`
  - quality fix iteration applied: `Mob.gd` now buffers pending wall-stop override state and `MobBootstrap.gd` applies it during bootstrap, restoring spawn-service compatibility without moving wall math back into the facade
  - quality re-review: approved
  - scoped verification PASS: `test_gamescenewaves_spawn_service.gd`, `test_mob_wall_attack_stop_distance_override.gd`, `test_mob_wall_targeting_flow.gd`, `test_mob_death_flow.gd`, `test_mob_bootstrap.gd`, `test_mob_lane_assault_runtime.gd`

### Batch G4 - `hero_core.gd` / Task 9d

- Status: partial
- Agent scope: `HeroCoreNotificationBridge`, `hero_core.gd`, related tests, docs ownership updates
- Done:
  - added `core/hero/HeroCoreNotificationBridge.gd`
  - updated `core/hero_core.gd` to delegate emit-and-save boilerplate through the bridge while keeping thin wrappers in the facade
  - added `scripts/dev/tests/test_hero_core_notification_bridge.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - spec review found one gap: tests covered only the helper in isolation and did not prove facade-wrapper behavior through `hero_core.gd`
  - spec fix iteration applied: `test_hero_core_notification_bridge.gd` now covers `_emit_updated_hero()`, `_emit_updated_hero_and_request_save()`, `update_hero(...)`, and `heal_hero(...)` through the facade path
  - quality review found two blockers: wrappers became silent no-ops if `_notification_bridge` was absent, and null-`hero_data` save behavior was not defined/tested
  - quality fix iteration applied: `hero_core.gd` now preserves fallback wrapper behavior when `_notification_bridge` is unavailable, `HeroCoreNotificationBridge.gd` no longer requests save when `hero_data` is null, and tests cover no-bridge/null-data paths
  - quality re-review: approved
  - scoped verification PASS: `test_hero_core_notification_bridge.gd`, `test_herocore_damage_flow.gd`

### Batch G5 - `HeroOnField.gd` / Task 9e

- Status: partial
- Agent scope: `HeroOnField.gd`, `HeroOnFieldBootstrap.gd`, related tests, docs ownership updates
- Done:
  - updated `scripts/hero/modules/HeroOnFieldBootstrap.gd` to own watchdog creation
  - updated `scripts/hero/HeroOnField.gd` to keep `_setup_watchdog()` as a thin wrapper into bootstrap
  - updated `scripts/dev/tests/test_hero_on_field_bootstrap.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - spec review: compliant
  - quality review found one blocker: `HeroOnField.gd` had a real parse error from mixed indentation, and the test covered only a fake helper host instead of the real facade path
  - quality fix iteration applied: indentation/parse issue was fixed in `HeroOnField.gd`, and `test_hero_on_field_bootstrap.gd` now exercises the real `HeroOnField._setup_watchdog()` wrapper path
  - quality re-review: approved
  - scoped verification PASS: `test_hero_on_field_bootstrap.gd`, `test_hero_on_field_shared_animation_path.gd`

### Batch H - repeated spell effects / Task 10

- Status: partial
- Agent scope: shared spell-effect helpers, `InfernalUnit.gd`, `GroundfireEffect.gd`, `BlindingLightEffect.gd`, `TornadoEffect.gd`, focused tests, docs ownership updates
- Done:
  - added `scripts/effects/shared/SpellEnemyTracker.gd`
  - added `scripts/effects/shared/SpellDamageApplicator.gd`
  - added `scripts/effects/shared/SpellBoundsEnforcer.gd`
  - added `scripts/effects/shared/SpellVisualLifecycle.gd`
  - added `scripts/effects/shared/SpellCaptureOrbitController.gd`
  - updated `scripts/effects/InfernalUnit.gd`, `scripts/effects/GroundfireEffect.gd`, `scripts/effects/BlindingLightEffect.gd`, `scripts/effects/TornadoEffect.gd`
  - updated `scripts/dev/tests/test_spell_enemy_tracker.gd`, `scripts/dev/tests/test_spell_damage_applicator.gd`
  - added `scripts/dev/tests/test_tornado_effect_runtime.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - initial extraction created shared helpers for enemy tracking, damage routing, movement bounds, and fade/lifetime concerns, but spec review found missing bounds/lifetime coverage and incomplete helper adoption
  - spec fix iteration applied: `SpellVisualLifecycle.gd` was wired into `GroundfireEffect.gd` and `InfernalUnit.gd`, bounds/lifetime coverage was added, and `TornadoEffect.gd` orbit math moved into `SpellCaptureOrbitController.gd`
  - quality review then found follow-up blockers: `TornadoEffect.gd` indentation/type regressions, fallback-target call sites that accidentally skipped `enemy`-group actors, and insufficient targeted Tornado runtime coverage
  - quality fix iteration applied: Tornado typing/indentation was corrected, `GroundfireEffect.gd` / `BlindingLightEffect.gd` now opt into `enemy`-group fallback explicitly, `test_tornado_effect_runtime.gd` was added, and `test_spell_enemy_tracker.gd` was isolated so its helper/runtime sections do not contaminate each other
  - spec final: compliant
  - quality re-review: approved
  - scoped verification PASS: `test_spell_enemy_tracker.gd`, `test_spell_damage_applicator.gd`, `test_tornado_effect_runtime.gd`

### Batch I - lower-priority UI cleanup / Task 11

- Status: partial
- Agent scope: prophecy popup controller, trader offer roller, UI facades, focused tests, docs ownership updates
- Done:
  - added `scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd`
  - added `scripts/ui/rewards/modules/TraderOfferRoller.gd`
  - updated `scripts/ui/prophecy/ProphecyMenu.gd` to delegate rewards-info popup and delayed hover-panel hide behavior
  - updated `scripts/ui/rewards/RewardMenuTrader.gd` to delegate trader offer rolling / reroll entrypoints into helper logic
  - updated `scripts/dev/tests/test_prophecy_info_popup_controller.gd`, `scripts/dev/tests/test_trader_offer_roller.gd`
  - updated `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md`
- Stopped at:
  - initial extraction moved prophecy popup and trader rolling logic out of scene roots, but spec review found leftover rolling implementation still living inside `RewardMenuTrader.gd`
  - spec fix iteration applied: `RewardMenuTrader.gd` reroll entrypoints were reduced to thin wrappers around `TraderOfferRoller.gd`, and trader tests were extended to assert wrapper delegation
  - quality review found one runtime blocker: `ProphecyInfoPopupController.handle_card_unhovered()` used the wrong host/timer contract and the old test passed a `SceneTree`, masking the production `Control -> get_tree()` path
  - quality fix iteration applied: the controller now resolves a `SceneTree` from an in-tree `Node` or direct tree host, and `test_prophecy_info_popup_controller.gd` now exercises the real `Control` host path
  - spec final: compliant
  - quality re-review: approved
  - scoped verification PASS: `test_prophecy_info_popup_controller.gd`, `test_trader_offer_roller.gd`

### Final Regression Sweep (Task 12)

- Status: complete
- Date: 27.03.2026
- Scope: all 42 test files created/updated in Tasks 1-11 plus 6 existing regression tests
- Results: **42/42 PASS, 0 failures**
- Batch A-E (Tasks 1-7): 13/13 PASS
- Batch F-G (Tasks 8-9): 17/17 PASS
- Batch H-I (Tasks 10-11) + existing regressions: 12/12 PASS
- Known repo-wide noise: HeroRecruitmentFlow type inference, save_core compile, DamagePopupPool indentation, forge_core init — all pre-existing and outside modularization scope
- Documentation: `docs/ARCHITECTURE.md` and `docs/PROJECT_NAVIGATOR.md` updated throughout execution
- Plan status: **COMPLETE (12/12 tasks)**

### Controller Notes

- Worktree isolation unavailable because `C:\Godot\clickcer` is not a git repository in the current environment.
- Parallel batches must not touch the same files.
- Agent reports are summarized here only after controller review to avoid write conflicts.

---

## Priority Order

1. Tier 1 critical monoliths with zero extracted modules: `BuildingRegistry.gd`, `WaveRewardMenu.gd`, `SmallBones.gd`
2. Tier 2 high-priority autoloads with mixed rules/state: `king_spell_state.gd`, `MoraleSystem.gd`
3. Tier 3 watchlist cleanup: `GameSceneWaves.gd` first, then small cleanup batches in `GameScene.gd`, `MapSlot.gd`, `Mob.gd`, `hero_core.gd`, `HeroOnField.gd`
4. Tier 4 repeated spell/boss patterns
5. Tier 5 lower-priority UI cleanup

---

### Task 1: Extract `BuildingScaleInspector` from `BuildingRegistry.gd`

**Files:**
- Create: `core/buildings/BuildingScaleInspector.gd`
- Modify: `core/buildings/BuildingRegistry.gd`
- Test: `scripts/dev/tests/test_building_scale_inspector.gd`

**Step 1: Write the failing test**

Cover:
- custom inspector property list contains scale override properties for live building ids,
- `_get()` returns saved overrides and default scale fallbacks,
- `_set()` updates overrides and triggers property-list refresh behavior,
- grouping/order logic remains stable for editor use.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_building_scale_inspector.gd`
Expected: FAIL because `BuildingScaleInspector.gd` does not exist yet.

**Step 3: Write minimal implementation**

Move these methods into `BuildingScaleInspector.gd`:
- `_get_property_list`
- `_get`
- `_set`
- `_validate_property`
- `get_placed_building_scale`
- `_get_default_placed_building_scale`
- `_get_buildings_grouped_for_scale_inspector`
- `_get_scale_property_name`
- `_get_building_id_from_scale_property`

Keep `BuildingRegistry.gd` wrappers such as:

```gdscript
func get_placed_building_scale(building_id: String) -> float:
	return _scale_inspector.get_placed_building_scale(
		building_id,
		_buildings_by_id,
		_placed_building_scale_overrides
	)
```

**Step 4: Run test to verify it passes**

Run the new test again.
Expected: PASS.

### Task 2: Extract `BuildingCostService` and `BuildingIconResolver` from `BuildingRegistry.gd`

**Files:**
- Create: `core/buildings/BuildingCostService.gd`
- Create: `core/buildings/BuildingIconResolver.gd`
- Modify: `core/buildings/BuildingRegistry.gd`
- Test: `scripts/dev/tests/test_building_cost_service.gd`
- Test: `scripts/dev/tests/test_building_icon_resolver.gd`

**Step 1: Write the failing tests**

Cover in `test_building_cost_service.gd`:
- `can_afford_building()` matches current ResourceCore rules,
- `pay_for_building()` spends the same resources as before,
- `get_next_build_cost()` keeps artifact multiplier and placed-count scaling intact,
- `get_next_build_markup_percent()` matches current UI display math.

Cover in `test_building_icon_resolver.gd`:
- filesystem scan still builds the same normalized icon lookup,
- missing icon assignment behaves the same,
- string normalization preserves current matching behavior.

**Step 2: Run tests to verify they fail**

Run:
- `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_building_cost_service.gd`
- `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_building_icon_resolver.gd`

Expected: FAIL because both services do not exist yet.

**Step 3: Write minimal implementation**

Move economy logic into `BuildingCostService.gd`:
- `can_afford_building`
- `pay_for_building`
- `get_next_build_cost`
- `get_next_build_markup_percent`
- `get_placed_building_count`
- `_get_artifact_build_cost_multiplier`

Move icon lookup logic into `BuildingIconResolver.gd`:
- `_scan_building_icons`
- `_normalize_key`
- `_try_assign_icon_if_missing`

Keep `BuildingRegistry.gd` as query facade plus recipe management surface.

**Step 4: Run tests to verify they pass**

Run both new tests again.
Expected: PASS.

### Task 3: Extract `WaveRewardSubmenuRouter` from `WaveRewardMenu.gd`

**Files:**
- Create: `scripts/ui/rewards/modules/WaveRewardSubmenuRouter.gd`
- Modify: `scripts/ui/rewards/WaveRewardMenu.gd`
- Test: `scripts/dev/tests/test_wave_reward_submenu_router.gd`

**Step 1: Write the failing test**

Cover:
- each `menu_type` branch opens the same submenu as before,
- submenu-open path keeps waiting state and pause semantics intact,
- unknown submenu type still fails safely,
- no reward execution logic leaks into the router.

**Step 2: Run test to verify it fails**

Run: `"C:\Godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Godot\clickcer" -s scripts/dev/tests/test_wave_reward_submenu_router.gd`
Expected: FAIL because `WaveRewardSubmenuRouter.gd` does not exist yet.

**Step 3: Write minimal implementation**

Move `_open_submenu(menu_type, amount)` into `WaveRewardSubmenuRouter.gd`.

Keep the scene-owned wrapper:

```gdscript
func _open_submenu(menu_type: String, amount: int) -> void:
	_submenu_router.open(menu_type, amount, _get_scene_tree(), _debug_dump_state)
```

**Step 4: Run test to verify it passes**

Run the new router test again.
Expected: PASS.

### Task 4: Extract `WaveRewardCardBuilder` and `WaveRewardExecutor` from `WaveRewardMenu.gd`

**Files:**
- Create: `scripts/ui/rewards/modules/WaveRewardCardBuilder.gd`
- Create: `scripts/ui/rewards/modules/WaveRewardExecutor.gd`
- Modify: `scripts/ui/rewards/WaveRewardMenu.gd`
- Test: `scripts/dev/tests/test_wave_reward_card_builder.gd`
- Test: `scripts/dev/tests/test_wave_reward_executor.gd`

**Step 1: Write the failing tests**

Cover in `test_wave_reward_card_builder.gd`:
- reward payload to card-data mapping stays identical for gold, resources, troops, buildings, spells, artifacts,
- prophecy-default path still produces the same card metadata,
- presentation fallback behavior does not change.

Cover in `test_wave_reward_executor.gd`:
- claiming each reward type triggers the same core/game-scene side effect as before,
- claimed card state still updates correctly,
- menu close/check-all-claimed flow remains scene-owned and is not moved into executor.

**Step 2: Run tests to verify they fail**

Run both new tests headless.
Expected: FAIL because the helper files do not exist yet.

**Step 3: Write minimal implementation**

Move `_build_rewards_for_cards()` into `WaveRewardCardBuilder.gd`.
Move `_on_reward_claimed(reward_type)` into `WaveRewardExecutor.gd`.

Keep `WaveRewardMenu.gd` responsible for:
- `open()` / `close_menu()`,
- `_process()` waiting loop,
- `_create_reward_cards()`,
- collapse button state,
- `_check_all_claimed()`.

**Step 4: Run tests to verify they pass**

Run both tests again.
Expected: PASS.

### Task 5: Extract shared hero UI helpers for `SmallBones.gd` and `HeroOnField.gd`

**Files:**
- Create: `scripts/hero/shared/HeroSelectionOutline.gd`
- Create: `scripts/hero/shared/HeroHurtboxUI.gd`
- Create: `scripts/hero/shared/HeroAnimationHelper.gd`
- Modify: `scripts/hero/types/SmallBones.gd`
- Modify: `scripts/hero/HeroOnField.gd`
- Test: `scripts/dev/tests/test_hero_selection_outline.gd`
- Test: `scripts/dev/tests/test_hero_hurtbox_ui.gd`
- Test: `scripts/dev/tests/test_hero_animation_helper.gd`

**Step 1: Write the failing tests**

Cover:
- selected hero outline visibility still follows EventBus selection,
- hurtbox hover still opens and closes HP tooltip,
- click-select behavior is unchanged,
- animation helper still prefers primary animation name and falls back safely.

**Step 2: Run tests to verify they fail**

Run the three new tests headless.
Expected: FAIL because the shared helpers do not exist yet.

**Step 3: Write minimal implementation**

Extract from `SmallBones.gd` and adapt `HeroOnField.gd` to use the same modules:
- `HeroSelectionOutline`: `_setup_selection_outline`, `_connect_selection_signals`, `_on_hero_selected_for_ui`
- `HeroHurtboxUI`: `_setup_hurtbox_ui_events`, `_on_hurtbox_mouse_enter`, `_on_hurtbox_mouse_exit`, `_on_hurtbox_input_event`
- `HeroAnimationHelper`: `_play_sprite_animation`, `_update_animation`

Keep both root scripts as unit-specific facade/orchestrator scripts.

**Step 4: Run tests to verify they pass**

Run the three new tests plus one focused existing field-hero regression.

### Task 6: Extract `SpellAvailabilityChecker` and `SpellUpgradeService` from `king_spell_state.gd`

**Files:**
- Create: `core/king_spell/SpellAvailabilityChecker.gd`
- Create: `core/king_spell/SpellUpgradeService.gd`
- Modify: `core/king_spell_state.gd`
- Test: `scripts/dev/tests/test_king_spell_availability_checker.gd`
- Test: `scripts/dev/tests/test_king_spell_upgrade_service.gd`

**Step 1: Write the failing tests**

Cover availability checker:
- active ability cooldown/resource gating stays intact,
- passive ability special-case checks still return the same unavailability reasons,
- affordability and spend logic matches current EconomyCore/ResourceCore behavior.

Cover upgrade service:
- upgrade cost progression remains identical,
- purchase fails and succeeds under the same conditions as before,
- active upgrade level mutation is unchanged.

**Step 2: Run tests to verify they fail**

Run the two new tests headless.
Expected: FAIL because helper files do not exist yet.

**Step 3: Write minimal implementation**

Move into `SpellAvailabilityChecker.gd`:
- `can_activate_active_ability`
- `get_active_ability_cost`
- `get_active_ability_resource_status`
- `can_afford_active_ability`
- `get_active_ability_unavailability_reason`
- `can_activate_passive_ability`
- `get_passive_ability_unavailability_reason`
- `spend_active_ability_cost`

Move into `SpellUpgradeService.gd`:
- `can_upgrade_active_spells`
- `get_next_upgrade_cost`
- `try_purchase_active_upgrade`

Keep `king_spell_state.gd` focused on runtime state ownership.

**Step 4: Run tests to verify they pass**

Run both tests again.
Expected: PASS.

### Task 7: Extract `MoraleCalculator` and reusable `BuildingSlotQuery` from `MoraleSystem.gd`

**Files:**
- Create: `scripts/systems/morale/MoraleCalculator.gd`
- Create: `scripts/systems/morale/BuildingSlotQuery.gd`
- Modify: `scripts/systems/MoraleSystem.gd`
- Test: `scripts/dev/tests/test_morale_calculator.gd`
- Test: `scripts/dev/tests/test_morale_building_slot_query.gd`

**Step 1: Write the failing tests**

Cover calculator:
- total morale and breakdown output remain unchanged,
- wine stock bonus, tavern bonus, arena bonus, debug bonus all combine identically,
- damage and productivity modifiers derived from total morale still match current behavior.

Cover slot query:
- tavern detection still matches current active-slot semantics,
- arena morale bonus lookup still matches current MapLayout scanning behavior.

**Step 2: Run tests to verify they fail**

Run both tests headless.
Expected: FAIL because helper files do not exist yet.

**Step 3: Write minimal implementation**

Move pure calculation into `MoraleCalculator.gd`:
- body of `calculate_morale`
- `_get_wine_morale_bonus`
- `_get_wine_consumption_multiplier`
- `_get_additional_wine_stock_morale_bonus`

Move scene-scan queries into `BuildingSlotQuery.gd`:
- `_has_active_tavern`
- `_get_active_arena_morale_bonus`

Keep `MoraleSystem.gd` as event router plus state facade.

**Step 4: Run tests to verify they pass**

Run both tests again.
Expected: PASS.

### Task 8: Finish the second extraction batch for `GameSceneWaves.gd`

**Files:**
- Create: `scripts/game_scene/modules/MobSceneRegistry.gd`
- Create: `scripts/game_scene/modules/WaveStartFlow.gd`
- Create: `scripts/game_scene/modules/MobContainerQuery.gd`
- Modify: `scripts/game_scene/modules/WaveSpawnService.gd`
- Modify: `scripts/game_scene/modules/TraderWaveSpawner.gd`
- Modify: `scripts/game_scene/modules/WaveTimerController.gd`
- Modify: `scripts/game_scene/GameSceneWaves.gd`
- Test: `scripts/dev/tests/test_gamescenewaves_mob_scene_registry.gd`
- Test: `scripts/dev/tests/test_gamescenewaves_wave_start_flow.gd`
- Test: `scripts/dev/tests/test_gamescenewaves_mob_container_query.gd`

**Step 1: Write the failing tests**

Cover:
- mob scene lookup and goblin fallback,
- wave-start state bookkeeping and signal timing,
- alive mob query / clear / wall-stop-distance iteration behavior,
- existing spawn and reward behavior remains unchanged after delegation.

**Step 2: Run tests to verify they fail**

Run the three new tests plus the existing safe-singleton test.
Expected: FAIL for new tests because helpers do not exist yet.

**Step 3: Write minimal implementation**

Move data and behavior as follows:
- `MobSceneRegistry.gd`: `GOBLIN_IDS`, `GOBLIN_SCENES`, `MOB_SCENES_BY_ID`
- `WaveStartFlow.gd`: extracted bookkeeping from `_on_wave_triggered`
- `MobContainerQuery.gd`: `clear_mobs`, `get_alive_mobs`, `set_wall_attack_stop_distance`
- `WaveSpawnService.gd`: absorb `_spawn_enemy_id_count`, `_spawn_mob_scene`, prophecy spawn iteration
- `TraderWaveSpawner.gd`: absorb trader-wave specific spawn branch
- `WaveTimerController.gd`: absorb `get_wave_interval_for_number`

Keep `GameSceneWaves.gd` as lifecycle orchestrator.

**Step 4: Run tests to verify they pass**

Run the new tests and existing:
- `scripts/dev/tests/test_gamescenewaves_safe_singleton_lookup.gd`

Expected: PASS.

### Task 9: Cleanup batch for already-healthy watchlist facades

**Files:**
- Create: `scripts/game_scene/GameSceneProcessLoop.gd`
- Create: `scripts/map_slot/MapSlotRecoveryFlow.gd`
- Create: `core/hero/HeroCoreNotificationBridge.gd`
- Modify: `scripts/game/GameScene.gd`
- Modify: `scripts/game_scene/GameSceneBootstrap.gd`
- Modify: `scripts/map/MapSlot.gd`
- Modify: `scripts/mob/Mob.gd`
- Modify: `scripts/mob/modules/MobWallTargetingFlow.gd`
- Modify: `scripts/mob/modules/MobMovement.gd`
- Modify: `scripts/mob/modules/MobBootstrap.gd`
- Modify: `scripts/mob/modules/MobDeathFlow.gd`
- Modify: `core/hero_core.gd`
- Modify: `scripts/hero/HeroOnField.gd`
- Modify: `scripts/hero/modules/HeroOnFieldBootstrap.gd`
- Test: `scripts/dev/tests/test_gamescene_process_loop.gd`
- Test: `scripts/dev/tests/test_mapslot_recovery_flow.gd`
- Test: `scripts/dev/tests/test_hero_core_notification_bridge.gd`

**Step 1: Write the failing tests**

Cover:
- `GameScene._process()` still routes spell targeting, pause tick, drag update, and slot hover exactly once,
- encounter-pause production recovery still touches the same slots/buildings,
- hero update notification bridge still emits and requests save,
- Mob wall range / corpse spawn behavior remains unchanged,
- HeroOnField watchdog/bootstrap behavior is preserved.

**Step 2: Run tests to verify they fail**

Run the three new tests headless.
Expected: FAIL because helpers do not exist yet.

**Step 3: Write minimal implementation**

Apply only narrow cleanup:
- `GameSceneProcessLoop.gd`: centralize `_process()` routing
- `GameSceneBootstrap.gd`: absorb `_setup_wave_timer_bar`
- `MapSlotRecoveryFlow.gd`: absorb `recover_after_encounter_pause`
- `HeroCoreNotificationBridge.gd`: absorb repeated emit-and-save boilerplate
- move remaining wall-rule helpers from `Mob.gd` into existing mob modules
- move HeroOnField watchdog creation into bootstrap

Do not introduce new broad modules here.

**Step 4: Run tests to verify they pass**

Run the new tests plus nearby existing watchlist regressions.

### Task 10: Create shared spell-effect helpers instead of growing more 300-line effect scripts

**Files:**
- Create: `scripts/effects/shared/SpellEnemyTracker.gd`
- Create: `scripts/effects/shared/SpellDamageApplicator.gd`
- Create: `scripts/effects/shared/SpellBoundsEnforcer.gd`
- Create: `scripts/effects/shared/SpellVisualLifecycle.gd`
- Modify: `scripts/effects/TornadoEffect.gd`
- Modify: `scripts/effects/BlindingLightEffect.gd`
- Modify: `scripts/effects/GroundfireEffect.gd`
- Modify: `scripts/effects/InfernalUnit.gd`
- Test: `scripts/dev/tests/test_spell_enemy_tracker.gd`
- Test: `scripts/dev/tests/test_spell_damage_applicator.gd`

**Step 1: Write the failing tests**

Cover:
- enemy tracking and dead-target filtering stay identical,
- damage application still respects current effect-side multipliers,
- bounds enforcement keeps current map-clamp behavior,
- visual lifetime helpers do not change expiry timing.

**Step 2: Run tests to verify they fail**

Run the two new shared-helper tests headless.
Expected: FAIL because shared helpers do not exist yet.

**Step 3: Write minimal implementation**

Extract repeated composition helpers rather than adding a deep inheritance tree.

Refactor the first four high-value effect scripts to use them.
If the pattern proves stable, apply the same helpers later to:
- `scripts/effects/TurnToSheepEffect.gd`
- `scripts/effects/MoonshineBarrelEffect.gd`
- `scripts/effects/ThunderstormEffect.gd`
- `scripts/effects/BanishEffect.gd`
- `scripts/effects/BladecasterEffect.gd`
- `scripts/effects/TNTBarrelEffect.gd`
- `scripts/effects/FrailtyEffect.gd`

**Step 4: Run tests to verify they pass**

Run the two new shared-helper tests and a focused smoke pass of the touched effects.

### Task 11: Lower-priority UI cleanup batch

**Files:**
- Create: `scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd`
- Create: `scripts/ui/rewards/modules/TraderOfferRoller.gd`
- Modify: `scripts/ui/prophecy/ProphecyMenu.gd`
- Modify: `scripts/ui/rewards/RewardMenuTrader.gd`
- Test: `scripts/dev/tests/test_prophecy_info_popup_controller.gd`
- Test: `scripts/dev/tests/test_trader_offer_roller.gd`

**Step 1: Write the failing tests**

Cover:
- prophecy hover popup delay/show/hide semantics remain unchanged,
- trader offer rolling still respects current rarity/type rules,
- UI scripts stay scene-owned and only delegate narrow logic.

**Step 2: Run tests to verify they fail**

Run the two new tests headless.
Expected: FAIL because helpers do not exist yet.

**Step 3: Write minimal implementation**

Extract:
- hover/info popup flow from `ProphecyMenu.gd`
- offer roll generation from `RewardMenuTrader.gd`

Keep card rendering and scene ownership in the scene-root scripts.

**Step 4: Run tests to verify they pass**

Run both new tests again.
Expected: PASS.

### Task 12: Documentation update and full regression sweep

**Files:**
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`
- Modify: relevant focused docs for touched subsystems
- Modify: only files touched in Tasks 1-11

**Step 1: Update canonical docs**

Document new module ownership for:
- buildings registry helpers,
- wave reward menu helpers,
- king spell state helpers,
- morale helpers,
- new shared hero helpers,
- GameSceneWaves second extraction batch,
- any new spell-effect shared helper layer actually adopted.

**Step 2: Run focused regression suite**

Run all new tests from Tasks 1-11 plus nearby existing regressions for buildings, rewards, hero field runtime, morale, king abilities, waves, and touched spell effects.

Recommended command batches:
- individual headless test scripts while modules are landing,
- then `C:\Godot\clickcer\run_9_tests.bat` if the touched subset overlaps the existing curated suite,
- then any additional targeted `scripts/dev/tests/*.gd` scripts created in this plan.

**Step 3: Inspect facades after extraction**

Confirm these files read primarily as orchestrators:
- `core/buildings/BuildingRegistry.gd`
- `scripts/ui/rewards/WaveRewardMenu.gd`
- `core/king_spell_state.gd`
- `scripts/systems/MoraleSystem.gd`
- `scripts/game_scene/GameSceneWaves.gd`
- `scripts/hero/types/SmallBones.gd`

**Step 4: Commit in small slices**

Suggested commit sequence:
- `refactor: split building registry editor and cost helpers`
- `refactor: extract wave reward routing and execution helpers`
- `refactor: share hero selection and hurtbox ui helpers`
- `refactor: split king spell availability and upgrade services`
- `refactor: extract morale calculation and building slot queries`
- `refactor: finish game scene waves extraction batch`
- `refactor: clean up remaining facade boilerplate`
- `refactor: add shared spell effect helpers`

---

## Scope Notes

- `core/mine/MineCore.gd` is not a priority extraction target; current structure is small and coherent.
- `core/skill_core.gd` is not a priority extraction target; it already delegates to `SkillEffects` and `SkillInstance`.
- For every watchlist file, preserve public wrappers and scene contracts.
- For every extraction from a known monolith, do not add new feature logic to the root file in the same task.

## Target Outcome

When this plan is complete:
- all high-risk 500+ line monoliths have extracted focused helpers,
- remaining watchlist files read as coordinators rather than mixed-logic controllers,
- repeated hero UI logic and repeated spell-effect logic are shared instead of copied,
- canonical architecture docs describe the new module ownership,
- future feature work has clear insertion points and no longer defaults back to root-script growth.
