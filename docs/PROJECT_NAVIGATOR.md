# Project Navigator

Last updated: 23.04.2026

Purpose: search-first file lookup for implementation work.

## What this document is

1. A practical "where do I go first?" map for the codebase.
2. A compact index of high-value runtime owners, orchestrators, registries, and UI entrypoints.
3. A fast lookup layer that should reduce unnecessary code reads before implementation.

## What this document is not

1. `docs/README.md` is the docs index.
2. `docs/WIKI_HOME.md` is the documentation entrypoint.
3. `docs/ARCHITECTURE.md` is the runtime ownership and boundaries document.
4. `docs/wiki_buildings/` is the current curated building lookup layer.

## Fast start

1. For any unfamiliar task, start at `res://scripts/game/GameScene.gd` if the behavior happens during a run.
2. If the task is about a gameplay system rather than a concrete file, cross-check `docs/ARCHITECTURE.md` and the closest focused reference that actually exists.
3. If the task is about buildings/catalog content, use `docs/wiki_buildings/` for practical building lookup and `docs/ARCHITECTURE.md` for runtime rules.
4. Use `docs/PROJECT_MERMAID_BIG_GRAPH.md` only for visual orientation, not as a behavior spec.

## Runtime entrypoints

1. Boot scene: `res://scenes/ui/MainMenu.tscn`.
2. Main gameplay scene: `res://scenes/game/GameScene.tscn`.
3. Main runtime orchestrator: `res://scripts/game/GameScene.gd`.
4. Main HUD/UI root: `res://scenes/ui/hud/MainUI.tscn` -> `res://scripts/ui/hud/MainUI.gd`.
5. MainMenu entry controller: `res://scripts/ui/MainMenu.gd`.

## GameScene module owners

1. `res://scripts/game/GameScene.gd` - top-level runtime orchestrator that wires scene references, module initialization, reward menus, encounters, pause state, and startup flow.
2. `res://scripts/game_scene/GameSceneBootstrap.gd` - startup helper that validates and binds core scene/runtime dependencies such as map layout, `WaveTimerBar` setup/hookup, and module bootstrapping.
3. `res://scripts/game_scene/GameSceneProcessLoop.gd` - owns per-frame `_process()` routing for spell targeting, pause-sensitive drag/hover updates, and hero cleanup.
4. `res://scripts/game_scene/GameSceneWaves.gd` - wave facade/orchestrator that wires helpers, wave state, prophecy/trader integration, and runtime progression.
5. `res://scripts/game_scene/modules/WaveStateFlow.gd` - wave-active bookkeeping and alive-mob tracking helper for `GameSceneWaves`.
6. `res://scripts/game_scene/modules/WaveStartFlow.gd` - wave-start reset and start-notification ordering helper.
7. `res://scripts/game_scene/modules/MobSceneRegistry.gd` - authoritative mob id -> scene registry plus goblin fallback ownership for wave spawning.
8. `res://scripts/game_scene/modules/MobContainerQuery.gd` - mob-container query/cleanup helper for `GameSceneWaves` wrappers.
9. `res://scripts/game_scene/modules/WaveSpawnService.gd` - mob instantiation, tracked-spawn registration, and prophecy pattern spawn helper.
10. `res://scripts/game_scene/modules/TraderWaveSpawner.gd` - trader cycle scheduling, trader preview payloads, and trader-wave spawn branch helper.
11. `res://scripts/game_scene/modules/WaveTimerController.gd` - timer preview payloads and canonical wave interval lookup.
12. `res://scripts/game_scene/modules/WavePreviewFlow.gd` - timer preview routing helper for prophecy/trader wave previews.
13. `res://scripts/game_scene/modules/SpecialWaveFlow.gd` - trader/prophecy completion branch helper for `GameSceneWaves`.
14. `res://scripts/game_scene/modules/WaveSpawnBranchFlow.gd` - branch selector for regular/trader/prophecy/placeholder spawning.
15. `res://scripts/game_scene/modules/WavePlaceholderFlow.gd` - placeholder prophecy-wave generation helper.
16. `res://scripts/game_scene/GameSceneWaveFlow.gd` - owns the post-wave flow that opens prophecy/reward UX at the right time.
17. `res://scripts/game_scene/GameSceneStages.gd` - owns biome/background loading and stage-to-biome scene switching through `StageCore`.
18. `res://scripts/game_scene/GameSceneHeroes.gd` - owns battlefield hero spawn/despawn and active-field syncing from `HeroCore` via `HeroSceneRegistry`.
19. `res://scripts/game_scene/GameSceneSpells.gd` - owns the runtime bridge between spell UI events, targeting state, and cast execution helpers.
20. `res://scripts/game_scene/GameSceneSignals.gd` - centralizes `EventBus` and `HeroCore` signal wiring into `GameScene` callbacks.
21. `res://scripts/game_scene/GameScenePendingRewards.gd` - owns the HUD reward-box queue and delayed reward claim flow.
22. `res://scripts/game_scene/GameSceneEncounterFlow.gd` - owns prophecy-to-encounter transition, encounter pause handoff, queued encounter UI actions, and uses safe runtime `TickManager` lookup so isolated/headless tests do not require a compile-time autoload identifier.
23. `res://scripts/game_scene/GameSceneRewardMenus.gd` - owns opening/closing orchestration for prophecy, trader, and reward menu surfaces.
24. `res://scripts/game_scene/GameScenePauseState.gd` - owns gameplay pause semantics around reward/prophecy/encounter flows.
25. `res://scripts/game_scene/GameSceneBuildingDrag.gd` - owns drag-and-drop placement state and ghost-building behavior.
26. `res://scripts/game_scene/GameSceneSlotHover.gd` - owns delayed slot-hover tooltip opening from runtime map interaction.
27. `res://scripts/game_scene/GameSceneBossSpawn.gd` - owns boss spawn presentation, boss containers, and arrival/HUD wiring.

