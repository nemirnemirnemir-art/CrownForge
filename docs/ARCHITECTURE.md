# Architecture Overview

Last updated: 23.04.2026

## Runtime composition

1. `GameScene.gd` is the root orchestrator for battle runtime.
2. Module responsibilities are split across:
   - `GameSceneBootstrap`
   - `GameSceneWaves`
   - `GameSceneHeroes`
   - `GameSceneStages`
   - `GameSceneSignals`
   - `GameSceneSpells`
   - `GameSceneProcessLoop`
3. Global systems are accessed via autoloads (`EventBus`, `TickManager`, `BattleCore`, `TownCore`, `EconomyCore`, `ResourceCore`, `BuildingRegistry`, `MapMarkerService`, etc.).

## Character creation scratch UI architecture

1. `scenes/dev/CharacterCreationScratchEditable.tscn` is the canonical editable scratch layout for character creation prototyping.
2. `scenes/dev/CharacterCreationScratch.tscn` mirrors the same node contract so the shared scratch script can be run without missing-node failures.
3. `scripts/dev/CharacterCreationScratchEditable.gd` is a thin UI-state coordinator: it updates labels, textures, button states, and input validation, but it does not rebuild or reposition the UI tree.
4. Scratch stat rows, class selector, age input, and name input are authored directly as scene nodes so designers can move them in the editor and keep those transforms across reloads.
5. Class selection is index-based over three authored assets (`Сhivalry`, `Necromancy`, `Demonology`) and updates both icon and display text from one shared data table in the scratch script.
6. Age input is direct text entry in the scene-authored `LineEdit`; the script filters non-digit input live, clamps committed values to `16..60`, and drops focus when the player clicks outside the active input.
7. Name input is direct text entry in the scene-authored `LineEdit`; the script filters input to letters plus spaces and enforces the current 16-character limit.
8. The class token is no longer a static `TextureRect`; it is a scene-authored rig with editable rope anchor, spawn point, rest point, rope line, token root, and token attach point so the hanging composition stays designer-tunable.
9. Root inspector export `class_token_physics_mode` switches between two simulation variants: `Taut Rope` (hard rope-length constraint) and `Elastic Rope` (spring-like stretch with damping).
10. Dragging the token is handled in the scratch script via mouse sampling in UI space; on release the token keeps sampled velocity and settles back under the currently selected rope mode.
11. Class changes reset the token to the authored spawn point, swap texture, and replay the drop-to-hang motion without recreating the UI tree.
12. King ability selection is handled in the same scratch controller via a scene-authored `SpellPanel`; the dropdown is filtered from one shared data table by current class id (`class-specific + global abilities only`).
13. Spell choice uses split state: `confirmed_spell_id` is the committed class spell, `pending_spell_id` is the temporary dropdown pick until confirm/cancel.
14. Stat icons and spell buttons share a single focus source of truth (`focused_entry_type`, `focused_stat_id`, `focused_spell_id`) and a shared pulsing overlay node `SelectionFocus`.
15. The lower-right `DescriptionPanel` is a scene-authored information surface populated by the controller for either stat focus or spell focus, including cost/resource/cooldown metadata for spells.
16. Assets from `res://assets/takefromthis/` are not part of runtime architecture; adopted assets must be relocated into owning feature folders before use.

## Ten Kings prototype architecture

1. `scenes/dev/TenKingsPrototype.tscn` is a standalone development sandbox and is not part of the main start/run flow.
2. `scripts/dev/ten_kings/TenKingsPrototype.gd` is the root prototype orchestrator: it wires UI, player input, board refresh, offer handling, tooltip hover, arena anchor injection, and battle handoff, but keeps phase logic and combat logic delegated out.
3. `scripts/dev/ten_kings/TenKingsTurnFlow.gd` owns the high-level game phases, castle-damage progression, opening hand normalization (castle + troop guarantee), and `can_end_turn()` validation; it does not instantiate battle nodes directly.
4. `scripts/dev/ten_kings/TenKingsBattleManager.gd` owns arena spawning (troops-only), fixed structure tracking, formations, targeting, and winner reporting; it does not mutate deck/offer/year state. It receives arena anchors via `set_arena_anchors()` and uses them to compute formation X-coordinates and castle contact positions.
5. Player runtime state is split across `TenKingsPlayerState.gd`, `TenKingsBoardState.gd`, `TenKingsCardLibrary.gd`, and `TenKingsYearEffects.gd` instead of growing the scene root into a monolith.
6. Prototype UI surfaces are modularized into `TenKingsBoardSlotUI.gd` and `TenKingsHandCardUI.gd`; the root scene authors layout containers while the script populates them at runtime.
7. The prototype is intentionally isolated from `GameScene`, `HeroOnField`, `HeroCore`, and `GameSceneWaves`; any future integration must happen through a separate bridge layer rather than shared runtime ownership.
8. Runtime-adopted prototype assets live under `res://assets/dev/ten_kings/`; `res://assets/takefromthis/` remains a temporary intake folder and is not referenced directly at runtime.

### Guaranteed troop spawning

1. At game setup, `TenKingsTurnFlow.setup()` calls `_ensure_opening_castle()` and `_ensure_opening_troop()` for both players, guaranteeing castle + troop in each player's starting hand.
2. `TenKingsPlayerState.has_troop_in_hand()` returns true if hand contains soldier/archer/paladin.
3. `TenKingsPlayerState.ensure_any_troop_in_hand()` pulls a troop from deck to hand if none present.
4. `TenKingsBoardState.has_troop_on_board()` returns true if any occupied slot contains a troop card.
5. `TenKingsTurnFlow.can_end_turn()` returns true only during PREP phase with castle placed and at least one troop on board.
6. `TenKingsPrototype.gd` disables the End Turn button and shows status message "Place at least one troop before ending turn" when `can_end_turn()` returns false.

### Battle model (troops-only arena with fixed structure fire support)

1. Cards are classified into three categories via `TenKingsCardLibrary.gd` helpers:
   - **Troops** (`spawns_in_arena()`): Soldier, Archer, Paladin — deploy into arena, move, fight
   - **Stationary combat** (`is_stationary_combat()`): Castle, Scout Tower — stay at board positions, shoot into arena
   - **Support-only** (`is_support_only()`): Farm, Blacksmith, Wildcard, Steel Coat — never participate in combat runtime
2. Battle manager tracks units in separate collections:
   - `_player_units` / `_ai_units` — troop stacks that move and fight in arena
   - `_player_fixed_structures` / `_ai_fixed_structures` — Castle/Tower references that fire from board positions
3. `TenKingsBattleActor.gd` uses state-driven lifecycle with pending state support to handle `@onready` timing issues.
4. Siege resolution uses `CastleContactAnchor` positions, not castle unit positions.

### Board slot visual-only contract

1. Board slots (`TenKingsBoardSlotUI.gd`) are 80x80px visual-only cells.
2. Slots display card art/placeholder icons only — no inline text (name, stats, cost).
3. Slots emit `hovered(slot)` and `unhovered(slot)` signals for tooltip integration.
4. Card details are shown in a dedicated hover tooltip, not rendered inside the slot.

