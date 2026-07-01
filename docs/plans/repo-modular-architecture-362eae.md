# Repo Modular Architecture Plan

This plan defines the target repo-wide architecture for Clickcer as a system of thin feature orchestrators over small focused mini-modules, with scene-first composition and explicit ownership boundaries.

## Goal

Bring the whole project to one consistent architectural model:

1. feature root script = orchestrator only
2. concrete behavior = focused mini-modules
3. static data = resources/registries/catalogs
4. cross-feature communication = signals, facades, and explicit adapters
5. scene composition = `.tscn` first where editor-authored structure is possible

## Context from current repo

The repo already contains several good partial examples of the desired style:

1. `scripts/game/GameScene.gd` already delegates to many `GameScene*` modules
2. `scripts/ui/hud/MainUI.gd` already delegates to focused HUD helpers
3. `scripts/map/MapSlot.gd` already uses a broad `scripts/map_slot/` split
4. `core/hero_core.gd` and `core/town_core.gd` already act as autoload facades over internal flows/modules

The problem is inconsistency:

1. some systems are already thin orchestrators
2. some systems are still mixed controller + logic + scene lookup + state mutation
3. module naming is uneven across folders
4. several systems still cross runtime boundaries too directly

## Architectural approaches considered

### Approach A - Big-bang normalization

Standardize the entire repo around one module taxonomy in one large refactor.

Pros:
1. fastest route to consistency
2. easiest to enforce one naming convention

Cons:
1. highest breakage risk
2. hardest to verify across gameplay, UI, saves, and autoloads
3. too much moving code at once

### Approach B - Opportunistic cleanup only

Refactor modules only when a feature is touched for gameplay work.

Pros:
1. low short-term cost
2. minimal disruption

Cons:
1. architecture stays uneven for a long time
2. no stable target model
3. future changes keep reintroducing mixed patterns

### Approach C - Canonical target architecture + phased migration

Define one strict target shape for all major subsystems, then migrate subsystem-by-subsystem toward that shape.

Pros:
1. gives one repo-wide standard
2. allows incremental safe migration
3. matches the project's existing partial modularization

Cons:
1. requires discipline while the repo is in mixed state
2. needs documentation enforcement during each phase

## Recommendation

Use **Approach C**.

The repo is already far enough into modular patterns that a full rewrite is unnecessary, but still inconsistent enough that opportunistic cleanup alone will not converge to a clean structure. The target architecture should be defined first, then applied phase-by-phase.

## Target repo-wide architecture

### 1. Top-level rule

Every major feature should follow this hierarchy:

`Scene/Autoload Root -> Orchestrator -> Mini-Modules -> Data/Configs/Scene Children`

The root script must not become the place where all real work happens.

### 2. Allowed responsibilities for an orchestrator

A feature-entry script may:

1. bind node references
2. construct module instances
3. inject dependencies into modules
4. connect signals
5. own lifecycle sequencing (`_ready`, open/close flow, startup/shutdown)
6. expose a small compatibility/public API for outside callers
7. coordinate between modules when more than one module is involved

A feature-entry script should not directly own:

1. large rule tables
2. presentation formatting details
3. business logic calculations
4. repeated validation branches
5. low-level data mutation helpers
6. large save/load serialization blocks
7. direct deep-tree traversal across unrelated features

### 3. Standard mini-module taxonomy

Use the same small set of module roles across the repo.

#### A. `*Bootstrap`

Use for:
1. initial node discovery
2. dependency validation
3. wiring startup-only scene contracts

Do not place gameplay logic here.

#### B. `*Signals` or `*EventBindings`

Use for:
1. connecting/disconnecting `EventBus`, autoload, and feature signals
2. translating external signals into local orchestrator callbacks

#### C. `*Flow`

Use for multi-step sequences and feature workflows.

Examples:
1. reward open/close flow
2. prophecy -> encounter flow
3. hire/upgrade/build flows
4. post-wave sequencing

#### D. `*State`

Use for:
1. local feature state snapshots
2. validation of state transitions
3. derived local flags

State modules should not touch UI directly unless the feature is purely UI-local.

#### E. `*Service`

Use for pure or mostly pure domain behavior.