## HUD and UI entrypoints

1. `res://scenes/ui/hud/MainUI.tscn` -> `res://scripts/ui/hud/MainUI.gd` - main HUD composition root.
2. `res://scripts/ui/hud/GameSpeedUI.gd` - runtime speed controls, settings entrypoint, and some pause/reward gating behavior.
3. `res://scenes/ui/hud/WaveTimerBar.tscn` -> `res://scripts/ui/hud/WaveTimerBar.gd` - countdown/timer UI that triggers wave flow.
4. `res://scenes/ui/hud/KingSpellHud.tscn` -> `res://scripts/ui/hud/KingSpellHud.gd` - king ability HUD owner.
5. `res://scenes/ui/hud/KingSpellSlot.tscn` -> `res://scripts/ui/hud/KingSpellSlot.gd` - individual king ability slot UI.
6. `res://scenes/ui/settings/OptionsMenu.tscn` -> `res://scripts/ui/settings/OptionsMenu.gd` - runtime settings UI owner.
7. `res://core/game_settings.gd` - persisted settings source of truth, including the default-disabled damage-number toggle.
8. `res://scripts/systems/DamagePopupPool.gd` - runtime damage-number gate; must respect `GameSettings` and default to disabled when settings are unavailable.
9. `res://scripts/ui/hud/MainUISignalFlow.gd` - `MainUI` signal wiring helper for `EventBus`, `ResourceCore`, `CastleCore`, and reset dialog.
10. `res://scripts/ui/hud/MainUIButtonFlow.gd` - `MainUI` button wiring, hidden debug-button gating, and debug/perks button pressed routing helper.
11. `res://scripts/ui/hud/MainUIResourceBarResolver.gd` - `MainUI` direct/fallback resource bar lookup helper.
12. `res://scripts/ui/hud/MainUIResourceBindingFlow.gd` - `MainUI` resource label lookup/binding helper.
13. `res://scripts/ui/hud/MainUIResourceDisplayFlow.gd` - resource label refresh/presentation helper for `MainUI`.
14. `res://scripts/ui/hud/MainUIPopupLayerBridge.gd` - popup host resolve/add bridge for `MainUI`.
15. `res://scripts/ui/hud/MainUIOverlayFlow.gd` - overlay-to-HUD visibility routing helper for `MainUI`.
16. `res://scripts/ui/hud/MainUIOverlayTargetBridge.gd` - scene target lookup bridge for `MainUI` overlay visibility updates.
17. `res://scripts/ui/hud/MainUIGameOverFlow.gd` - game-over popup creation/reuse/show helper for `MainUI`.
18. `res://scripts/ui/hud/MainUIHirePanelBootstrapFlow.gd` - initial hire-panel hidden-state bootstrap helper for `MainUI`.
19. `res://scripts/ui/hud/MainUIStartupDisplayFlow.gd` - startup HUD refresh/update orchestration helper for `MainUI`.
20. `res://scripts/ui/hud/MainUITooltipProcessFlow.gd` - per-frame tooltip tick forwarding helper for `MainUI`.
21. `res://scripts/ui/hud/MainUIDisplayEventFlow.gd` - gold/stage/resource display event routing helper for `MainUI`.
22. `res://scripts/ui/hud/MainUITooltipFacadeBridge.gd` - public tooltip facade routing helper for `MainUI`.
23. `res://scripts/ui/hud/MainUIPerksPanelFlow.gd` - perks test panel open-routing helper for `MainUI`.
24. `res://scripts/ui/hud/MainUIActionFlow.gd` - city-overlay/restart/debug action routing helper for `MainUI`.
25. `res://scripts/ui/town/BarracksTroopMenu.gd` - barracks troop panel and expand-up behavior.

## Character creation and start flow