### Board tooltip architecture

1. `scenes/dev/ten_kings/TenKingsBoardTooltip.tscn` is the dedicated tooltip scene for board slot hover details.
2. `scripts/dev/ten_kings/TenKingsBoardTooltip.gd` owns tooltip show/hide, content population, and viewport clamping.
3. The tooltip displays card name, stats (ATK/HP), cost, and description when a slot is hovered.
4. `TenKingsPrototype.gd` wires slot hover signals to the tooltip controller.
5. Tooltip uses lazy node resolution (`get_node_or_null`) for headless test compatibility.

### Arena layout and anchors

1. The scene layout uses a 180px minimum central battle corridor between player board (x=12-430) and AI board (x=610-1010).
2. Arena anchors are scene-authored `Marker2D` nodes under `BattleLayer`: `PlayerFormationAnchor`, `AiFormationAnchor`, `PlayerCastleAnchor`, `AiCastleAnchor`.
3. `TenKingsPrototype.gd` exposes `get_arena_anchors()` returning a dictionary with `player_formation`, `ai_formation`, `player_castle`, `ai_castle` positions.
4. `TenKingsBattleManager.gd` receives anchors via `set_arena_anchors()` and uses them for:
   - `get_formation_x_for_unit_type(owner)` — returns formation anchor X for player/AI unit spawning
   - `get_castle_contact_position(owner)` — returns castle anchor position for siege targeting
   - `_build_formation_targets()` — computes formation positions using anchor X-coordinates
5. This anchor-driven layout ensures formation and siege positions stay aligned with the visual corridor regardless of scene resizing.

## Start flow architecture

1. Project boot now starts in `scenes/ui/MainMenu.tscn` instead of entering gameplay directly.
2. Scene-routing state for starting through character creation vs direct gameplay is centralized in autoload `core/game_start_settings.gd`.
3. `MainMenu` and runtime `MainUI` both mutate the same `GameStartSettings.start_via_character_creation` flag, so the next-run path stays consistent across screens.
4. Character creation remains the authoritative source for applying selected class, active king ability, passive king ability, age, and name into `CharacterCreationState`.
5. `CharacterCreationScratchEditable._on_next_pressed()` now also initializes per-run king ability runtime state through `KingSpellState` before loading `GameScene`.

## King ability runtime architecture

1. Runtime king ability state is isolated in autoload `core/king_spell_state.gd`.
2. `KingSpellState` owns per-run active cooldowns, passive one-shot consumption flags, active upgrade level, and temporary productivity bonus state.
3. `KingSpellHud` is the dedicated runtime controller/view for king abilities and is intentionally separate from gameplay `SpellPanel`.
4. `KingSpellSlot` is a dedicated visual/runtime slot implementation for king abilities, with disabled/cooldown overlay support and rectangular passive slot sizing.
5. Shared king ability metadata remains in `scripts/ui/spells/CharacterCreationSpellCatalog.gd`; runtime HUD/controller code reads the same catalog instead of duplicating ability definitions in multiple places.
6. Active king ability upgrades are implemented as HUD-driven per-run purchases that consume `EconomyCore` gold and `ResourceCore` materials through a central cost table in `KingSpellState`.

## Artifacts architecture

1. Artifact definitions and implementation flags are centralized in `core/artifacts/artifact_catalog.gd`.
2. Runtime ownership/activation is managed by `core/artifacts/artifact_core.gd` (thin orchestrator).
3. Artifact logic is split into focused modules under `core/artifacts/`:
   - `ArtifactExternalMultiplierBridge.gd` - composition helper for applying external `BuildingUpgradeCore` multipliers on top of artifact query results
   - `ArtifactOwnershipFlow.gd` - owned/active state mutation, pickup-side queue updates, and activate/deactivate sequencing helpers
   - `ArtifactTraderBenefits.gd` - trader-specific benefit ownership for one-shot free coupon charges and extended market trade unlock checks
   - `ArtifactProductionHooks.gd` - output-aware production artifact ownership for post-cycle resource hooks, threshold rewards, and production-tracked state
   - `ArtifactProgressionFlow.gd` - early progression/runtime hooks for gaze rewards, king cooldown reductions, troop-building capacity bonuses, and unit-created rewards
   - `ArtifactBuildingCombatHooks.gd` - attacking-building damage bridge used by real combat buildings and shared building-damage consumers
   - `ArtifactWorkingBuildingFlow.gd` - working-building combat helper for artifact effects tied to active production ticks
   - `ArtifactState.gd` - state helpers (get/set int/float, periodic timers)
   - `ArtifactStatQueries.gd` - stat getter functions (HP/damage/move/proc/block multipliers and bonuses)
   - `ArtifactClassBonuses.gd` - class-based troop bonus application
   - `ArtifactHealDamage.gd` - heal troops, damage enemies utilities
   - `ArtifactSpellRewards.gd` - spell addition and spell choice queue
   - `ArtifactEffectExecutor.gd` - effect application (pickup/activate/deactivate)
   - `ArtifactEventHandlers.gd` - event callbacks (enemy_killed, wave_started, hero_died)
   - `ArtifactRuntimeFlow.gd` - periodic runtime effects, pending spell-choice opening loop, and scene-level periodic building-count effects
   - `ArtifactRuntimeTargetBridge.gd` - scene/runtime target lookup and pending reward enqueue bridge for artifact facade helpers
   - `ArtifactPersistenceFlow.gd` - save snapshot building, save-data normalization, reset payloads, and reapply sequencing
   - `ArtifactFriendlyDeathBuffDomain.gd` - death-reactive ally buff ownership for `hand_of_the_avenged`
   - `ArtifactDeathSummonDomain.gd` - death-trigger cooldown/spec ownership for effect spawn and recruit-on-death artifacts
   - `ArtifactBuildingLifecycleBonuses.gd` - starter-building durability/unit-limit bonus ownership for `iron_hoe`