Examples:
1. spawn planning
2. reward aggregation
3. production math
4. encounter resolution
5. pattern classification

#### F. `*Presenter` / `*UIBuilder` / `*Tooltip*`

Use for display formatting and UI payload building.

These modules can know UI-facing text/icons/layout payloads, but should not own gameplay progression.

#### G. `*Query` and `*Mutator`

Use where the domain is data-heavy.

`Query`:
1. read-only lookups
2. derived values
3. filtering/search

`Mutator`:
1. centralized writes
2. invariant-preserving updates
3. normalized state mutation

#### H. `*Registry` / `*Catalog` / `*Resolver`

Use for static or semi-static data and canonical lookup.

Examples:
1. hero scene resolution
2. spell config path resolution
3. reward presentation lookup
4. building config lookup

#### I. `*Adapter`

Use when one subsystem needs a narrow bridge into another subsystem or autoload.

Examples:
1. runtime facade over `HeroCore`
2. save bridge
3. UI bridge to reward menus

## Target structure by subsystem

### 1. Runtime gameplay scene

#### Target root orchestrator
1. `scripts/game/GameScene.gd`

#### Target role
1. runtime composition root only
2. owns scene references, startup order, and cross-system sequencing
3. delegates battle runtime responsibilities to feature modules

#### Canonical child modules
1. `GameSceneBootstrap`
2. `GameSceneSignals`
3. `GameScenePauseState`
4. `GameSceneWaves`
5. `GameSceneHeroes`
6. `GameSceneStages`
7. `GameSceneSpells`
8. `GameSceneRewardMenus`
9. `GameScenePendingRewards`
10. `GameSceneEncounterFlow`
11. `GameSceneWaveFlow`
12. `GameSceneBossSpawn`
13. `GameSceneBuildingDrag`
14. `GameSceneSlotHover`

#### Target refinement
Each of these modules should itself follow the same pattern when needed:

1. orchestrator-like feature module at the first layer
2. internal `modules/` helpers for state/service/flow work

`GameSceneWaves.gd` is the clearest example of the target style for deeper decomposition.

### 2. HUD / runtime UI root

#### Target root orchestrator
1. `scripts/ui/hud/MainUI.gd`

#### Target role
1. compose HUD surfaces
2. bind top-level UI events
3. delegate concrete UI logic to specialized HUD modules

#### Canonical mini-modules
1. `MainUITooltips`
2. `MainUITownOverlays`
3. `MainUIHeroHire`
4. `MainUITroopBonus`
5. future `MainUIResources`
6. future `MainUISettingsEntry`
7. future `MainUIPopupRouter`

#### Rule
No gameplay math, registry crawling, or long inventory/building/business rules should live in `MainUI.gd`.

### 3. Map slot runtime

#### Target root orchestrator
1. `scripts/map/MapSlot.gd`

#### Target role
1. slot composition root
2. UI node ownership
3. bridge between building runtime, special handlers, visuals, and player interaction

#### Existing target-aligned split
`MapSlot.gd` is already close to the desired model.

#### Follow-up target cleanup
1. reduce direct autoload lookups by routing through adapters/facades
2. keep slot-specific presentation in UI/presenter helpers
3. isolate special-building interoperability behind narrower contracts
4. keep per-tick routing out of general-purpose modules

### 4. Reward / prophecy / encounter stack

#### Target feature roots
1. `WaveRewardMenu.gd`
2. `ProphecyMenu.gd`
3. `EncounterMenu.gd`
4. `GameSceneRewardMenus.gd` as the runtime UI orchestrator between them

#### Target architecture
1. menu root = UI orchestrator
2. menu state = local selection state and validity rules
3. menu option generation = service layer
4. card/payload formatting = presenter/ui-builder layer
5. runtime opening/closing order = `GameSceneRewardMenus` + flow modules

#### Canonical mini-modules
1. `*MenuState`
2. `*OptionGenerator`
3. `*Cards`
4. `*UIBuilder`
5. `*Tooltip*`
6. `*Validation*` where necessary

### 5. Autoload game facades

#### Target roots
1. `HeroCore`
2. `TownCore`
3. `ArtifactCore`
4. `EconomyCore`
5. `ResourceCore`
6. `PopulationCore`
7. `BuildingUpgradeCore`
8. `SaveCore`
9. `KingSpellState`

