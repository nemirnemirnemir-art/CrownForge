# BLOATED_SCRIPTS

| Путь | Строк | Проблема | Серьёзность | Рекомендация | Сложность |
|------|------:|----------|-------------|--------------|----------|
| `res://scripts/ui/hud/MainUI.gd` | 921 | >500 lines | 🔴 Critical | Split into focused UI controllers (e.g. `MainUIInventory`, `MainUITownPanels`, `MainUITooltips`, `MainUIResources`) orchestrated by `MainUI` | Hard |
| `res://scripts/hero/HeroOnField.gd` | 718 | >500 lines | 🔴 Critical | Split into movement/AI/combat/targeting components; keep `HeroOnField` as thin orchestrator | Hard |
| `res://scripts/map/MapSlot.gd` | 765 | >500 lines | 🔴 Critical | Split slot UI/interaction, building placement, state/persistence, visuals | Hard |
| `res://core/skill_core.gd` | 747 | >500 lines | 🔴 Critical | Split skill data/catalog, runtime state, effects application, UI-facing API | Hard |
| `res://core/town_core.gd` | 602 | >500 lines | 🔴 Critical | Split into Town modules (buildings/resources/perks/production) + thin orchestrator (some modules already exist; unify pattern) | Medium |
| `res://scripts/mob/Mob.gd` | 513 | >500 lines | 🔴 Critical | Split into components: health/combat/movement/state-machine glue, effects; keep `Mob` orchestrator | Medium |
| `res://scripts/game/GameScene.gd` | 513 | >500 lines | 🔴 Critical | Split orchestration by subsystem (some already extracted into `scripts/game_scene/*`); reduce remaining responsibilities in `GameScene.gd` | Medium |
| `res://core/hero_core.gd` | 425 | >300 lines | 🟡 High | Verify SRP; consider splitting recruitment/squad/progression/services (some are already modules) | Medium |
| `res://core/save_core.gd` | 306 | >300 lines | 🟡 High | Split save IO vs module registration vs scheduling; keep thin facade | Medium |
| `res://scripts/ui/hud/SkillsPanel.gd` | 315 | >300 lines | 🟡 High | Split UI rendering vs input vs data-binding (skills state) | Medium |
| `res://scripts/systems/DamagePopupPool.gd` | 319 | >300 lines | 🟡 High | Split pooling vs container management vs formatting; keep facade | Medium |
| `res://core/forge_core.gd` | 320 | >300 lines | 🟡 High | Split crafting state machine vs pricing/recipes vs persistence | Medium |
| `res://scripts/components/AttackComponent.gd` | 308 | >300 lines | 🟡 High | Split hit timing, target selection, projectile spawning, damage calc into smaller components | Medium |
| `res://scripts/ui/debug/DebugSpawnMenu.gd` | 472 | >300 lines | 🟡 High | Split UI layout vs spawn commands vs debug data providers | Medium |
| `res://scripts/ui/gaze/VzorZone.gd` | 341 | >300 lines | 🟡 High | Split zone logic vs visuals/animation vs state | Medium |
| `res://scripts/ui/building/BuildingMenu.gd` | 305 | >300 lines | 🟡 High | Split filtering/sorting vs card rendering vs interaction handlers | Medium |
| `res://scripts/ui/town/TownInventoryPanel.gd` | 353 | >300 lines | 🟡 High | Split tabs/layout vs item rendering vs transfer logic (some already in `TownInventoryPanel*` helpers) | Medium |
| `res://modules/inventory/inventory_core.gd` | 345 | >300 lines | 🟡 High | Split inventory state, drop/spawn logic, persistence, and UI-facing API | Medium |
| `res://scripts/ui/town/BuildingsTooltip.gd` | 598 | >500 lines | 🔴 Critical | Split tooltip composition: data extraction vs formatting vs UI rendering | Medium |
| `res://scripts/ui/town/SmithCraftPanel.gd` | 674 | >500 lines | 🔴 Critical | Split smith recipes/inventory view/craft actions into sub-panels or components | Medium |

## Details (draft)

### `res://scripts/ui/hud/MainUI.gd`