4. Ownership and activation mutations remain facade-triggered in `ArtifactCore`, but the actual add/remove/activate/deactivate state transitions and pickup queue updates are delegated through `ArtifactOwnershipFlow`.
5. Class-based troop bonuses are applied through `TroopBonusCore` and re-applied on load to avoid stacking drift.
6. Spell-choice artifact pickups (for example `mages_notebook`) are queued in `ArtifactCore`, while the per-frame opening loop runs through `ArtifactRuntimeFlow` and opens `GameScene.open_reward_menu_spells()` only when reward menus are free.
7. Save/load/reset ownership remains on `ArtifactCore`, but the data shaping and normalization path is delegated through `ArtifactPersistenceFlow` so the facade only assigns loaded state and triggers reapply/reset side effects.
8. External production/spell multipliers from `BuildingUpgradeCore` are composed onto artifact query results through `ArtifactExternalMultiplierBridge`, keeping cross-core math out of the facade getters.
9. Runtime lookups for `TroopBonusCore`, `game_scene`, and pending artifact reward enqueue are delegated through `ArtifactRuntimeTargetBridge` so `ArtifactCore` does not embed scene-tree traversal details.
10. Deferred artifact pickups that should not interrupt gameplay immediately (for example `excavation_stone` resource-choice rewards and fixed spell grants) are converted into pending reward payloads and claimed through `GameScenePendingRewards`.
11. Player-facing artifact reward pools must use `artifact_catalog.gd` player-availability filtering so `implemented:false` entries never appear in reward menus or trader artifact offers.
12. Trader coupon spending stays in `TraderTransactionLogic.gd`, but coupon charge ownership and market-unlock queries stay in `ArtifactTraderBenefits.gd` behind thin `ArtifactCore` wrappers.
13. Early progression hooks stay facade-triggered in `ArtifactCore`, while concrete behavior lives in `ArtifactProgressionFlow.gd`; current consumers are `GazeCore`, `KingSpellState`, `BuildingUpgradeCore`, and `MapSlotProduction`.
14. Output-aware production artifacts are triggered from `MapSlotProduction.gd` through `ArtifactCore.on_resource_production_completed(building_id, outputs, production_count)`, while milestone tracking/reward side effects are owned by `ArtifactProductionHooks.gd`.
15. Production-threshold rewards that should not interrupt gameplay immediately (for example `clay_treasure` legendary artifact reward and `royal_order` legendary spell grants) must enqueue pending rewards instead of bypassing the reward-box flow.
16. `RewardMenuArtifacts.gd` now supports legendary-only artifact offers through `open_with_options(...)`, allowing deferred artifact rewards to reuse the same player-facing menu with rarity filtering.

## Item equipment visuals

1. Runtime item/equipment visuals are currently unified per equipment class, not per individual template.
2. Canonical runtime equipment icon folder is `res://assets/items/equipment/`.
3. Current canonical icons are `helmet.png`, `armor.png`, `sword.png`, and `ring.png`.
4. `modules/inventory/item_catalog.gd` remains the source of item visual `icon_path` values for generated equipment items.
5. `res://assets/takefromthis/` is intake-only and must not be referenced directly by runtime item/equipment visuals.
6. Smith/forge recipe visuals are also intentionally unified and must use the same canonical equipment icons from `res://assets/items/equipment/` instead of bespoke per-recipe craft button art.
17. Dynamic combat/stat artifacts that depend on current battlefield composition should stay query-driven in `ArtifactStatQueries.gd` instead of mutating permanent troop state; current users are `HeroStats.gd` (`poor_mans_relic` HP/damage), movement states (`golden_wings` move speed), and `HeroAttackingState.gd` (`twin_projectiles` bonus projectile chance).
18. `golden_wings` attack-speed ownership stays in `ArtifactClassBonuses.gd` through `TroopBonusCore`, while its move-speed half stays runtime-query-based so on-field movement refreshes immediately without extra persistent bookkeeping.
19. Temporary summon artifacts are owned by `ArtifactSummonFlow.gd`; wave-start spawns are triggered from `ArtifactEventHandlers.gd`, while `HeroOnField.gd` now supports a temporary-summon runtime mode that avoids `HeroCore` persistence and emits resurrection tokens for `second_chance`.
20. Seal/vzor/reward artifacts currently use three distinct ownership paths: `ArtifactRuntimeFlow.gd` for always-on external gaze (`stone_gaze`), `ArtifactEffectExecutor.gd` for immediate random seal placement (`enchanted_totem`, `trusty_compass`), and reward-menu-specific reroll cost queries through `ArtifactCore` (`voodoo_beads`).
21. `golden_arrow` currently hooks at mob spawn in `WaveSpawnService.gd` through `ArtifactCore.on_enemy_spawned(mob)` because there is no richer global enemy-introduction reward hook yet.
22. `healing_banner` currently hooks at hero death in `ArtifactEventHandlers.gd`, resolving the death position through `GameSceneHeroes` and spawning `HealingPoolEffect` directly into the map container; this is the highest-fidelity implementation available without introducing a new generalized unit-death effect bus.
23. `frag_bomb` is now implemented through the real attacking-building path: metadata lives in `artifact_catalog.gd`, the multiplier query lives in `ArtifactStatQueries.gd`, facade wrappers live in `artifact_core.gd`, and current runtime consumers are `TeslaTower.gd` and the upgraded damage pulse in `FairyFountain.gd`.
24. `sweeping_blade` is now implemented through the real working-production path: `MapSlotProduction.gd` forwards active working ticks into `ArtifactCore.on_working_building_tick(...)`, and `ArtifactWorkingBuildingFlow.gd` applies v1 damage only for `tree` and `sawmill` while the slot is actually producing.
25. `nether_contract` was removed from the game instead of forcing a non-canonical `nether_rune` runtime resource into the economy/UI stack.
26. `chi_fan` is implemented as artifact-state-backed flat HP growth per resolved spell cast: `GameSceneSpells.gd` calls `ArtifactCore.on_spell_cast(...)`, `ArtifactEffectExecutor.gd` increments persisted resolved-cast counters, `ArtifactStatQueries.gd` exposes the flat HP bonus, and `HeroCore` refreshes live hero max HP through the existing `artifacts_changed -> _on_troop_bonuses_changed -> HeroBonusSyncFlow` path.
27. `indestructible_shield` is implemented through real frontline damage entrypoints rather than static data mutation: `FriendlyDamageBlockHelper.gd` queries `ArtifactCore.get_friendly_full_damage_block_chance()` and is consumed by `HeroOnFieldStatusEffects.gd`, `HeroOnField.gd` temporary summons, `SmallBones.gd`, and `InfernalUnit.gd`.
28. `hand_of_the_avenged` is implemented through the hero-death event path: `ArtifactEventHandlers.gd` delegates to `ArtifactFriendlyDeathBuffDomain.gd`, which selects a living friendly valid recipient, applies temporary move/attack-speed multipliers, and owns timed cleanup plus status-icon removal.
29. `iron_hoe` is implemented through starter-building lifecycle wrappers, not generic speed modifiers: `MapSlotBuildingConfigFlow.gd` and `MapSlotProduction.gd` route building limits through `ArtifactCore`, while `ArtifactBuildingLifecycleBonuses.gd` doubles only canonical starter resource durability and starter troop-building unit limits.
30. `scarecrow_hat` is implemented through the death-trigger effect path: `ArtifactDeathSummonDomain.gd` defines the cooldown/spec, and `ArtifactEventHandlers.gd` spawns the canonical `BladecasterEffect.tscn` at the dead troop position.
31. `indescribable_figurine` is implemented as recruit-on-death via canonical content only: the death trigger resolves to `cacodaemon`, which has both `data/units/cacodaemon.tres` and `scenes/heroes/cacodaemon.tscn`; `ArtifactEventHandlers.gd` performs recruit + squad insert + battlefield positioning through `HeroCore`.
32. `tome_of_the_restless_souls`, `unexpected_finding`, and `ugly_apple` were removed from the game instead of keeping permanently blocked player-facing definitions without canonical runtime/content seams.

## Hero runtime contract