#### Required rule
Every autoload should be one of only two things:

1. a thin public facade over internal modules
2. a very small infrastructure singleton with one narrow purpose

#### Required sub-shape for complex autoloads
`Autoload Facade -> Queries / Mutators / State / Flows / Persistence helpers`

#### Special note
Autoloads must not discover scene-tree runtime state ad hoc unless that is explicitly their job as an infrastructure bridge. If runtime scene access is required, prefer one of:

1. injected adapter
2. scene-owned registration
3. explicit runtime bridge service

### 6. Building systems

#### Target roots
1. `BuildingRegistry` for config/catalog ownership
2. `TownCore` for town-facing APIs
3. `MapSlot` for slot-local building runtime
4. `core/buildings/special/*` for building-specific runtime behavior

#### Required separation
1. config/catalog data stays out of slot scripts
2. slot-local visuals stay out of special building handlers
3. special building rules stay out of generic town facades
4. upgrade availability logic should not depend on deep scene crawling when a runtime registry/adapter can provide the same data explicitly

### 7. Hero and mob runtime

#### Target split
1. `HeroCore` = public facade + orchestration
2. `scripts/hero/*` = scene resolution, on-field adapters, state-machine helpers
3. `scripts/hero/states/*` = pure state behavior
4. `scripts/mob/Mob.gd` = entity orchestrator for enemy runtime
5. `scripts/mob/states/*` = pure state behavior

#### Rule
Entity root scripts should own node wiring and state transitions, but concrete attacks, status effects, targeting heuristics, and special ability logic should move into state/helpers/components instead of growing in the root node script.

### 8. Shared services and registries

These should remain globally reusable and not be duplicated in feature roots:

1. path resolution
2. reward presentation lookup
3. scene registries
4. marker/position services
5. shared config loading

## Repo-wide boundary rules

### 1. Dependency direction

Preferred dependency direction:

1. scene root/orchestrator -> feature modules
2. feature modules -> services/state/registries/adapters
3. services -> pure data/resources/helpers

Avoid reverse dependency where low-level modules need to know the full orchestrator.

### 2. Scene access rule

Only orchestrators, bootstraps, or explicit adapters should perform broad node discovery.

Avoid:
1. random business modules calling `get_tree().current_scene`
2. deep `get_parent()` climbing
3. feature logic searching unrelated scene branches directly

### 3. UI rule

UI roots may own:
1. node references
2. local animations/tweens/open-close transitions
3. input and selection routing

UI roots should delegate:
1. reward generation
2. balance math
3. cross-system side effects
4. save/load logic

### 4. Persistence rule

Save/load should be centralized behind persistence helpers or save facades, not spread across random gameplay modules.

### 5. Compatibility rule

Where public APIs are already widely used, keep a thin compatibility surface on the orchestrator/facade and move internals behind it instead of breaking all call sites at once.

## Naming standard

For consistency, prefer these names across the repo:

1. `FeatureRoot.gd` or existing canonical root name
2. `FeatureBootstrap.gd`
3. `FeatureSignals.gd`
4. `FeatureState.gd`
5. `FeatureFlow.gd`
6. `FeatureService.gd`
7. `FeaturePresenter.gd` or `FeatureUIBuilder.gd`
8. `FeatureQuery.gd`
9. `FeatureMutator.gd`
10. `FeatureAdapter.gd`
11. `FeatureRegistry.gd` / `FeatureCatalog.gd`

Avoid inventing a new suffix for every subsystem unless the role is genuinely different.

## Repo inventory snapshot for migration design

This snapshot exists so the migration plan stays grounded in the current repo, not in an imagined clean-room architecture.

### 1. Current autoload layer

Current project autoloads include:

1. infrastructure/runtime globals: `TickManager`, `EventBus`, `SaveCore`, `AudioManager`, `DamagePopupPool`, `DayNightCycle`
2. economy/state facades: `EconomyCore`, `ResourceCore`, `PopulationCore`, `TownCore`, `ForgeCore`, `CastleCore`, `MineCore`, `GazeCore`, `MoraleSystem`
3. gameplay/state facades: `HeroCore`, `BattleCore`, `SkillCore`, `SpellCore`, `ArtifactCore`, `KingSpellState`, `CharacterCreationState`, `GameStartSettings`, `GameSettings`
4. registries/services: `BuildingRegistry`, `MapMarkerService`, `SealRegistry`, `StageCore`, `TroopBonusCore`, `BuildingUpgradeCore`