1. `res://scenes/dev/CharacterCreationScratchEditable.tscn` -> `res://scripts/dev/CharacterCreationScratchEditable.gd` - editable scratch/runtime-aligned character creation controller.
2. `res://scenes/dev/CharacterCreationScratch.tscn` -> `res://scripts/dev/CharacterCreationScratchEditable.gd` - alternate scene wrapper using the same controller.
3. `res://core/game_start_settings.gd` - autoload for start-path selection/runtime start mode.
4. `res://core/king_spell_state.gd` - runtime state owner for king abilities chosen before the run.
5. `res://scripts/ui/spells/CharacterCreationSpellCatalog.gd` - shared spell metadata used by character creation and runtime spell UI.

## Inventory and item visuals

1. `res://modules/inventory/item_catalog.gd` - equipment template catalog and canonical `icon_path` source for generated helmet/armor/weapon/ring items.
2. `res://modules/inventory/item_system.gd` - item dictionary schema including stored `icon_path`.
3. `res://core/forge_item_generator.gd` - forge-crafted item generator that copies icon paths from `ItemCatalog` templates.
4. `res://assets/items/equipment/` - canonical runtime folder for the four shared equipment visuals: `helmet.png`, `armor.png`, `sword.png`, `ring.png`.
5. `res://scripts/ui/town/smith/SmithCraftRecipes.gd` - smith/forge recipe catalog and canonical source for recipe/crafting preview icons used by the craft menu.

## Dev prototypes and isolated tests

1. `res://scenes/dev/CombatTest.tscn` -> `res://scripts/dev/CombatTest.gd` - standalone combat/dev harness template that remains isolated from the main run.
2. `res://scenes/dev/TenKingsPrototype.tscn` -> `res://scripts/dev/ten_kings/TenKingsPrototype.gd` - standalone 10 Kings Player vs AI prototype scene with its own board, offer, and battle loop.
3. `res://scripts/dev/ten_kings/TenKingsTurnFlow.gd` - prototype phase-flow owner for castle placement, prep, yearly effects, battle, offer, and slot unlocking; also owns `can_end_turn()` validation for troop-on-board requirement.
4. `res://scripts/dev/ten_kings/TenKingsBattleManager.gd` - prototype battle orchestrator for troops-only arena spawning, fixed structure fire support, targeting, winner detection, and anchor-based formation positioning.
5. `res://scripts/dev/ten_kings/TenKingsCardLibrary.gd` - card catalog with classification helpers: `spawns_in_arena()`, `is_stationary_combat()`, `is_support_only()`.
6. `res://scripts/dev/ten_kings/TenKingsPlayerState.gd` - per-player state with `has_troop_in_hand()`, `ensure_any_troop_in_hand()` helpers for troop guarantee.
7. `res://scripts/dev/ten_kings/TenKingsBoardState.gd` - 5x5 board state with `has_troop_on_board()` helper for End Turn validation.
8. `res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn` -> `res://scripts/dev/ten_kings/TenKingsBoardTooltip.gd` - dedicated hover tooltip for board slot details (card name, stats, cost, description).
9. `res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd` - 80x80px visual-only board slot with hover signals for tooltip integration.
10. `docs/dev/TEN_KINGS_PROTOTYPE.md` - focused reference for the Ten Kings prototype module split, layout, tooltip, battle model, and isolation rules.

## Buildings and map-slot runtime