1. `HeroCore` remains the public hero facade, but fatigue/rest APIs are no longer part of the canonical runtime surface.
2. Hero battle availability is determined by life/state only; there is no tired-state exclusion step.
3. Hero UI bars/cards must not render Zz/tired indicators.
4. `HeroOnField.gd` should stay a facade/orchestrator; bootstrap-time node wiring such as watchdog timer creation belongs in `scripts/hero/modules/HeroOnFieldBootstrap.gd`.
4. Hero update notification + save-request boilerplate is delegated to `core/hero/HeroCoreNotificationBridge.gd`, while `HeroCore` keeps facade wrappers/public methods.

## Hero scene resolution canon

1. Hero/unit spawn scene resolution is centralized in `scripts/hero/HeroSceneRegistry.gd`.
2. Canonical entry scene format is `scenes/heroes/<unit_id>.tscn`.
3. Runtime and debug spawners must use the registry and must not use branch-based id matching for scene selection.
4. Hero entry scenes must be fully local/editable (no inherited wrapper roots).
5. Hero animation node contract for entry/base scenes is dual-node: `AnimWalk` + `AnimAttack` (`AnimatedSprite2D`).
6. Hero melee/ranged classification is resolved from `UnitConfig.unit_classes` via `scripts/hero/HeroCombatTypeResolver.gd`.
7. Authored hero-scene `SpriteFrames` are canonical when they already provide valid `walk`/`attack` content; runtime loader helpers must not replace them just because a same-id placeholder PNG exists.
8. `scripts/utils/HeroAssetLoader.gd` fallback order is: real direct animation folders first, placeholder single-texture frames last.
9. Placeholder hero sprites under `assets/characters/unit_placeholders/` are emergency fallback visuals only; they must not silently override working animated content for units such as `ballista`/`minotaur`.

## Mob facade contract

1. `scripts/mob/Mob.gd` remains the runtime facade/orchestrator for mobs and should preserve public wrapper methods used by states, spawners, and scene contracts.
2. Wall stand-off/range/approach calculations and wall-rule constants are owned by `scripts/mob/modules/MobWallTargetingFlow.gd`; `Mob.gd` should delegate wall-rule queries there instead of re-embedding the math.
3. Wall stop-distance override runtime state is stored on `scripts/mob/modules/MobMovement.gd`, keeping wall-target tuning state out of the facade.
4. Corpse-spawn execution in the death path is owned by `scripts/mob/modules/MobDeathFlow.gd`; `Mob.gd` may keep only thin compatibility wrappers.
5. Projectile spawn/setup for ranged and healer mobs is owned by `scripts/mob/modules/MobProjectileFlow.gd`; `projectile_speed` and `projectile_spin_speed_deg` are optional mob fields, and when a mob does not expose them the projectile scene defaults must be preserved instead of causing runtime property errors.
6. `Mob.gd` exposes `speed_multiplier` and `attack_speed_multiplier` proxy properties that delegate to `stats` (`MobStats`), allowing spell effects to apply modifiers via the mob facade without reaching into internal modules.

## Unit config path compatibility

1. UnitConfig runtime loading must go through `scripts/systems/PathRegistry.gd` (`resolve_unit_config_path`, `load_unit_config`, `unit_config_exists`) instead of hardcoded `res://data/units/<id>.tres` strings spread across systems.
2. Current alias compatibility in registry includes `small -> small_bones` (and `smallbones -> small_bones`) to avoid lookup failures from legacy/short ids.
3. Hero/troop/UI runtime consumers now use centralized unit-config resolution (`HeroData`, `troop_bonus_core`, `HeroOnFieldStats`, prophecy/town unit info panels), reducing migration risk for future folder moves.

## Wave flow

1. `WaveTimerBar.wave_triggered` drives wave release into `GameSceneWaves._on_wave_triggered`.
2. `GameSceneWaves` owns wave content selection (wave 0, prophecy queue, trader wave, placeholder waves).
3. `GameScene` listens to `GameSceneWaves.wave_completed` and opens reward UI.
4. `GameSceneBootstrap` owns `WaveTimerBar` setup/hookup: it resolves or instantiates the HUD timer, stores it on `GameScene`, connects it to `GameSceneWaves`, and assigns the wave-interval provider.
5. `GameSceneWaves` now delegates wave-state bookkeeping into `WaveStateFlow`, wave-start reset/notification timing into `WaveStartFlow`, mob scene lookup into `MobSceneRegistry`, mob-container iteration (`clear_mobs`, alive filtering, wall-stop propagation) into `MobContainerQuery`, preview rendering into `WavePreviewFlow`, special prophecy/trader completion handling into `SpecialWaveFlow`, branch selection into `WaveSpawnBranchFlow`, and placeholder prophecy wave generation into `WavePlaceholderFlow`.
6. `WaveSpawnService` owns mob-scene spawning plus `enemy_id -> scene -> tracked mob` delegation and prophecy-pattern iteration; `TraderWaveSpawner` owns the trader-specific spawn branch; `WaveTimerController` owns canonical wave-interval timing queries.
7. `GameSceneProcessLoop` owns per-frame `_process()` routing for spell-targeting updates, pause-sensitive drag/hover updates, and hero cleanup; `GameScene.gd` stays the facade entrypoint that forwards the tick.

## Main HUD architecture

1. `MainUI.gd` is the HUD composition root and should prefer delegation over embedding display logic.
2. Signal wiring into `EventBus`, `ResourceCore`, `CastleCore`, and reset dialog confirmation is delegated to `scripts/ui/hud/MainUISignalFlow.gd`.
3. Button wiring, hidden debug-button gating, and debug/perks button pressed routing are delegated to `scripts/ui/hud/MainUIButtonFlow.gd` instead of scene-level button connections.
4. Resource-bar direct/fallback lookup is delegated to `scripts/ui/hud/MainUIResourceBarResolver.gd`, while resource-label binding/lookup is delegated to `scripts/ui/hud/MainUIResourceBindingFlow.gd` and actual value refresh/presentation is delegated to `scripts/ui/hud/MainUIResourceDisplayFlow.gd`.
5. Popup host resolution and popup attachment are delegated to `scripts/ui/hud/MainUIPopupLayerBridge.gd`.
6. Overlay-to-HUD visibility routing is delegated to `scripts/ui/hud/MainUIOverlayFlow.gd`, while scene lookup for `hero_bar` and `hero_card` is delegated to `scripts/ui/hud/MainUIOverlayTargetBridge.gd`.
7. City overlay button routing, restart flow delegation, and debug grant actions are delegated to `scripts/ui/hud/MainUIActionFlow.gd`, while game-over popup lifecycle is delegated to `scripts/ui/hud/MainUIGameOverFlow.gd`.
8. Initial hidden-state gating for the hire panel is delegated to `scripts/ui/hud/MainUIHirePanelBootstrapFlow.gd`.
9. Startup HUD refresh orchestration is delegated to `scripts/ui/hud/MainUIStartupDisplayFlow.gd`.
10. Per-frame tooltip tick forwarding is delegated to `scripts/ui/hud/MainUITooltipProcessFlow.gd`.
11. Gold/stage/resource display event reactions are delegated to `scripts/ui/hud/MainUIDisplayEventFlow.gd`.
12. Public tooltip facade routing (`show/hide hero/enemy hp tooltip`) is delegated to `scripts/ui/hud/MainUITooltipFacadeBridge.gd`.
13. Perks test panel open-routing is delegated to `scripts/ui/hud/MainUIPerksPanelFlow.gd`.
14. Tooltip flow, town overlays, troop bonuses, and hero-hire flow remain separate helper modules and should continue growing through focused submodules, not by bloating `MainUI.gd`.