### 2. Current module-rich zones

These areas already demonstrate the target style and should be treated as reference implementations:

1. `scripts/game_scene/modules/`
2. `scripts/ui/prophecy/modules/`
3. `scripts/map_slot/`
4. `core/hero/`
5. `core/town/`
6. `core/artifacts/`

### 3. Current high-value orchestrator roots

These are the most important roots to normalize and protect during migration:

1. `scripts/game/GameScene.gd`
2. `scripts/ui/hud/MainUI.gd`
3. `scripts/map/MapSlot.gd`
4. `scripts/ui/rewards/WaveRewardMenu.gd`
5. `scripts/ui/prophecy/ProphecyMenu.gd`
6. `scripts/ui/encounters/EncounterMenu.gd`
7. `core/hero_core.gd`
8. `core/town_core.gd`
9. `core/artifacts/artifact_core.gd`
10. `core/building_upgrade_core.gd`
11. `core/save_core.gd`

### 4. Current mixed-risk areas

These are likely to require architectural cleanup, compatibility shims, or dedicated adapters during migration:

1. autoloads that inspect scene state directly
2. runtime roots that still blend orchestration with business logic
3. UI roots that still combine input, data shaping, and cross-system side effects
4. systems that rely on deep scene-tree lookup instead of explicit ownership contracts

## Master migration doctrine

This section defines how every future implementation batch must be executed.

### 1. Migration unit of work

The canonical migration unit is a **batch**, not a whole subsystem rewrite.

One batch should change exactly one of the following:

1. one root orchestrator contract
2. one subsystem slice inside a root
3. one cross-system bridge
4. one autoload facade with its immediate helpers
5. one shared registry/service boundary

### 2. Batch size rule

One batch should be small enough that all of the following are true:

1. affected runtime behavior is easy to identify
2. rollback is possible without reverting unrelated work
3. public API compatibility can be checked by inspection
4. docs can be updated in the same change
5. the batch can be verified with a focused test/runtime checklist

### 3. Mandatory batch checklist

Every implementation batch in the future should follow this order:

1. define the exact responsibility being moved
2. define which script remains the orchestrator
3. define which new mini-module(s) will own the behavior
4. preserve outward behavior first, improve internals second
5. add/adjust regression coverage
6. update `docs/PROJECT_NAVIGATOR.md`
7. update `docs/ARCHITECTURE.md`
8. update focused subsystem docs if they exist

### 4. Non-negotiable migration rules

During future implementation, do not allow batches that:

1. rename files and move logic and change behavior all at once unless the behavior delta is tiny and fully verified
2. extract modules without clearly documenting new ownership
3. make low-level modules depend on full scene roots
4. increase scene-tree guessing as a temporary shortcut
5. remove compatibility APIs before downstream callers are migrated

## Detailed phase and batch program

The following is the recommended full-program migration order for the whole repo.

---

## Phase 0 - Freeze the architecture contract

### Objective

Establish one canonical migration language so future refactors do not invent different module taxonomies per subsystem.

### Why this phase is first

If the naming, ownership rules, and batch discipline are not frozen first, later subsystem refactors will drift and create a second generation of inconsistency.

### Batches

#### Batch 0A - Canonical module taxonomy freeze

Scope:
1. freeze the suffix vocabulary (`Bootstrap`, `Signals`, `Flow`, `State`, `Service`, `Presenter`, `Query`, `Mutator`, `Adapter`, `Registry`, `Catalog`)
2. map current local naming variants to that taxonomy

Outputs:
1. naming matrix in architecture docs
2. explicit rule for when `Flow` vs `Service` vs `State` is allowed

Done when:
1. a future engineer can classify any new module without guessing

#### Batch 0B - Root ownership ledger

Scope:
1. list every major root orchestrator/autoload
2. define what each root is allowed to own and not own

Outputs:
1. root ownership table
2. no-logic-in-root exceptions list if unavoidable

Done when:
1. each major root has a written responsibility boundary