1. `res://scripts/map/MapSlot.gd` - start here for slot click behavior, placed-building state, production display, and special-building popup entrypoints.
2. `res://scripts/map_slot/` - split flow modules used by `MapSlot.gd` for production, lifecycle, interaction, popup, status, recovery-after-encounter-pause, and special-building behavior. Selector popup placement for Market/Research/Basic Construction is owned by `MapSlotPopupController.gd`, uses slot-global overlay positioning, and enforces one-open-popup-at-a-time across slots. Slot-local unit/durability overlays are authored from `MapSlotBootstrap.gd` and are centered over the building cell with white text.
3. `res://core/buildings/BuildingRegistry.tscn` -> `res://core/buildings/BuildingRegistry.gd` - central building config registry, recipe counts, rollout filtering, and placed-scale overrides.
4. `res://core/buildings/BuildingConfig.gd` - building data contract used by build menus, slot runtime, and production/special handlers.
5. `res://scenes/ui/building/BuildingMenu.tscn` -> `res://scripts/ui/building/BuildingMenu.gd` - building selection/build menu entry UI.
6. `res://core/buildings/special/` - authoritative runtime logic for special buildings; start here when a building does more than normal production.
7. `res://core/buildings/special/BasicConstruction.gd` - runtime owner for Basic Construction upgrade/build cycle logic.
8. `res://core/buildings/special/ResearchTable.gd` - runtime owner for Research Table modes, shared progress, and pending reward completion.
9. `res://core/buildings/special/Arena.gd` - runtime owner for gaze-gated arena morale/fight-betting behavior.
10. `res://core/buildings/special/ExecutionGround.gd` - runtime owner for reserve-unit execution and gold reward flow.
11. `res://scenes/ui/town/BasicConstructionUI.tscn` -> `res://scripts/ui/town/BasicConstructionUI.gd` - Basic Construction slot popup UI.
12. `res://scenes/ui/town/ResearchTableUI.tscn` -> `res://scripts/ui/town/ResearchTableUI.gd` - Research Table mode selector UI. The slot entrypoint is the clickable `ResearchModeBadge` button built by `res://scripts/map_slot/MapSlotBootstrap.gd`.
13. `res://scenes/ui/town/MarketUI.tscn` -> `res://scripts/ui/town/MarketUI.gd` - market trade selector UI. Its opener button hides while the selector is visible, and the trade list expands dynamically when artifact-based extended market trades are unlocked.
14. `res://scripts/ui/town/BuildingsTooltip.gd` and `res://scripts/ui/town/buildings/BuildingsTooltipContent.gd` - building hover tooltip composition and content rendering.
15. `res://scripts/ui/town/BuildingDetailsPanel.gd` - expanded building details panel.
16. `res://scripts/ui/rewards/RewardBuildingCard.gd` - building reward/building card presentation inside reward menus.
17. `res://scripts/ui/town/buildings/BuildingPresentationData.gd` - canonical building upgrade name/description data source.
18. `res://scripts/ui/town/buildings/BuildingUpgradeData.gd` - thin facade over presentation data with icon accessor delegating to `BuildingUpgradeIconResolver`.
19. `res://scripts/ui/town/buildings/BuildingUpgradeVisuals.gd` - status colors, stripe textures, and `EXPLICIT_WORKING_UPGRADES` dict for upgrade visual state.
20. `res://scripts/ui/town/buildings/BuildingUpgradeIconResolver.gd` - static upgrade icon mapping and resolution module; maps `building_id:index` to PNG paths with lazy texture caching.
21. `res://scenes/ui/town/UpgradeItemPanel.tscn` -> `res://scripts/ui/town/UpgradeItemPanel.gd` - individual upgrade row panel used in tooltips and details panels.
22. `res://assets/ui/buildings/upgrade_icons/` - upgrade icon assets organized by `<building_id>/<index>_<slug>.png` (33 PNGs across 16 buildings).

## Rewards, prophecy, and encounters

1. `res://scenes/ui/rewards/WaveRewardMenu.tscn` -> `res://scripts/ui/rewards/WaveRewardMenu.gd` - main wave reward selector UI.
2. `res://scenes/ui/prophecy/ProphecyMenu.tscn` -> `res://scripts/ui/prophecy/ProphecyMenu.gd` - prophecy selection UI owner; renders rows in `Easy -> Mid -> Hard` order with 6 options per row, requires one Easy pick to continue, and allows at most one pick per tier row.
3. `res://scripts/prophecy/ProphecyWaveGenerator.gd` - prophecy wave generation logic and canonical per-level power bands.
4. `res://scripts/resources/ProphecyPattern.gd` and `res://scripts/resources/ProphecyPatternPool.gd` - prophecy data definitions, level-aware metadata (`family`, `reward_bias`, `is_rare_strong`), and JSON pool building.
5. `res://scripts/encounters/EncounterService.gd` - authoritative builder/applicator for encounter data, requirements, rewards, and pending UI actions.
6. `res://scripts/encounters/EncounterDefs.gd` - encounter definition source used by `EncounterService`.
7. `res://scenes/ui/encounters/EncounterMenu.tscn` -> `res://scripts/ui/encounters/EncounterMenu.gd` - encounter choice UI owner.
8. `res://scripts/ui/rewards/RewardPresentationRegistry.gd` - canonical reward type to icon/name presentation mapping shared across reward UIs.
9. `res://scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd` - prophecy rewards-info popup hover/show/hide/drag helper.
10. `res://scripts/ui/rewards/modules/TraderOfferRoller.gd` - trader offer section rolling helper used by `RewardMenuTrader.gd`.
11. `res://scenes/ui/rewards/RewardBuildingUpgradeCard.tscn` -> `res://scripts/ui/rewards/RewardBuildingUpgradeCard.gd` - building upgrade reward card with 72x72 icon-bearing upgrade status slots, dim overlay for locked upgrades, spell-style hover tooltip (PanelContainer centered above slot), and ThaleahFat font throughout.

## Spells and spell UI

Terminology:
- `spells` = normal battlefield spells from `SpellPanel` that deal damage or apply effects.
- `king spells` / `king abilities` = separate king-ability system shown in `KingSpellHud`.
- Do not mix these two terms in project discussions or specs.