- **Responsibilities mixed**
  - Resource bar updates / polling (`_refresh_all_resources`, `_on_resource_changed`)
  - Global signals plumbing (`_connect_signals` connects `EventBus.*` + `ResourceCore.*` + `CastleCore.*`)
  - Debug actions (`_on_test_gold_button_pressed`, population/debug building levels)
  - Tooltip systems for hero HP / enemy HP (`_ensure_*_tooltip`, `_update_*_tooltip`)
  - “Game over” UI creation (`ColorRect.new()`, `Label.new()`, `Button.new()`)

- **Evidence / coupling markers**
  - Hard dependencies on multiple autoloads: `EventBus`, `ResourceCore`, `EconomyCore`, `TownCore`, `HeroCore`, `CastleCore`.
  - Dynamic UI creation via `*.new()` (tooltips + game over panel).
  - Scene-tree assumptions via `get_node_or_null(...)` (e.g. `GameOverPanel`, mob health component path, hire UI).

- **Split plan (draft)**
  - `MainUIResources`:
    - resource label cache, `ResourceCore.resource_changed` binding, `EconomyCore.get_gold()` refresh.
  - `MainUITooltips`:
    - hero/enemy tooltip creation + positioning + cleanup.
  - `MainUIGameOver`:
    - game over overlay creation + restart button.
  - `MainUIDebugActions`:
    - debug gold/building/population helpers.
  - Keep `MainUI.gd` as orchestrator: scene references + wiring only.

### `res://scripts/hero/HeroOnField.gd`

- **Responsibilities mixed**
  - State-machine wiring + fallback dynamic creation of state machine and states.
  - Combat parameters + projectile firing.
  - Health + damage application (incl. evasion/invincibility flags).
  - UI hover tooltips integration via `get_tree().get_first_node_in_group("main_ui")`.
  - Watchdog / stuck detection and failsafes.

- **Evidence / coupling markers**
  - Multiple state classes `preload(...)` and dynamic `Hero*State.new()` creation.
  - Multiple `get_node_or_null(...)` fallbacks for animation nodes (`AnimationSprite2D`, `AnimWalk`, `AnimatedSprite2D`) and components (`AttackComponent`, `AggroArea`, `Hurtbox`, etc.).
  - Uses external systems: `HeroCore` for stats / ids, and expects specific node names.

- **Split plan (draft)**
  - `HeroOnFieldStateMachineBinder`:
    - locate/create `HeroStateMachine`, register states.
  - `HeroOnFieldCombat` (already exists):
    - keep projectile logic + damage; ensure inputs are passed in via interfaces.
  - `HeroOnFieldHealth` (already exists):
    - own HP, death, healed, tooltip hooks (or move tooltip hooks to UI side).
  - `HeroOnFieldWatchdog`:
    - stuck detection + failsafe transitions.
  - Reduce `HeroOnField.gd` to assembly + delegating to modules.

### `res://scripts/map/MapSlot.gd`

- **Responsibilities mixed**
  - Slot UI state (highlight/progress/durability labels).
  - Building placement + production ticking (new `BuildingConfig` path + legacy `PRODUCTION_CONFIG`).
  - Market subsystem embedded inside slot (market active resource, market UI instancing).
  - Durability depletion and building removal (calls `TownCore.remove_building(slot_index)`).
  - Visual effects / animations (production “floating” resource icons, radial textures via `load()` loop).

- **Evidence / coupling markers**
  - Significant dynamic UI creation: `Label.new()`, `Button.new()`, `TextureRect.new()`, `HBoxContainer.new()` etc.
  - Asset-path coupling: `load("res://assets/ui/radialProgressBar/%d.png")`, and resource icon lookup based on string ids.
  - Hard dependencies: `ResourceCore`, `EconomyCore`, `TownCore`, `HeroCore`, `BuildingRegistry`/`BuildingConfig`.

- **Split plan (draft)**
  - `MapSlotView`:
    - highlight/progress/radial rendering, durability UI.
  - `MapSlotProduction`
    - ticking logic and completion for `BuildingConfig`/legacy dict.
  - `MapSlotMarket`
    - market UI instancing + trade logic + rate table.
  - `MapSlotBuildingState`
    - apply/clear building id, persist/remove building (TownCore interaction), durability.

### `res://core/town_core.gd`