#### Batch 0C - Dependency-direction rule freeze

Scope:
1. formalize what may depend on what
2. mark scene lookup as privileged behavior of orchestrators/bootstrap/adapters only

Outputs:
1. dependency rule section in docs
2. anti-pattern examples from current repo

Done when:
1. future batches can reject bad dependency direction early

### Exit criteria for Phase 0

1. naming standard frozen
2. orchestrator contract frozen
3. dependency direction frozen
4. doc update policy attached to every later batch

---

## Phase 1 - Normalize top-level runtime roots

### Objective

Stabilize the main runtime composition shells before touching deeper internals.

### Why this phase precedes autoload cleanup

The runtime roots define where bridges into autoloads and UI live. If these roots are not stabilized first, later autoload cleanup will target moving call sites.

### Phase targets

1. `GameScene.gd`
2. `MainUI.gd`
3. primary reward/menu roots that behave as runtime surfaces

### Batches

#### Batch 1A - `GameScene.gd` shell audit and role freeze

Scope:
1. classify every remaining responsibility inside `GameScene.gd`
2. mark which responsibilities stay in the shell and which must always be delegated

Planned outcomes:
1. `GameScene.gd` becomes explicitly the composition root and compatibility facade
2. no new business logic should ever be added directly there

Key files to review during implementation phase:
1. `scripts/game/GameScene.gd`
2. `scripts/game_scene/*.gd`

Done when:
1. all remaining direct logic in `GameScene.gd` is either intentionally root-owned or queued for extraction by later batches

#### Batch 1B - `MainUI.gd` shell normalization

Scope:
1. classify HUD responsibilities into resource display, overlays, hire flow, popup routing, settings entry, tooltips
2. define which pieces become mandatory mini-modules

Planned outcomes:
1. `MainUI.gd` is reduced to composition and event routing
2. future HUD additions attach through focused modules instead of growing the root

Done when:
1. any new HUD feature has an obvious owner module category

#### Batch 1C - Runtime menu root standardization

Scope:
1. define the canonical shape for menu roots: `UI root -> local state -> generator/service -> presenter/builders -> runtime open/close flow`
2. apply that as the standard for wave rewards, prophecy, encounters, and similar surfaces

Done when:
1. all future menu refactors share the same internal decomposition pattern

### Exit criteria for Phase 1

1. root-shell rules for `GameScene` and `MainUI` are explicit
2. runtime menu roots have one canonical architecture shape
3. new root growth can be blocked by policy instead of taste

---

## Phase 2 - Standardize the reward / prophecy / encounter family

### Objective

Use the reward-family stack as the first full demonstration of the target architecture from top UI root down to generators and runtime orchestration.

### Why this phase is early

This stack already has partial modularization and is a clean place to standardize menu architecture without immediately touching all core autoloads.

### Phase targets

1. `WaveRewardMenu`
2. `ProphecyMenu`
3. `EncounterMenu`
4. `GameSceneRewardMenus`
5. surrounding builders/generators/state modules

### Batches

#### Batch 2A - Menu root contract freeze

Define per-menu root boundaries:

1. input handling
2. open/close state transitions
3. signal emission
4. local node ownership

Move out or mark for move:

1. reward generation
2. option shaping
3. tooltip payload generation
4. cross-system side effects

#### Batch 2B - State normalization

For each menu family, define where selection state lives and what is considered local UI state vs gameplay decision state.

Expected target artifacts:

1. `*MenuState`
2. validation helpers if rules are non-trivial

#### Batch 2C - Generator/service normalization

Separate:

1. option generation
2. reward aggregation
3. pattern classification
4. encounter effect resolution preview building

Expected target artifacts:

1. `*OptionGenerator`
2. `*Service`
3. `*Validation*` or `*Rules*` only where needed

#### Batch 2D - Presentation normalization

Separate:

1. card row building
2. tooltip payload building
3. icon/name mapping
4. text formatting

Expected target artifacts:

1. `*Cards`
2. `*UIBuilder`
3. `*TooltipBuilder`
4. shared presentation registries where cross-menu reuse exists

#### Batch 2E - Runtime menu router normalization

Target:
1. `GameSceneRewardMenus.gd`