1. `res://resources/spells/SpellConfig.gd` - spell resource contract and tooltip-facing metadata source.
2. `res://scripts/systems/PathRegistry.gd` - compatibility resolver for spell configs, unit configs, and resource icons across canonical and legacy paths.
3. `res://scenes/ui/spells/SpellPanel.tscn` -> `res://scripts/ui/spells/SpellPanel.gd` - runtime spell inventory UI, slot interaction, and targeting-start owner.
4. `res://scripts/ui/spells/SpellSlot.gd` - individual spell slot behavior, stacking, and click/hover events.
5. `res://scripts/ui/debug/DebugSpawnMenu.gd` - debug spell injection/spawn utilities.
6. `res://scripts/effects/` - start here for concrete runtime spell effect implementations.
7. `res://scripts/effects/shared/SpellEnemyTracker.gd` - shared enemy resolution / dead-filter / nearest-target helper for spell effects and summons.
8. `res://scripts/effects/shared/SpellDamageApplicator.gd` - shared damage routing helper for spell effects.
9. `res://scripts/effects/shared/SpellBoundsEnforcer.gd` - shared bounds clamp/bounce helper for roaming spell effects.
10. `res://scripts/effects/shared/SpellVisualLifecycle.gd` - shared fade/lifetime tween helper for extracted effect expiry.
11. `res://scripts/effects/shared/SpellCaptureOrbitController.gd` - shared captured-target orbit helper for tornado-style effects.
12. `res://scripts/effects/shared/StatusIconService.gd` - shared static service for buff/debuff status icons above units (add, remove, reflow in horizontal row).
13. `res://scripts/effects/QuicksandEffect.gd` - persistent area slow debuff (replaces old SlowZoneEffect); uses StatusIconService for visual icons.
14. `res://scripts/effects/ImmortalityEffect.gd` - persistent allied area that grants invincibility while heroes stay inside; applies both overhead status icon and per-hero floor VFX.
15. `res://scripts/effects/FreezeEffect.gd` - area control spell that fully freezes enemies for 1 second, then keeps a timed 25% slow with blue visual state and status icon.
16. `res://scripts/effects/IncinerationEffect.gd` - instant area burst spell that applies direct AoE damage with authored fire visuals.
17. `res://scripts/effects/LastStandEffect.gd` - persistent allied area spell that grants invincibility and 110 HP/s heal-over-time to heroes inside; uses separate stack meta keys from ImmortalityEffect, authored 16-frame SpriteFrames at 12 FPS scaled 2x.
18. `res://scripts/dev/verify/verify_scenes.gd` and `res://scripts/dev/tests/test_spell_scene_smoke_roster.gd` - spell smoke/roster verification entrypoints for config/catalog/scene coverage.
18. `res://scripts/ui/spells/SpellPanel.gd` - also owns the enlarged runtime hover tooltip for spell descriptions; start here for battlefield spell popup readability changes.

## Heroes, mobs, and combat runtime

1. `res://core/hero_core.gd` - central hero autoload facade for hero data, recruitment, squad state, battle flow, and persistence hooks.
2. `res://core/hero/HeroCoreNotificationBridge.gd` - helper for `HeroCore` hero-updated emission and optional save-request side effects.
3. `res://scripts/hero/HeroSceneRegistry.gd` - authoritative resolver from hero/unit ids to dedicated hero scene files.
4. `res://scripts/hero/HeroOnField.gd` - base on-field hero runtime facade/orchestrator.
5. `res://scripts/hero/modules/HeroOnFieldBootstrap.gd` - bootstrap helper for HeroOnField node wiring, watchdog timer setup, and initial runtime boot tasks.
6. `res://scenes/heroes/*.tscn` - dedicated hero entry scenes resolved through `HeroSceneRegistry`.
7. `res://scripts/utils/HeroAssetLoader.gd` - runtime hero animation/icon loader; direct animation folders must win over placeholder fallbacks, and placeholders must be used only when no authored scene frames or real animation folders exist.
8. `res://scripts/hero/states/*.gd` - hero state-machine runtime logic.
9. `res://scripts/hero/HeroCombatTypeResolver.gd` - shared combat-role/type resolution for heroes.
10. `res://scripts/hero/card/HeroCardBattle.gd` - fight/auto-battle entry helper; when the field is already full because of summon overflow, it must not pull extra reserve heroes into battle-start selection.
11. `res://scripts/mob/Mob.gd` - base runtime mob facade/orchestrator; keep public wrappers here, not wall/death implementation details.
12. `res://scripts/mob/modules/MobWallTargetingFlow.gd`, `res://scripts/mob/modules/MobMovement.gd`, and `res://scripts/mob/modules/MobDeathFlow.gd` - own wall-rule math, wall stop-distance state, and corpse-spawn/death flow details for `Mob.gd`.
13. `res://scripts/mob/modules/MobProjectileFlow.gd` - projectile spawn helper for ranged/heal mobs; projectile speed/spin overrides are optional mob fields and must fall back to projectile-scene defaults when absent.
14. `res://scripts/mob/modules/MobBootstrap.gd` - mob bootstrap wiring helper that initializes runtime modules before state logic runs.
15. `res://scripts/mob/states/*.gd` - mob state-machine runtime logic.
16. `res://scripts/map/Wall.gd` - wall runtime and combat target.