- **Responsibilities mixed (module orchestrator)**
  - Initializes many modules (`TownBuildings`, `TownPotions`, `TownPopulation`, `TownProduction`, `TownPerks`, `TownHospital`, `TownBonuses`, `TownInventory`, `TownAlchemyCraft`, `TownShop`, `TownMageTower`).
  - Owns a lot of public API that delegates to modules.

- **Evidence / coupling markers**
  - Centralized module creation via many `.new()` calls.
  - Own signals like `population_changed`, `building_upgraded` plus forwarding.
  - Loads config resource: `load("res://data/build_config.tres")`.

- **Split plan (draft)**
  - Keep `TownCore` strictly as *facade + module registry*.
  - Move all “computed orchestration” into modules (and use `EventBus` where cross-module events needed).
  - Ensure each module exposes a narrow interface; document ownership of persistence.

### `res://core/skill_core.gd`

- **Responsibilities mixed**
  - Skill runtime state (mana, timers, durations).
  - Effects application + VFX spawning (e.g. `load("res://core/effects/GoldDropEffect.tscn")`).
  - Emits signals on activation/end and also emits on `EventBus` (`skill1_toggled`).

- **Evidence / coupling markers**
  - Emits own signals + touches `EventBus` directly.
  - Spawns effect scenes and uses RNG inline.

- **Split plan (draft)**
  - `SkillCatalog` (data): durations/costs/ids.
  - `SkillRuntimeState` (mana/timers).
  - `SkillEffects` (spawn scenes/apply status effects).
  - `SkillCore` stays as thin API for UI and other systems.

### `res://scripts/game/GameScene.gd`

- **Current state**
  - Already partially split into `scripts/game_scene/*` managers via `preload(...)` and `.new()` (`GameSceneUI`, `Waves`, `Stages`, `Heroes`, `Debug`, `Signals`, `Spells`).
  - Still contains fallback node creation and direct scene-tree wiring (`HeroPivot`, `DebugSpawnMenu`, `WaveTimerBar`, spell targeting circle, ghost building sprite).

- **Split plan (draft)**
  - Continue extracting leftovers:
    - `GameSceneWorldNodes` (hero pivot + map/world container invariants)
    - `GameSceneDebugOverlay` (DebugSpawnMenu instancing)
    - `GameSceneBuildingPlacement` (ghost building + tool interactions)

### `res://scripts/mob/Mob.gd`

- **Responsibilities mixed**
  - Node references by name (`AnimWalk`, `AnimAttack`, `AggroArea`, `AttackComponent`, `MobStateMachine`...).
  - Initializes runtime modules (`MobCombat.new()`, `MobAnimations.new()`) and watchdog timer.
  - Has death-animation fallback creation similar to heroes.

- **Split plan (draft)**
  - `MobSceneBinder`: node lookup/validation for required nodes.
  - `MobWatchdog`: stuck/timeout handling.
  - Keep `MobCombat`/`MobAnimations` as components (already there).

### `res://scripts/ui/town/BuildingsTooltip.gd`

- **Responsibilities mixed**
  - Data extraction (building config/resources/units/upgrades).
  - UI rendering (instancing rows from scenes and manual `HBoxContainer.new()`/`Label.new()` for unit rows).
  - Icon loading and fallbacks (`ResourceLoader.exists`, `load(...)`, label fallback).

- **Split plan (draft)**
  - `BuildingsTooltipDataProvider` (pure data, no nodes).
  - `BuildingsTooltipRenderer` (UI nodes only, takes DTO).
  - `BuildingsTooltipIconResolver` (paths + fallback strategy).

### `res://scripts/ui/town/SmithCraftPanel.gd`

- **Responsibilities mixed**
  - Recipes list rendering + scrolling.
  - Slot queue state and ticking (`Timer.new()`), cancellation.
  - Ingredient UI generation via dynamic nodes (`HBoxContainer.new()`, `TextureRect.new()`, `Label.new()`).
  - Loads icons and uses multiple resources/constants.

- **Split plan (draft)**
  - `SmithCraftRecipesModel` (recipe list, sorting/filter, selection).
  - `SmithCraftQueueModel` (slot state, tick, cancel).
  - `SmithCraftUIRenderer` (updates nodes; no business logic).

### `res://core/hero_core.gd`