Scope:
1. own only runtime open/close ordering and menu availability checks
2. route into menus through narrow APIs
3. avoid embedding menu-specific business logic

### Exit criteria for Phase 2

1. reward-family menus all follow the same internal decomposition pattern
2. runtime menu routing is separate from menu content logic
3. this family becomes the canonical template for future menu systems

---

## Phase 3 - Normalize autoload facades by risk tier

### Objective

Convert all complex autoloads into clearly limited facades over internal modules, without breaking their public role as global access points.

### Risk-tier ordering

Do not migrate autoloads in random order. Use this sequence.

#### Tier A - Already close to target shape

Examples:
1. `HeroCore`
2. `TownCore`
3. `ArtifactCore`

Work here is mostly:
1. naming consistency
2. public API cleanup
3. extracting any leftover mixed logic

#### Tier B - Mid-size facades with mixed infrastructure/domain behavior

Examples:
1. `SaveCore`
2. `KingSpellState`
3. `ForgeCore`
4. `SkillCore`

Work here is mostly:
1. state vs flow separation
2. persistence isolation
3. explicit adapters for runtime interactions

#### Tier C - Small but architecturally dangerous due to scene/runtime coupling

Examples:
1. `BuildingUpgradeCore`
2. any global that inspects current scene or map layout directly

Work here is mostly:
1. remove implicit scene-tree crawling
2. replace with runtime registration or adapters

### Batches

#### Batch 3A - Facade pattern freeze

For every complex autoload define the allowed internal shape:

1. public API facade
2. query/mutator/state/services/flows
3. save integration helper if needed

#### Batch 3B - Tier A cleanup

Normalize the autoloads already closest to target shape.

Goal:
1. produce “reference facades” for the rest of the repo

#### Batch 3C - Tier B cleanup

Normalize mid-size facades that mix domain and infrastructure concerns.

Goal:
1. pull serialization, runtime glue, and domain rules into predictable submodules

#### Batch 3D - Tier C de-risking

Normalize scene-crawling globals last in this phase because they require explicit runtime bridge design.

Goal:
1. remove implicit scene ownership assumptions from global singletons

### Exit criteria for Phase 3

1. every complex autoload is obviously a facade, not a god-object
2. scene-tree knowledge is no longer randomly distributed across autoloads
3. facade internals use recognizable module roles

---

## Phase 4 - Normalize runtime-to-autoload bridges

### Objective

Make cross-boundary access explicit so runtime roots and autoload facades stop reaching into each other in ad hoc ways.

### Why this phase exists separately

Many architecture failures do not come from the root or the autoload individually, but from how they are glued together.

### Bridge patterns to prefer

1. root-owned dependency injection
2. runtime registration into a known service/facade
3. narrow adapter modules
4. signal-driven handoff

### Bridge patterns to eliminate

1. `get_tree().current_scene` in domain logic
2. autoload scanning scene nodes on demand for normal business queries
3. modules that know both a global singleton and deep scene internals

### Batches

#### Batch 4A - Map/building runtime bridge cleanup

Focus:
1. map slots
2. building upgrade queries
3. town/building runtime ownership boundaries

#### Batch 4B - Reward/runtime bridge cleanup

Focus:
1. reward queue
2. prophecy/encounter handoff
3. menu availability and pending actions

#### Batch 4C - Hero/runtime bridge cleanup

Focus:
1. hero battle presence
2. battlefield sync
3. hero facade vs on-field runtime adapters

### Exit criteria for Phase 4

1. runtime roots and autoloads talk through declared contracts
2. scene crawling is reduced to orchestrators, bootstraps, and explicit adapters

---

## Phase 5 - Normalize the building stack as one architecture family

### Objective

Bring all building-related code under one coherent split between registry/config, town facade, slot runtime, special building handlers, and building UI.

### Why this phase is isolated

The building system spans static data, slot runtime, UI popups, special handlers, progression logic, and upgrades. It is wide enough that it needs its own focused migration phase.

### Target family members

1. `BuildingRegistry`
2. `TownCore`
3. `MapSlot`
4. `core/buildings/special/*`
5. building-related UI surfaces
6. `BuildingUpgradeCore`

### Batches

#### Batch 5A - Building ownership matrix

Define exactly where each concern belongs:

1. config lookup
2. recipe cost and scaling
3. slot-local visuals and interaction
4. special building runtime loops
5. upgrade unlock/application
6. tooltip/detail presentation

#### Batch 5B - `MapSlot` family cleanup

Goal:
1. keep `MapSlot.gd` as slot orchestrator only
2. continue pushing behavior into `scripts/map_slot/*`
3. ensure each map slot helper has a narrow role

#### Batch 5C - Special building contract normalization

Goal:
1. every special building runtime handler follows a common contract
2. slot orchestrator can interact with them uniformly

#### Batch 5D - Upgrade path cleanup

Goal:
1. remove deep runtime scene coupling from upgrade logic
2. centralize upgrade state and slot/building association behind explicit contracts

#### Batch 5E - Building UI cleanup

Goal:
1. move display-only logic into presenter/builders
2. keep build/research/market/special UIs consistent with the general menu architecture rules

### Exit criteria for Phase 5

1. building data, slot runtime, and special logic are clearly separated
2. no building feature needs to guess ownership at implementation time

---

## Phase 6 - Normalize hero and mob runtime roots

### Objective

Ensure combat entity roots remain orchestration shells over state machines, helpers, and reusable components rather than gradually growing feature blobs.

### Target family members

1. `HeroCore`
2. `scripts/hero/*`
3. `scripts/hero/states/*`
4. `scripts/mob/Mob.gd`
5. `scripts/mob/states/*`
6. supporting runtime adapters and resolvers

### Batches

#### Batch 6A - Hero facade and battlefield boundary audit

Goal:
1. separate hero global state ownership from on-field runtime behavior
2. identify everything that should stay in `HeroCore` versus move to adapters/components

#### Batch 6B - Hero root cleanup

Goal:
1. keep `HeroOnField`-style runtime roots focused on wiring, node ownership, and state transitions
2. move concrete combat/special cases into helpers/states/components

#### Batch 6C - Mob root cleanup

Goal:
1. apply the same shell pattern to `Mob.gd` and mob-specific roots
2. prevent special enemy logic from bloating the base runtime node

#### Batch 6D - Shared combat helper normalization

Goal:
1. centralize reusable targeting, damage, status, and classification helpers where appropriate
2. avoid duplicate local mini-frameworks in hero and mob trees

### Exit criteria for Phase 6

1. hero and mob roots are orchestration-heavy, not logic-heavy
2. state machine and component boundaries are clearer than before

---

## Phase 7 - Normalize persistence, save integration, and long-tail globals

### Objective

Clean up infrastructure ownership so serialization, runtime registration, and global services do not silently re-couple the project.

### Target family members

1. `SaveCore`
2. save helpers / registration flow
3. infrastructure autoloads with registration roles
4. long-tail globals that are currently small but strategically important

### Batches

#### Batch 7A - Save target contract cleanup

Goal:
1. define which systems self-register, auto-register, or expose save adapters
2. reduce magical persistence coupling where possible

#### Batch 7B - Infrastructure singleton classification

Classify each remaining global as one of:

1. narrow infrastructure singleton
2. registry/resolver
3. domain facade
4. runtime bridge

Goal:
1. eliminate ambiguous “misc global manager” patterns

#### Batch 7C - Long-tail cleanup pass

Goal:
1. normalize smaller globals and leftover utility roots so they do not remain architectural outliers

### Exit criteria for Phase 7

1. persistence and registration are explicit enough to survive future refactors
2. no small global remains a hidden architecture loophole

---

## Phase 8 - Repo convergence and debt cleanup

### Objective

Finalize convergence after the major subsystems are migrated so the repo ends in one consistent style rather than a mostly-complete transition state.

### Batches

#### Batch 8A - Naming convergence

Goal:
1. rename or alias inconsistent module names where needed
2. remove one-off suffixes that duplicate canonical roles

#### Batch 8B - Leftover scene-access cleanup

Goal:
1. search for remaining deep scene lookup anti-patterns
2. replace them with adapters, signals, or injected dependencies

#### Batch 8C - Root script final slimming pass

Goal:
1. review major roots one last time
2. ensure new logic has not leaked back into them during migration

#### Batch 8D - Documentation convergence