## Save architecture

1. `SaveCore` remains the autoload facade for persistence and save scheduling.
2. Save-target auto-registration and save-key derivation are delegated to `core/save/SaveRegistryFlow.gd`.
3. Autosave debounce scheduling is delegated to `core/save/SaveAutosaveFlow.gd`.
4. Save/load IO is delegated to `core/save/SaveIOFlow.gd`.
5. Reset-progress orchestration is delegated to `core/save/SaveResetFlow.gd`.
6. New persistence changes should extend these focused helpers or add adjacent save helpers, not re-grow `save_core.gd` into a mixed registry + debounce + IO + reset controller.

## Building upgrade architecture

1. `building_upgrade_core.gd` remains the public upgrade facade (thin wrappers only — monolith watchlist).
2. Slot/runtime lookup logic is delegated to `core/building_upgrade/BuildingUpgradeSlotQuery.gd`.
3. Upgrade unlock, normalization, and save/load translation are delegated to `core/building_upgrade/BuildingUpgradeRegistryFlow.gd`.
4. Upgrade-derived bonus/multiplier queries are delegated to `core/building_upgrade/BuildingUpgradeBonusFlow.gd`.
5. Future building-upgrade work should extend these helpers or add adjacent narrow helpers instead of re-growing `building_upgrade_core.gd` into a mixed scene-query + registry + bonus controller.
6. Artifact-aware troop-building capacity remains a facade wrapper in `building_upgrade_core.gd`; it must resolve the canonical `BuildingConfig` through `BuildingRegistry.get_building()` before delegating the artifact bonus query.

### Upgrade runtime effect helpers (Phase 2A–2C)

Economy/production helpers:
- `BuildingUpgradeProductionBoost.gd` — production speed multiplier lookup by building_id.
- `BuildingUpgradeProductionBonus.gd` — bonus resource/repair hooks per production cycle.
- `BuildingUpgradeNeighbourBoost.gd` — sawmill 20% neighbour boost (4 orthogonal).
- `BuildingUpgradeTroopInspiration.gd` — flat 10% class-wide HP/damage from mines/forge/mill.

Military/combat helpers:
- `BuildingUpgradeCapacityBonus.gd` — capacity bonus lookup by building_id.
- `BuildingUpgradeTroopStatModifier.gd` — per-unit HP/damage/evasion/attack-range modifiers.
- `BuildingUpgradeCombatHook.gd` — on-hit effects (DoT, stun, crit, lifesteal, slow, long shot, war of attrition, jumping lightning).
- `BuildingUpgradeDeathReward.gd` — on-death resource grants (peasant gold, gnome gold, barbarian metal).
- `BuildingUpgradeCostModifier.gd` — production cost multipliers (discounts and increases).
- `BuildingUpgradeMegaMilitia.gd` — mega militia global counter logic.

Elite/synergy helpers:
- `BuildingUpgradeUnitCounter.gd` — shared utility counting active heroes by unit_id on the battlefield.
- `BuildingUpgradeSpellDamageBoost.gd` — spell damage multipliers from paladins (+10% flat), ram (+20%/unit), unicorn (+10%/unit).
- `BuildingUpgradeUnitAura.gd` — unit-count-dependent auras (black unicorn morale, hydra global damage, minotaur flying buff, falcon mentoring HP).
- `BuildingUpgradeProductionEvent.gd` — post-production hooks (giants bedding resources, ram twins extra unit).
- `BuildingUpgradeLionCircus.gd` — griffin versatility (best-of-all-classes stat) + cost doubling.

Consumer systems wired:
- `MapSlotProduction.gd` — speed boost, neighbour boost, efficient processing, bonus rolls, capacity, cost modifier, production events.
- `MoraleSystem.gd` — vineyard/market/tavern/black unicorn morale hooks.
- `HeroStats.gd` — per-unit stat modifiers, hydra/minotaur/falcon/lion-circus auras.
- `HeroAttackingState.gd` — combat hooks (all on-hit effects including long shot, war of attrition, jumping lightning).
- `HeroOnFieldCombatAI.gd` — long shot projectile multiplier bridge.
- `HeroProjectile.gd` — damage_multiplier field for long shot distance scaling.
- `HeroOnFieldBootstrap.gd` — spawn-time modifiers (evasion chance, attack range).
- `ArtifactExternalMultiplierBridge.gd` — spell damage hooks (crystal mine, paladins, ram, unicorn).

### Upgrade icon presentation pipeline

1. `BuildingPresentationData.gd` provides canonical upgrade names and descriptions per building.
2. `BuildingUpgradeData.gd` is a thin facade that adds `get_upgrade_icon()` / `has_upgrade_icon()` delegating to `BuildingUpgradeIconResolver`.
3. `BuildingUpgradeIconResolver.gd` is a static class that maps `building_id:index` upgrade IDs to icon texture paths under `res://assets/ui/buildings/upgrade_icons/<building_id>/<index>_<slug>.png`. It lazy-loads textures with an internal cache.
4. UI surfaces wired to the icon resolver: `TraderOfferRoller` (trader tiles), `RewardBuildingUpgradeCard` (reward cards), `BuildingsTooltipExtras` (town tooltips), and `BuildingDetailsPanel` (details panels). Each preloads `BuildingUpgradeIconResolver` and calls `get_icon()` to display per-upgrade icons where available, with fallback to building icon or placeholder.
5. Not all upgrades have icons — only 33 entries across 16 buildings are currently mapped. Unmapped upgrades fall back gracefully.
6. `RewardBuildingUpgradeCard` upgrade status slots are 72x72 with `SlotIcon` (TextureRect, fill/keep-aspect-covered) and `DimOverlay` (ColorRect, semi-transparent black) children per slot. Dim overlay is visible when the upgrade is locked and hidden when unlocked or empty.
7. `RewardBuildingUpgradeCard` hover tooltip is a `PanelContainer > MarginContainer > VBoxContainer` with `top_level = true`, spell-style white `StyleBoxFlat` (bg 0.92/0.92/0.92/0.96, border 0.18/0.18/0.18/1.0, radius 6), positioned centered above the hovered slot with viewport clamping.
8. All labels in `RewardBuildingUpgradeCard` use `ThaleahFat.ttf` via `theme_override_fonts/font` and 25%-increased font sizes (title/name 23, description 20).

### Building upgrade audit runner

Three-layer headless audit system that validates building upgrade runtime effects without a running game scene.

**Architecture:**