- **Responsibilities mixed (facade + domain + events)**
  - Exposes many hero operations (hire/recruit/squad/battle/damage/stats/buffs/items).
  - Owns/forwards many signals (`hero_created`, `hero_hp_changed`, `hero_died`, `squad_changed`, etc.).
  - Wires to `EventBus` (`EventBus.wave_completed`, `EventBus.hero_recruited`, `EventBus.hero_died`, `EventBus.battle_started/battle_ended`, etc.).

- **Evidence / coupling markers**
  - Initializes many submodules via `.new()` (`HeroData`, `HeroQuery`, `HeroMutator`, `HeroPerks`, `HeroRecruitment*`, `HeroSquad`, `HeroItems`, `HeroHealth`, `HeroBuffs`, `HeroStats`, `HeroProgression`, `HeroCombat`, `HeroBattle`).
  - Mixes “domain state” with “event routing” (both own signals and `EventBus`).
  - Touches persistence boundary via `SaveCore.request_save()`.

- **Split plan (draft)**
  - Keep `HeroCore` as facade + module registry only.
  - Group public API into sub-facades:
    - `HeroCoreRecruitmentApi`, `HeroCoreSquadApi`, `HeroCoreBattleApi`, `HeroCoreInventoryApi`.
  - Consolidate event strategy:
    - Either core emits only its own signals (UI binds here), or it emits only on `EventBus` (but not both for same event).

### `res://core/save_core.gd`

- **Responsibilities mixed**
  - Save/load orchestrator for multiple autoload modules via `project.godot` autoload list and `get_node_or_null("/root/<autoload>")`.
  - File IO through `save_manager.gd` (`write_json`, etc.).
  - Also performs “reset progress” by mutating core internals and emitting signals (`EventBus.gold_changed`, `EventBus.stage_changed`, `EventBus.forge_cores_changed`, `ResourceCore.resource_changed`, etc.).

- **Evidence / coupling markers**
  - Hard runtime coupling to autoload paths (`/root/...`) + direct field mutation (e.g. `EconomyCore._current_gold`, `StageCore._current_stage`).
  - Emits global signals directly (`EventBus.game_saved`, `EventBus.game_loaded`).

- **Split plan (draft)**
  - `SaveRegistry`:
    - resolves save-capable modules and their keys.
  - `SaveIO`:
    - JSON read/write, versioning, backups.
  - `ProgressResetService`:
    - single place for “new run” reset logic; avoid direct mutation of private fields where possible.

### `res://scripts/ui/hud/SkillsPanel.gd`

- **Responsibilities mixed**
  - Builds/updates skill UI (creates timer labels via `Label.new()`).
  - Loads skill icons dynamically (`load("res://assets/skills/%d.png")` guarded by `ResourceLoader.exists`).

- **Split plan (draft)**
  - `SkillsPanelRenderer`:
    - nodes only.
  - `SkillsPanelIconCache`:
    - lazy loading and caching of textures.
  - `SkillsPanelBinding`:
    - reads from skill runtime (likely `SkillCore`) and updates renderer.

### `res://scripts/systems/DamagePopupPool.gd`

- **Responsibilities mixed**
  - Pool lifecycle + container management (`Node2D.new()` container).
  - Popup spawn rules and batching (batch radius/time window) and throttling.
  - Exposes behavior via many `@export` tuning knobs.
  - Loads popup scene (`preload("res://scenes/ui/overlays/DamagePopup.tscn")`).

- **Split plan (draft)**
  - `DamagePopupPool`:
    - only pool acquire/release + container.
  - `DamagePopupBatcher`:
    - pending hits merge rules.
  - `DamagePopupSpawner`:
    - translate “damage event” -> popup instance + positioning rules.

### `res://core/forge_core.gd`

- **Responsibilities mixed**
  - Currency generation (forge cores gained) + crafting slots state machine.
  - Emits many signals (`forge_cores_gained`, `crafting_started/completed/claimed/tick`).
  - RNG and item generation inside core (`RandomNumberGenerator.new()`).

- **Split plan (draft)**
  - `ForgeCraftingSlots`:
    - owns `crafting_slots` data and tick/claim transitions.
  - `ForgeEconomy`:
    - forge cores earn/spend rules.
  - `ForgeItemGenerator`:
    - RNG-based item templates and stat rolls.