Goal:
1. bring `PROJECT_NAVIGATOR`, `ARCHITECTURE`, and focused docs into exact agreement with the codebase

### Exit criteria for Phase 8

1. module naming is coherent repo-wide
2. major architectural anti-patterns are not just reduced but intentionally closed
3. documentation matches actual ownership boundaries

## Batch execution template for future implementation work

Every future implementation batch should be planned using the following mini-template.

### 1. Batch definition

1. batch name
2. subsystem owner
3. orchestrator that remains
4. logic being extracted/moved
5. new or renamed mini-modules

### 2. Pre-batch invariants

1. what behavior must not change
2. which public APIs must remain callable
3. which save/load assumptions must survive
4. which UI contracts must remain intact

### 3. Verification set

1. direct subsystem tests
2. runtime smoke path
3. compatibility call sites
4. save/load or persistence checks if applicable
5. documentation updates

### 4. Rollback strategy

1. what files belong only to this batch
2. what compatibility shim allows safe rollback
3. what should not be mixed into the same commit

## Cross-phase dependency order

The critical dependency order is:

1. taxonomy and ownership freeze
2. root-shell normalization
3. reward/menu family standardization
4. autoload facade normalization
5. runtime/autoload bridge cleanup
6. building family normalization
7. hero/mob family normalization
8. persistence/global cleanup
9. repo convergence and doc freeze

Do not swap this order casually.

### Why this order matters

1. menu roots are easier to standardize than the full building stack and create a repeatable pattern early
2. autoload cleanup before bridge cleanup risks moving targets if runtime roots are still unstable
3. building and hero/mob families are broad and should be attacked only after naming and bridge rules are proven elsewhere
4. convergence work should happen last so it reflects the final structure, not a mid-migration snapshot

## Stop conditions and escalation rules

Future implementation should stop and re-plan if any batch reveals one of the following:

1. a root script is hiding two or more independent subsystems that need separate orchestrators
2. an autoload cannot be made thin without first redesigning its runtime ownership contract
3. save/load behavior depends on hidden side effects not captured in the current public API
4. a subsystem needs a new registry or adapter type not covered by the canonical taxonomy
5. scene-first composition conflicts with an assumed code-built runtime hierarchy

When any of these happens, the correct response is not to push through blindly; it is to split the batch and update the architecture plan.

## Final recommended implementation campaign order

If this plan is approved and later converted into an execution roadmap, the highest-value campaign order is:

1. Phase 0 - freeze architecture language and ownership
2. Phase 1 - stabilize `GameScene`, `MainUI`, and root menu contracts
3. Phase 2 - finish the reward/prophecy/encounter family as the first gold-standard subsystem
4. Phase 3 - normalize autoload facades by risk tier
5. Phase 4 - remove hidden runtime/autoload coupling
6. Phase 5 - normalize the full building stack
7. Phase 6 - normalize hero and mob runtime roots
8. Phase 7 - clean persistence and long-tail globals
9. Phase 8 - converge naming, docs, and remaining debt

## Success criteria

The architecture should be considered aligned when the following are true:

1. every major subsystem has one clearly named root orchestrator/facade
2. business logic is no longer concentrated in root scripts
3. module roles are recognizable by name across folders
4. cross-feature communication goes through signals, facades, or adapters instead of scene-tree guessing
5. `.tscn` remains the owner of static structure and authored visuals
6. docs describe the same boundaries that the code actually uses

## Immediate planning output for future implementation phase

When implementation starts, each subsystem refactor should produce:

1. one subsystem target map
2. one list of modules to extract/rename/merge
3. one compatibility plan for public API preservation
4. one verification set for runtime behavior, save behavior, and UI behavior
5. matching updates to `docs/PROJECT_NAVIGATOR.md` and `docs/ARCHITECTURE.md`

## First recommended subsystem candidates

If you want to start applying this architecture soon, the best candidates are:

1. `GameScene` runtime shell and remaining cross-system glue
2. `BuildingUpgradeCore` and other autoloads that still pull scene state directly
3. reward/prophecy/menu stack to standardize `State + Generator + Presenter + RuntimeFlow`
4. `MainUI` resource/popup/settings edges
5. remaining hero/mob roots that still mix orchestration with concrete gameplay logic