## Economy, town, and artifacts

1. `res://core/economy_core.gd` - gold/Denarii runtime owner.
2. `res://core/town_core.gd` - town-facing facade for building/town progression APIs.
3. `res://core/buildings/BuildingCostService.gd` - canonical building affordability/payment helper; `gold` cost entries resolve against `EconomyCore`, while non-gold entries still resolve against `ResourceCore`.
4. `res://core/gaze_core.gd` - gaze upgrade owner; `gold` upgrade cost resolves against `EconomyCore`, while the remaining materials still resolve against `ResourceCore`.
5. `res://core/save_core.gd` - save facade/autosave orchestrator over save registry, autosave debounce, IO, and reset helpers.
6. `res://core/save/SaveRegistryFlow.gd` - autoload save-target registration and save-key derivation helper.
7. `res://core/save/SaveAutosaveFlow.gd` - autosave debounce helper.
8. `res://core/save/SaveIOFlow.gd` - save/load IO helper for `SaveCore`.
9. `res://core/save/SaveResetFlow.gd` - reset-progress orchestration helper.
10. `res://core/resource_core.gd` - resource inventory owner.
11. `res://core/population_core.gd` - population runtime owner.
12. `res://core/population/PopulationBattlefieldQuery.gd` - shared occupied-field query helper used by normal deploy guards so summons still consume visible field capacity after they appear.
13. `res://core/building_upgrade_core.gd` - building-upgrade facade over slot queries, registry/save helpers, and bonus queries.
14. `res://core/building_upgrade/BuildingUpgradeSlotQuery.gd` - slot/runtime query helper for building-upgrade calculations.
15. `res://core/building_upgrade/BuildingUpgradeRegistryFlow.gd` - upgrade unlock/save/load helper.
16. `res://core/building_upgrade/BuildingUpgradeBonusFlow.gd` - bonus/multiplier query helper for upgrade effects.
17. `res://core/building_upgrade/BuildingUpgradeProductionBoost.gd` - production speed multiplier lookup by building_id.
18. `res://core/building_upgrade/BuildingUpgradeProductionBonus.gd` - bonus resource/repair hooks per production cycle.
19. `res://core/building_upgrade/BuildingUpgradeNeighbourBoost.gd` - sawmill 20% neighbour boost (4 orthogonal), consumed by `MapSlotProduction.gd` when building cycle time is calculated.
20. `res://core/building_upgrade/BuildingUpgradeTroopInspiration.gd` - flat 10% class-wide HP/damage from mines/forge/mill.
21. `res://core/building_upgrade/BuildingUpgradeCapacityBonus.gd` - capacity bonus lookup by building_id.
22. `res://core/building_upgrade/BuildingUpgradeTroopStatModifier.gd` - per-unit HP/damage/evasion/attack-range modifiers.
23. `res://core/building_upgrade/BuildingUpgradeCombatHook.gd` - on-hit effects (DoT, stun, crit, lifesteal, slow, long shot, war of attrition, jumping lightning).
24. `res://core/building_upgrade/BuildingUpgradeDeathReward.gd` - on-death resource grants.
25. `res://core/building_upgrade/BuildingUpgradeCostModifier.gd` - production cost multipliers (discounts and increases).
26. `res://core/building_upgrade/BuildingUpgradeMegaMilitia.gd` - mega militia global counter logic.
27. `res://core/building_upgrade/BuildingUpgradeUnitCounter.gd` - shared utility counting active heroes by unit_id.
28. `res://core/building_upgrade/BuildingUpgradeSpellDamageBoost.gd` - spell damage multipliers from paladins/ram/unicorn.
29. `res://core/building_upgrade/BuildingUpgradeUnitAura.gd` - unit-count-dependent auras (morale, damage, HP buffs).
30. `res://core/building_upgrade/BuildingUpgradeProductionEvent.gd` - post-production hooks (giants bedding, ram twins).
31. `res://core/building_upgrade/BuildingUpgradeLionCircus.gd` - griffin versatility and cost doubling.
32. `res://scripts/systems/MoraleSystem.gd` - morale calculation/runtime helpers.
33. `res://core/artifacts/artifact_core.gd` - artifact facade for owned/active state, signals, trader/progression/production/combat wrappers, stat queries, and high-level coordination.
34. `res://core/artifacts/ArtifactExternalMultiplierBridge.gd` - applies external `BuildingUpgradeCore` multipliers to artifact query outputs.
35. `res://core/artifacts/ArtifactOwnershipFlow.gd` - artifact add/remove/activate state mutation and pickup queue helper.
36. `res://core/artifacts/ArtifactRuntimeFlow.gd` - artifact periodic runtime loop, pending spell reward opening flow, and scene-driven periodic building-count effects such as `cupbearers_vessel`.
37. `res://core/artifacts/ArtifactRuntimeTargetBridge.gd` - scene target lookup and pending artifact reward enqueue bridge.
38. `res://core/artifacts/ArtifactPersistenceFlow.gd` - artifact save/load/reset payload normalization and reapply helper.
39. `res://core/artifacts/ArtifactTraderBenefits.gd` - trader-focused artifact helper for one-shot free coupon charges and extended market trade unlock queries.
40. `res://core/artifacts/ArtifactProgressionFlow.gd` - early runtime artifact helper for gaze-trigger rewards, king cooldown modifiers, troop-building capacity bonuses, and unit-created rewards.
41. `res://core/artifacts/ArtifactProductionHooks.gd` - resource-production artifact helper for output-aware hooks, production thresholds/rewards, and resource-tracking state (`filtered_fuel`, `clay_treasure`, `magic_acorn`, `royal_order`, `flour_deity`, `super_metal`).
42. `res://core/artifacts/ArtifactSummonFlow.gd` - temporary summon helper for wave-start summons, lifetime scaling, and `second_chance` resurrection tokens.
43. `res://core/artifacts/ArtifactEventHandlers.gd` - artifact event hook owner for kill/wave/death effects including temporary-wave summons, death-position healing pools, death-trigger effect spawning (`scarecrow_hat`), and recruit-on-death artifact routing.
44. `res://core/artifacts/ArtifactStatQueries.gd` - artifact stat query helper for dynamic unit HP/damage/move-speed/projectile-chance lookups including class-count-based combat artifacts (`poor_mans_relic`, `golden_wings`, `twin_projectiles`), persistent morale from `wine_cup`, attacking-building damage multipliers used by `frag_bomb`, `chi_fan` flat-HP spell stacks, and `indestructible_shield` full-damage-block chance.
45. `res://core/artifacts/ArtifactBuildingCombatHooks.gd` - shared building-damage bridge used by attacking buildings and working-building artifact flows.
46. `res://core/artifacts/ArtifactWorkingBuildingFlow.gd` - working-production artifact helper for `sweeping_blade` (`tree` + `sawmill` while actively producing).
47. `res://core/artifacts/artifact_catalog.gd` - artifact definition source and canonical player-available artifact filtering used by reward/trader pools.
48. `res://core/artifacts/ArtifactSpellRewards.gd` - shared helper for queued spell-choice artifact rewards.
49. `res://core/artifacts/ArtifactFriendlyDeathBuffDomain.gd` - death-reactive friendly buff owner for `hand_of_the_avenged` enrage application/removal.
50. `res://core/artifacts/ArtifactDeathSummonDomain.gd` - death-trigger cooldown/spec owner for `scarecrow_hat` and `indescribable_figurine`.
51. `res://core/artifacts/ArtifactBuildingLifecycleBonuses.gd` - starter-building lifecycle bonus owner for `iron_hoe` durability and unit-limit doubling.
52. `res://scripts/hero/shared/FriendlyDamageBlockHelper.gd` - shared frontline helper that applies `indestructible_shield` full-damage-block checks across hero/summon damage entrypoints.
53. `res://scripts/ui/rewards/RewardMenuArtifacts.gd` - artifact reward selection UI fed from the player-available artifact pool; also supports legendary-only artifact offers through open options.
54. `res://scripts/ui/rewards/modules/TraderOfferGenerator.gd` - trader artifact offer pool generator; uses the same player-available artifact filtering as reward menus.
55. `res://scripts/ui/rewards/modules/TraderTransactionLogic.gd` - trader purchase helper that consumes artifact coupon discounts when available.
39. `res://scripts/map_slot/MapSlotMarket.gd` - market runtime trade logic with artifact-aware extended resource trade resolution.
40. `res://scripts/map_slot/MapSlotProduction.gd` - production/runtime owner that now also forwards active working ticks to artifact combat flow for `sweeping_blade` and routes starter-building limits through artifact lifecycle wrappers.
41. `res://core/buildings/special/TeslaTower.gd` and `res://core/buildings/special/FairyFountain.gd` - current attacking-building runtime consumers for `frag_bomb`.
42. `res://scripts/ui/rewards/RewardArtifactCard.gd`, `res://scripts/ui/artifacts/ArtifactPanel.gd`, and `res://scripts/ui/artifacts/ArtifactDebugPanel.gd` - artifact presentation surfaces.