1. **Matrix** (`BuildingUpgradeAuditMatrix.gd`) — static array of 141 dictionaries, each with `building_id`, `index`, `family` (effect type string), and family-specific expected fields (`expected_key`, `expected_value`, `expected_unit`, etc.). This is the single source of truth for what every upgrade should do at runtime.
2. **Harness** (`BuildingUpgradeAuditHarness.gd`) — creates a fresh `BuildingUpgradeCore` instance, exposes `unlock(building_id, index)` and query helpers that call into the core's public API. Provides test isolation without needing the full game scene tree.
3. **FamilyRunner** (`BuildingUpgradeFamilyRunner.gd`) — contains one verification method per effect family. Given a harness and a matrix entry, it unlocks the upgrade, queries the relevant helper, and returns a result dictionary with `status` (PASS / FAIL_LOGIC / FAIL_REFRESH / INCONCLUSIVE) and `detail` string.

**Result categories:**

- `PASS` — the upgrade's expected effect was found in the helper's runtime data after unlock.
- `FAIL_LOGIC` — the upgrade was unlocked but the expected effect was not found or had wrong values.
- `FAIL_REFRESH` — the upgrade's effect disappeared after a simulated refresh cycle.
- `INCONCLUSIVE` — the effect family requires scene-level integration (e.g. special building handlers like KingsStatue, LionCircus) that cannot be validated in a headless harness.

**Coverage (2026-03-29):** 111 PASS, 0 FAIL, 30 INCONCLUSIVE. The 30 INCONCLUSIVE entries are special-building upgrades whose effects live in per-slot scene scripts (`core/buildings/special/*.gd`), not in the centralized helper system.

## Current wave timing canon

These values are canonical for now **(may change as the project evolves)**:

1. Wave 0 starts after 100 seconds from run start.
2. Prophecy-cycle waves use 60-second spacing.
3. Trader wave also uses 60-second spacing.
4. First wave after trader (new prophecy cycle) starts after 90 seconds.

## Pause and reward flow

1. On wave completion, runtime wave progression is paused.
2. `WaveRewardMenu` pauses both scene tree and tick speed while open.
3. If prophecy selection is pending, closing wave reward opens `ProphecyMenu` while paused.
4. After prophecy confirmation, `GameScene` attempts to open an encounter modal before resuming progression.
5. Encounter modal pause is managed in `GameScene` (`_apply_encounter_pause_state` / `_release_encounter_pause_state`).
6. Non-wave rewards that previously opened immediately can now be translated into queued payloads and claimed later from the bottom-right HUD `reward_box` button.
7. Progression resumes after encounter closes (or immediately after prophecy when no encounter is available).
8. `GameSceneEncounterFlow.gd` must resolve `TickManager` through scene-tree/runtime lookup instead of a direct global identifier reference, so the module stays compile-safe in isolated/headless tests that omit the autoload.

## Encounter architecture

1. Encounter definitions are authored in `scripts/encounters/EncounterDefs.gd`.
2. Runtime validation, availability checks, and effect application are centralized in `scripts/encounters/EncounterService.gd`.
3. Encounter UI is `scenes/ui/encounters/EncounterMenu.tscn` + `scripts/ui/encounters/EncounterMenu.gd`.
4. Current canonical pool is Standard encounters only (25 ids).
5. Options with unmet resource requirements remain visible but are disabled in UI.
6. Encounter option effects can enqueue follow-up UI actions (for example `open_reward_menu_building_upgrades`) that `GameScene` executes after option selection.
7. `EncounterService` exposes compact per-option preview payload (`effects_text`, `requirements_text`, `effects_rows`, `requirements_rows`) with icon metadata.
8. `EncounterMenu` renders encounter options as styled card-buttons with primary icon plus effect/requirement rows, keeping rewards readable before selection.
9. For `spell_add` encounter effects, runtime first tries to inject the spell into the live `spell_panel` group (immediate slot visibility); fallback is `SpellCore` inventory when panel is unavailable.
10. Encounter spell config resolution is centralized through `scripts/systems/PathRegistry.gd` (no direct hardcoded spell-config directory paths in `EncounterService`).
11. `troops_add` effect grants hero units via `HeroCore.ensure_hero_template`, `HeroCore.hire_hero_copy`, and `HeroCore.add_to_squad`. Unit id aliases are resolved through `HeroSceneRegistry.UNIT_ID_ALIASES` (e.g., `undead_bone_warrior` -> `bone_warrior`).
12. `morale_add` effect modifies morale via `MoraleSystem.add_debug_morale`.

## Prophecy hover panel flow

1. `ProphecyMenu._on_card_unhovered()` applies delayed hide and re-checks whether the pointer is still over any `ProphecyWaveCard`.
2. Hover info stays visible when unhover is transient/noisy but card hover is still active.
3. Hover info is hidden only after card hover actually ends (or on explicit window-exit cleanup).
4. `ProphecyWaveCard` drag-and-drop start is guarded by a local pointer-distance threshold from press (`DRAG_START_DISTANCE_PX = 10.0`) so micro-movement remains a click and does not spawn drag preview flicker.

## Prophecy level 1 canon

1. `Prophecy 1` uses only `goblin_bandit`, `goblin_crossbowman`, `goblin_swordsman`, and rare-strong `goblin_pig` patterns.
2. `Wall buster` is forbidden in `Prophecy 1` and first becomes valid starting from `Prophecy 2`.
3. `ProphecyMenu` always shows `6 Easy + 6 Mid + 6 Hard` options in that top-to-bottom order.
4. `Easy` is mandatory: prophecy cannot continue until one `Easy` pattern is selected.
5. `Mid` is optional and unlocks only after `Easy` is selected.
6. `Hard` is optional and unlocks only after `Mid` is selected.
7. At most one pattern may be selected from each tier row, so a prophecy run resolves as `Easy`, `Easy + Mid`, or `Easy + Mid + Hard`.
8. `Easy` / `Mid` / `Hard` inside `Prophecy 1` share one threat corridor with intentional overlap; `Hard` is the top of the same early-game band, not a full next-tier jump.
9. Pure count-noise patterns such as `goblin_bandit x5` are non-canonical; early prophecy counts should stay deliberate/readable (`4`, `6`, or role-combined pairs).
10. `Prophecy 1` ordinary rewards are capped to `Denarii`, `Resource`, `Basic Production`, and `Levy Barracks`.
11. `Prophecy 1` rare-strong patterns may elevate reward ceiling only to `Established Production` or `Veteran Barracks`.

## Economy and Denarii flow

1. Denarii is managed by `EconomyCore`.
2. Canonical Denarii sources are reward systems tied to mob kills and selling recipes.
3. Selling any recipe in the build menu always gives exactly 5 Denarii.
4. Extended Denarii sources (for example king boosts) are expected future additions and must be documented when implemented.
5. Source-of-truth wording is maintained in this document and in `docs/PROJECT_NAVIGATOR.md` until a dedicated economy system page is restored.
6. Runtime costs that explicitly use `gold` in building construction and gaze upgrades are resolved against `EconomyCore`, while non-gold material costs continue to use `ResourceCore`.

## Building lifecycle flow