### `res://scripts/components/AttackComponent.gd`

- **Responsibilities mixed**
  - Attack timing state machine + animation window options.
  - Hitbox/shapecast maintenance (`get_node_or_null(NodePath)` fallbacks + runtime `RectangleShape2D.new()` / `CircleShape2D.new()`).
  - Projectile spawning parameters (`@export var projectile_scene`, speed) + damage emit (`hit_landed`).
  - Debug visual creation (`ColorRect.new()` under hitbox).

- **Split plan (draft)**
  - `AttackTiming`:
    - cooldown/attack window/hit window state.
  - `AttackHitboxBinder`:
    - resolves nodes from NodePath + validates fallbacks.
  - `AttackDebugOverlay` (optional):
    - debug visuals separated from runtime logic.

### `res://scripts/ui/debug/DebugSpawnMenu.gd`

- **Responsibilities mixed**
  - In-code UI construction (large `_build_ui()` with many `*.new()` nodes).
  - Stores large registries of scenes in dictionaries via `preload(...)` (heroes, mobs, small bones, artifact panel).
  - Provides spawn commands + debug actions + spell add actions.

- **Split plan (draft)**
  - `DebugSpawnMenuView`:
    - create nodes and wire UI events.
  - `DebugSpawnMenuActions`:
    - spawn hero/mob/skeleton, add spell, toggle artifacts panel.
  - `DebugSpawnMenuCatalog`:
    - constants for scene registries and icons.

### `res://scripts/ui/gaze/VzorZone.gd`

- **Responsibilities mixed**
  - Input/drag behavior + snapping to map grid.
  - Validation state (`_valid_cells`, “invalid” color) and drawing.
  - Multiple tuning `@export` for visuals and drag behavior.

- **Split plan (draft)**
  - `VzorZoneModel`:
    - valid cell computation and last-valid tracking.
  - `VzorZoneView`:
    - drawing only, takes model state.
  - `VzorZoneDragController`:
    - pointer handling and smoothing.

### `res://scripts/ui/building/BuildingMenu.gd`

- **Responsibilities mixed**
  - UI state: paging, category filtering, tool buttons, selection.
  - Tooltip instancing (`BuildingsTooltipScene.preload`, hover handling).
  - Emits selection/drag signals (`building_selected`, `building_drag_started`).
  - Heavy reliance on scene node paths via `get_node_or_null(...)`.

- **Split plan (draft)**
  - `BuildingMenuModel`:
    - selected id, active tool, paging/category state.
  - `BuildingMenuRenderer`:
    - tile creation and visuals.
  - `BuildingMenuToolController`:
    - tool selection/visual refresh.
  - `BuildingMenuTooltipController`:
    - tooltip lifecycle and positioning.

### `res://scripts/ui/town/TownInventoryPanel.gd`

- **Responsibilities mixed**
  - UI scene wiring + font application.
  - Instantiates submodules via `.new()` (`TownInventoryPanelTransfers`, `TownInventoryPanelSlots`, `TownInventoryPanelUtility`).
  - Dynamic popup loading/instancing (`load("res://scenes/ui/HeroSelectionPopup.tscn")`).
  - Has “unfinished glue” markers (e.g. `pass` placeholders around drag/drop wrapper logic).

- **Split plan (draft)**
  - Keep current module split, but make `TownInventoryPanel.gd` only:
    - locate nodes, create modules, forward UI signals.
  - Formalize a DTO for drag/drop payload and always include context (`player`/`town`).
  - Extract “hero equip flow” into a dedicated controller (`TownInventoryEquipToHeroController`).

### `res://modules/inventory/inventory_core.gd`

- **Responsibilities mixed**
  - Inventory state + signals (`inventory_updated`, `item_added/removed`, `item_equipped`).
  - Drop generation logic (rarity rolls, ingredient drops) using RNG inline.
  - World spawn logic (instantiates `DropItem.tscn`, finds world container via `get_tree().current_scene.get_node_or_null(...)`).

- **Split plan (draft)**
  - `InventoryState`:
    - items array, add/remove/equip, signals.
  - `LootGenerator`:
    - RNG rolls, templates by mob type, rarity rules.
  - `DropSpawner`:
    - responsible for finding correct world container and spawning drop scenes.