## Shared services and world positioning

1. `res://scripts/map/MapMarkerService.gd` - canonical spawn/bridge/marker position service.
2. `res://scripts/map/MapMarker.gd` - marker node contract used by layout/service logic.
3. `res://scripts/map/MapLayout.gd` - map layout owner and marker arrangement source.
4. `res://scenes/effects/SpawnDustEffect.tscn` and `res://scripts/mob/Mob.gd` - mob spawn effect visual hookup.

## Building and wiki reference layers

1. `docs/ARCHITECTURE.md` - current runtime rules for building lifecycle, sell/destroy semantics, and ownership boundaries.
2. `docs/wiki_buildings/` - current curated building reference for practical building lookup, upgrades, and content browsing.
3. `the_king_is_watching_gdd/04_buildings_catalog.md` - external design-side building reference.

## Go here if...

1. You need wave spawn/completion logic: start at `res://scripts/game_scene/GameSceneWaves.gd`.
2. You need prophecy/reward opening flow after a wave: start at `res://scripts/game_scene/GameSceneWaveFlow.gd`.
3. You need delayed reward-box behavior: start at `res://scripts/game_scene/GameScenePendingRewards.gd`.
4. You need building click/special popup behavior: start at `res://scripts/map/MapSlot.gd`.
5. You need building data, recipes, or rollout filtering: start at `res://core/buildings/BuildingRegistry.gd`.
6. You need special building runtime behavior: start at `res://core/buildings/special/`.
7. You need spell inventory/slot UI: start at `res://scripts/ui/spells/SpellPanel.gd`.
8. You need spell targeting/casting runtime flow: start at `res://scripts/game_scene/GameSceneSpells.gd`.
9. You need hero spawn path resolution: start at `res://scripts/hero/HeroSceneRegistry.gd` and `res://scripts/game_scene/GameSceneHeroes.gd`.
10. You need encounter logic or encounter effects: start at `res://scripts/encounters/EncounterService.gd`.
11. You need artifact ownership/reward side effects: start at `res://core/artifacts/artifact_core.gd`.