1. Placement/removal runtime is handled by `MapSlot.gd` + `TownCore` + `BuildingRegistry`.
2. Cost scaling and next-build pricing are resolved through `BuildingRegistry`.
3. Building affordability/payment treats `gold` costs as `EconomyCore` currency and all other cost entries as `ResourceCore` materials so market-earned Denarii immediately unlock construction.
4. Tool semantics (`sell`, `destroy`) are currently documented here and surfaced in `docs/PROJECT_NAVIGATOR.md` + `docs/wiki_buildings/`.
5. `MapSlot.gd` also orchestrates special-building slot UX: it owns popup toggles for `BasicConstructionUI`, `ResearchTableUI`, and `MarketUI`, while runtime behavior stays in focused handlers under `core/buildings/special/`.
6. Encounter-pause recovery for placed slots is delegated from `MapSlot.gd` into `scripts/map_slot/MapSlotRecoveryFlow.gd`, keeping touched-slot/building runtime restoration out of the facade.
7. `BasicConstruction.gd` is a timed placeholder special building: after its 30s build cycle it exposes a white `Nothing` slot-badge and converts only into the established-production mine targets configured in its handler/UI.
8. `MarketUI.gd` owns the market trade selector while `BuildingsTooltip` + `BuildingsTooltipContent` own hover rendering for trade exchange preview rows. Market trade tooltips must explicitly reset legacy arrow/prod/cons rows to avoid stale state leakage from previous building hovers.
9. Extended market trades (`clay`, `grapes`, `crystal`) are artifact-gated: unlock state comes from `ArtifactCore.has_extended_market_trades()`, UI option building stays in `MarketUI.gd`, and runtime rate resolution stays in `MapSlotMarket.gd`.
10. Map-slot selector popups (`MarketUI`, `ResearchTableUI`, `BasicConstructionUI`) run in overlay/top-level mode and must be positioned from the slot's global position, not from child-local offsets, or they will appear detached from the clicked building.
11. The research selector entry surface on a placed `research_table` / `research_laboratory` slot is a clickable badge button owned by `MapSlotBootstrap.gd`; it is not a passive visual-only badge.
12. Special-building selector popups are globally exclusive across map slots: opening one Market/Research/Basic Construction popup closes the others, and the opener button/badge stays hidden while its popup is visible.
13. Opening a special-building selector popup cancels active `VzorZone` drag immediately, and `VzorZone` also force-cancels drag while the tree is paused so drag cannot survive modal/pause transitions.
14. Slot-local unit count / durability overlays created by `MapSlotBootstrap.gd` must ignore mouse input, stay centered over the building cell, and use white text for both military and resource building counters.
15. `Arena.gd` is gaze-state driven: morale is granted only while the arena slot is currently active under gaze, and `Fight betting` is gated by upgrade state plus active gaze.
16. `ExecutionGround.gd` is a reserve-only castle consumer: it finds hired inactive grunt-class heroes in `HeroCore`, casts for 8 seconds, executes one reserve grunt, grants Denarii-equivalent gold, then waits 2 seconds before the next reserve check.

## Population and deploy cap

1. `PopulationCore.get_max_population()` is the authoritative battlefield cap.
2. Summoned units may exceed the cap when they are created by summon effects.
3. Normal deploy paths must still treat summons as occupied battlefield slots after they appear; no additional barracks/building deploy may enter the field when occupied count is already `>= cap`.
4. Shared occupied-field queries for those normal deploy guards are owned by `core/population/PopulationBattlefieldQuery.gd` and should be reused instead of re-embedding local counting rules.
5. `HeroCardBattle.gd` must keep already-fielded hired heroes in its battle-start list, but it must not add extra reserve heroes when the remaining normal field capacity is zero because summons already filled or overflowed the cap.

## Settings and combat UI defaults

1. `core/game_settings.gd` is the source of truth for persisted UI defaults such as damage-number visibility.
2. Damage numbers are disabled by default on cold start.
3. `DamagePopupPool.gd` must treat missing/unavailable `GameSettings` as disabled fallback behavior, not as implicit opt-in.

## Marker and positioning contract

1. `MapMarkerService` is the source of positions for portal/bridge/wall/defense markers.
2. Enemy wave spawning resolves positions from `MapMarkerService.get_random_spawn_position()` (spawn marker group).
3. `MapLayout` generates `32` spawn markers in a wider ring around the portal marker, so mob waves emerge with more spatial separation.
4. `MapMarkerService` uses a shuffled round-robin marker cycle before reusing a point, reducing same-marker streaks and visible overlap.
5. `MapLayout.spawn_markers_offset` (Inspector export) allows manual designer shift of the spawn cluster relative to the portal while preserving randomized spread.
6. Minotaur point-phase gnoll summons also use portal spawn marker positions (same global spawn contract as wave mobs).
7. Mob spawn dust VFX is instantiated in the mob parent container before world-position assignment to keep the effect aligned with spawned mob positions under transformed/YSort hierarchies.

## Spells architecture notes

1. `SpellConfig.gd` is the canonical spell config adapter and icon resolver for spell UI.
2. Spell icons are resolved from `res://assets/spells/` with runtime fallback texture loading when `.import` loader lookup fails in headless/runtime edge cases.
3. Icon resolver uses directory-based exact filename mapping and pre-checks file existence to avoid noisy missing-resource lookups and case-mismatch probes during UI build.
4. `SpellSlot.gd` must render icon via config fallback API (`get_icon_or_placeholder`) instead of direct raw `config.icon` access.
5. `DebugSpawnMenu.gd` must not overwrite spell icons with debug placeholders when adding spells.
6. `SummonInfernalsEffect.gd` is a direct summon flow and is not corpse-gated; corpse-based summon behavior remains owned by `NecromancyEffect.gd`.
7. `InfernalUnit.gd` targets nearest enemy globally when no enemy is inside close detection range, so summoned infernals behave as active frontline fighters instead of idling in place.
8. `ShieldsUpEffect.gd` applies timed allied area modifiers (`damage_taken_multiplier`, `speed_multiplier`) and restores original values on expiry.
9. `FireballEffect.gd` is the canonical meteorite strike runtime bound from `resources/spells/configs/meteorite.tres`: it spawns the projectile off-screen on the left/top side, travels diagonally left-to-right for a fixed 3 seconds, keeps projectile rotation disabled, then plays `assets/effects/Explosion2` contact animation and applies radius-based impact damage.
10. Spell-config path lookup for reward UIs and encounter spell grants is centralized in `scripts/systems/PathRegistry.gd` (`resolve_spell_config_path`, `load_spell_config`, `list_spell_config_ids`) to support staged folder migration without runtime breakage.
11. Shared spell-effect extraction helpers now live in `scripts/effects/shared/`:
    - `SpellEnemyTracker.gd` - enemy resolution, dead-target filtering, nearest/radius queries
    - `SpellDamageApplicator.gd` - canonical damage routing order (`Hurtbox.apply_hit` -> `apply_hit` -> `apply_damage` -> `take_damage`)
    - `SpellBoundsEnforcer.gd` - roaming-effect bounds clamp/bounce helper
    - `SpellVisualLifecycle.gd` - shared fade/lifetime tween helper for extracted effect expiry visuals
    - `SpellCaptureOrbitController.gd` - captured-target orbit/jitter helper for tornado-style effects
12. `InfernalUnit.gd`, `GroundfireEffect.gd`, `BlindingLightEffect.gd`, and `TornadoEffect.gd` remain effect-owned runtime facades, but repeated target lookup, damage routing, bounds enforcement, fade timing, and orbit math should be delegated through those helpers instead of duplicated per effect.
13. `StatusIconService.gd` (`scripts/effects/shared/`) is the shared static utility for buff/debuff status icons displayed above affected units. Key methods: `add_status_icon()`, `remove_status_icon()`, `reflow_status_icons()`. Icons are tagged with `set_meta("status_icon", true)` and arranged in a centered horizontal row with `STATUS_ICON_SPACING = 42.0`. All 9 buff/debuff spell effects use this service for consistent icon display.
14. `QuicksandEffect.gd` is the persistent-area slow debuff (replaced `SlowZoneEffect`): 10-second duration, `speed_multiplier *= 0.5` on enemies inside, continuous enter/leave tracking with `CHECK_INTERVAL = 0.2s`, divide-out modifier removal pattern, and StatusIconService integration. Config: `resources/spells/configs/quicksand.tres`. Scene: `scenes/spells/effects/QuicksandEffect.tscn` with editor-authored SpriteFrames (6 frames from `assets/vfx/spells_visuals/Quicksand/`).
15. Modifier removal for buff/debuff effects must use the divide-out pattern (`entity.speed_multiplier = maxf(0.01, float(entity.speed_multiplier) / applied_mult)`) — never hardcoded reset to `1.0`. This prevents breakage when multiple effects overlap.
16. Snapshot AoE buff/debuff spells that only apply on cast (`WeaknessEffect.gd`, `WrathEffect.gd`) must not rely solely on immediate `Area2D.get_overlapping_bodies()` results for target acquisition; they should use reliable group-plus-radius collection (or equivalent fallback) so overhead status visuals are applied consistently in runtime and headless verification.
17. `ImmortalityEffect.gd` is now a persistent enter/leave allied area effect rather than a one-shot snapshot buff: heroes are invincible only while inside the area, receive an overhead status icon plus per-hero floor VFX, and lose both immediately on exit or when the spell expires. The floor animation is authored as scene-owned `SpriteFrames` in `scenes/spells/effects/ImmortalityEffect.tscn` using frames from `assets/vfx/spells_visuals/Immortality/`.
18. Spell smoke verification is split between `scripts/dev/verify/verify_scenes.gd` (loadability smoke roster) and `scripts/dev/tests/test_spell_scene_smoke_roster.gd` (registry/catalog/scene coverage guard) so new spell configs do not silently fall out of verification coverage.
19. The battlefield spell hover popup shown by `SpellPanel.gd` is the canonical runtime spell description surface. Readability changes to spell descriptions should be made there (panel width, padding, title/body typography) without changing spell slot sizes unless the task explicitly asks for slot scaling.
20. `FrailtyEffect.gd` and `RootsEffect.gd` should use scene-owned animation resources for their ground-impact visuals instead of runtime filesystem frame crawling. Target point alignment belongs to the authored scene/child animation node, not to moving the entire effect root away from the cast point.
21. `PoisonPuddleEffect.gd` now owns poison-zone visual state on enemies in addition to DoT damage: affected mobs are tinted green while inside the puddle and must restore their original `modulate` cleanly on exit/expiry.
22. `LandmineEffect.gd` trigger size, visual size, and explosion expectations must stay aligned; avoid tiny trigger-only collision shapes that make enemies visually walk through mines before detonation. Landmine now scans for pre-existing overlaps on spawn using a 3-tier detection method (overlapping bodies, overlapping areas, group-based radius fallback) so enemies already on top of a spawned mine trigger immediate detonation.
23. `TornadoEffect.gd` capture must not rely on overlap queries alone; it should retain a reliable enemy-radius fallback so capture/orbit/damage continue working when collision-layer setups vary across enemy scenes.
24. `ArmageddonEffect.gd` start VFX now uses authored `SpriteFrames` resource ownership instead of runtime frame crawling. `FreezeEffect.gd` and `IncinerationEffect.gd` are now concrete spell effects with scenes/config bindings and must remain included in spell smoke verification.
25. `LastStandEffect.gd` is a persistent enter/leave allied area effect that grants invincibility and heals 110 HP/s to heroes while inside. Uses separate stack meta keys (`last_stand_effect_stack_count` / `last_stand_effect_original_invincible`) from `ImmortalityEffect` so both can coexist. Scene: `scenes/spells/effects/LastStandEffect.tscn` with editor-authored 16-frame SpriteFrames at 12 FPS, `StandAnim` at 2x scale, `DetectionArea` with CircleShape2D r=100. Config: `resources/spells/configs/last_stand.tres`.
26. `ScarecrowEffect` has been fully removed from the game (config, scene, script, debug catalog, verification roster, audit maps).
27. The `KEY_V` debug dragon spawn hotkey has been removed from `GameSceneDebug.gd` and the keybind legend from `DebugSpawnMenu.gd`.

## Building upgrade QA workbench architecture

1. The in-game QA workbench is a three-file system under `scripts/dev/qa/` and `scripts/ui/debug/`.
2. `BuildingUpgradeQaRunner.gd` — static-only orchestrator; wraps `BuildingUpgradeFamilyRunner` for all/family/building/failed subsets; returns `Array[Dictionary]` of structured results per entry.
3. `BuildingUpgradeQaReportStore.gd` — static-only I/O layer; writes `latest.json`, `latest.md`, `latest_failed.json`, and timestamped `history/<ts>.json` to `user://qa_reports/building_upgrade/`; completely separate from game save files.
4. `BuildingUpgradeQaPanel.gd` — `CanvasLayer` (layer 101) that builds its UI in code (no `.tscn`); toggled by F11; instantiated as sibling of `DebugSpawnMenu` via `DebugSpawnMenu._setup_qa_panel()`.
5. The panel never touches `save.json` or `SaveManager`; QA I/O uses its own `BuildingUpgradeQaReportStore` write path.
6. Result dict shape: `{ upgrade_id, building_id, upgrade_index, family (int), family_name (str), status, ran_at }`.
7. Status codes match the headless runner: `PASS`, `FAIL_LOGIC`, `FAIL_REFRESH`, `INCONCLUSIVE`.

## Reward and prophecy UI extraction notes

1. `ProphecyMenu.gd` remains the scene-owned prophecy facade/orchestrator.
2. `scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd` owns rewards-info popup hover/show/hide/drag flow plus delayed hover-panel hide behavior.
3. `RewardMenuTrader.gd` remains the trader menu facade for open/close, affordability refresh, tooltip lifecycle, and transaction wiring.
4. `scripts/ui/rewards/modules/TraderOfferRoller.gd` owns trader offer section rolling, building-upgrade reroll composition, and troop-section reroll logic; `RewardMenuTrader.gd` should keep only thin wrappers/delegation entrypoints.

## Spell UI layout note

1. Spell slot size is intentionally scaled by +50% (from 51 to 76.5) for readability and touch/mouse interaction comfort.