## Dev tools and audit runners

### Building upgrade audit runner

Headless audit that validates every building upgrade in the canonical matrix has a working runtime effect.

| File | Role |
|------|------|
| `scripts/dev/audit/BuildingUpgradeAuditMatrix.gd` | Canonical matrix of all 141 upgrade entries (building_id, index, effect family, expected key/value) |
| `scripts/dev/audit/BuildingUpgradeAuditHarness.gd` | Mock infrastructure — creates a minimal `BuildingUpgradeCore` with helpers, unlocks upgrades, queries results |
| `scripts/dev/audit/BuildingUpgradeFamilyRunner.gd` | Per-family verification logic — one method per effect family (production_boost, troop_stat, combat_hook, etc.) |
| `scripts/dev/tests/test_building_upgrade_audit_runner.gd` | Headless entrypoint — iterates the matrix, runs each entry through FamilyRunner, reports PASS / FAIL / INCONCLUSIVE |

Run command:

```
C:\Godot\Godot_v4.3-stable_win64.exe --headless --path C:\Godot\clickcer -s scripts/dev/tests/test_building_upgrade_audit_runner.gd
```

Result categories: **PASS** (effect verified), **FAIL** (logic or refresh error), **INCONCLUSIVE** (requires scene integration or runtime-only validation, e.g. special building handlers).

Current status (2026-03-29): 111 PASS, 0 FAIL, 30 INCONCLUSIVE.

### Building upgrade in-game QA workbench

Hidden runtime panel that runs the full 141-entry matrix inside a live game session and saves machine-readable reports to disk.

Toggle with **F11** (available whenever the debug menu is loaded, i.e. non-release builds).

| File | Role |
|------|------|
| `scripts/dev/qa/BuildingUpgradeQaRunner.gd` | Orchestrator — wraps `BuildingUpgradeFamilyRunner`, runs all/family/building/failed subsets, returns structured result dicts |
| `scripts/dev/qa/BuildingUpgradeQaReportStore.gd` | Report persistence — writes `latest.json`, `latest.md`, `latest_failed.json`, `history/<ts>.json` to `user://qa_reports/building_upgrade/` |
| `scripts/ui/debug/BuildingUpgradeQaPanel.gd` | CanvasLayer UI panel — button row (Run All, Run Failed, Clear), status line, color-coded result table |

Report output paths:
- `user://qa_reports/building_upgrade/latest.json` — full results array
- `user://qa_reports/building_upgrade/latest.md` — human-readable markdown summary
- `user://qa_reports/building_upgrade/latest_failed.json` — only FAIL_* entries
- `user://qa_reports/building_upgrade/history/<timestamp>.json` — per-run history

Result status codes: **PASS**, **FAIL_LOGIC**, **FAIL_REFRESH**, **INCONCLUSIVE** (same as headless audit runner).

## Documentation update reminder

If a mechanic, flow, economy rule, or architecture detail changes, also update:

1. `docs/ARCHITECTURE.md`
2. relevant focused doc(s) that actually exist for the touched subsystem
