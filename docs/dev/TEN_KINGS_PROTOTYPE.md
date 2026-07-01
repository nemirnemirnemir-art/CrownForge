# Ten Kings Prototype

Last updated: 04.04.2026

This document describes the standalone 10 Kings prototype located under `res://scenes/dev/`.

## Purpose

1. Provide an isolated Player vs AI card-battle sandbox for the King of Nothing deck.
2. Keep all prototype runtime code fully separate from the main `GameScene` runtime.
3. Support rapid iteration on board, year, offer, and battle rules before any future integration work.

## Entry points

1. Scene: `res://scenes/dev/TenKingsPrototype.tscn`
2. Root orchestrator: `res://scripts/dev/ten_kings/TenKingsPrototype.gd`
3. Battle runtime owner: `res://scripts/dev/ten_kings/TenKingsBattleManager.gd`
4. Match-flow owner: `res://scripts/dev/ten_kings/TenKingsTurnFlow.gd`

## Isolation contract

1. The prototype does **not** use `GameScene`, `HeroOnField`, `HeroCore`, `GameSceneWaves`, or any main-run combat/runtime modules.
2. Shared usage is limited to engine primitives and reused visual assets only.
3. Runtime-adopted prototype assets live under `res://assets/dev/ten_kings/`; `res://assets/takefromthis/` remains intake-only.
4. The root scene still joins the `game_scene` group for lightweight compatibility with helper lookups used by some debug/runtime patterns.

## Script responsibilities

### Data and board state

1. `res://scripts/dev/ten_kings/TenKingsCardLibrary.gd` - authoritative card catalog, per-level stats, 27-card deck generation, and card classification helpers (`spawns_in_arena()`, `is_stationary_combat()`, `is_support_only()`).
2. `res://scripts/dev/ten_kings/TenKingsBoardState.gd` - 5x5 board ownership, slot locking, adjacency, upgrades, Tome and Steel Coat application, and unlock progression.
3. `res://scripts/dev/ten_kings/TenKingsPlayerState.gd` - per-player hand/deck/castle HP/loss streak ownership.
4. `res://scripts/dev/ten_kings/TenKingsYearEffects.gd` - Farm and Blacksmith yearly effect application.

### Match flow and AI

1. `res://scripts/dev/ten_kings/TenKingsTurnFlow.gd` - high-level phase flow: castle placement -> prep -> year effects -> battle -> offer -> unlock -> next year.
2. `res://scripts/dev/ten_kings/TenKingsAiController.gd` - simple placement, upgrade, Steel Coat, and offer heuristics for the AI player.

### Battle runtime

1. `res://scripts/dev/ten_kings/TenKingsUnit.gd` - aggregated arena unit for troop stacks, including state-driven visuals and attack event emission.
2. `res://scripts/dev/ten_kings/TenKingsBattleManager.gd` - arena spawning (troops-only), fixed structure tracking, anchor-based formation placement, targeting, projectile feedback, siege/chase resolution, and battle-end reporting.
3. `res://scripts/dev/ten_kings/TenKingsBattleActor.gd` - shared prototype-local troop animation controller used by dev-only actor scenes. Uses state-driven lifecycle with pending state support.
4. `res://scripts/dev/ten_kings/TenKingsAttackEffect.gd` - short-lived projectile/tracer effect for ranged, tower, and castle attacks.

### UI helpers

1. `res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd` - board-slot display, drop target, and hover signal emitter (visual-only, no inline text).
2. `res://scripts/dev/ten_kings/TenKingsHandCardUI.gd` - draggable hand-card display.
3. `res://scripts/dev/ten_kings/TenKingsBoardTooltip.gd` - dedicated hover tooltip for board slot details.
4. `res://scripts/dev/ten_kings/TenKingsPrototype.gd` - scene-level coordinator that wires player input, UI refresh, offers, tooltip handling, arena anchors, and battle start/end handoff.

### Prototype-local visuals

1. `res://scenes/dev/ten_kings/actors/TenKingsSoldierActor.tscn` - dev-only animated soldier actor.
2. `res://scenes/dev/ten_kings/actors/TenKingsArcherActor.tscn` - dev-only animated archer actor.
3. `res://scenes/dev/ten_kings/actors/TenKingsPaladinActor.tscn` - dev-only animated paladin actor.
4. `res://scenes/dev/ten_kings/TenKingsBoardTooltip.tscn` - hover tooltip panel for board slot details.

## Layout and arena architecture

### Board layout

1. Board slots are 80x80 pixels.
2. Player board panel spans x=12 to x=430 (left side).
3. AI board panel spans x=610 to x=1010 (right side).
4. A central battle corridor of 180px width exists between the two board panels (x=430 to x=610).

### Board slot display

1. Board cells are visual-only and do not render inline detail text (level, units, damage bonus, etc.).
2. Slot details are presented through a dedicated hover tooltip (`TenKingsBoardTooltip`).
3. Hover signals (`slot_hover_started`, `slot_hover_ended`) connect board slots to the tooltip system.
4. Troop slots show representative pack icon grids; building slots show a single icon.

### Arena anchors

The battle arena uses explicit anchor nodes under `BattleLayer/ArenaAnchors` for formation and siege positioning:

| Anchor | Position | Purpose |
|--------|----------|---------|
| `PlayerFrontAnchor` | (-90, 0) | Player melee formation line |
| `PlayerRangedAnchor` | (-140, 0) | Player ranged formation line |
| `PlayerBackAnchor` | (-190, 0) | Player building formation line |
| `AiFrontAnchor` | (90, 0) | AI melee formation line |
| `AiRangedAnchor` | (140, 0) | AI ranged formation line |
| `AiBackAnchor` | (190, 0) | AI building formation line |
| `PlayerCastleContactAnchor` | (-220, 0) | Player castle siege contact zone |
| `AiCastleContactAnchor` | (220, 0) | AI castle siege contact zone |

Battle manager methods:
- `get_formation_x_for_unit_type(side, is_ranged, is_building)` - returns anchor-based X position for formation
- `get_castle_contact_position(side)` - returns castle contact anchor for siege resolution
- `set_arena_anchors(anchors)` - accepts anchor dictionary from prototype orchestrator

## Current flow notes

1. The prototype normalizes the opening hand so each side can always place a Castle and has at least one troop during the mandatory opening phase.
2. Farm and Blacksmith stay on the board and do not spawn as combat units.
3. Board slots are visual-only; slot details appear in a hover tooltip instead of inline text.
4. Troop battle units use prototype-local animated actor scenes; buildings remain on simple icon visuals.
5. Battles deploy from board-slot origins into anchor-based arena formation before combat starts.
6. Archer, Scout Tower, and Castle attacks spawn lightweight tracer/projectile feedback during combat.
7. Field victory is locked first; surviving winning troops then chase toward castle-contact anchors during a short siege-resolution phase before the battle result is emitted.
8. Castle damage after a lost battle is applied by the turn-flow layer, not by direct arena combat damage.
9. The End Turn button is disabled until the player places at least one troop on the board, ensuring battles always have troops to spawn.

## Battle model architecture

The battle system uses a **troops-only arena** model with **fixed structure fire support**:

### Card classification

Cards are classified into three mutually exclusive categories:

| Category | Cards | Arena behavior |
|----------|-------|----------------|
| **Troops** (spawns in arena) | Soldier, Archer, Paladin | Deploy into arena, move, fight with walk/attack animations |
| **Stationary combat** (fixed structures) | Castle, Scout Tower | Stay at board positions, shoot into arena from fixed locations |
| **Support-only** | Farm, Blacksmith, Wildcard, Steel Coat | Never participate in combat runtime |

Classification helpers in `TenKingsCardLibrary.gd`:
- `spawns_in_arena(card_id)` - returns true for troops only
- `is_stationary_combat(card_id)` - returns true for Castle and Scout Tower
- `is_support_only(card_id)` - returns true for Farm, Blacksmith, Wildcard, Steel Coat

### Arena unit tracking

Battle manager tracks units in separate collections:

| Collection | Content | Processing |
|------------|---------|------------|
| `_player_units` / `_ai_units` | Troop stacks (Soldier, Archer, Paladin) | Move, target, attack in `_process()` |
| `_player_fixed_structures` / `_ai_fixed_structures` | Castle, Scout Tower references | Fire at enemies from board positions in `_process()` |

### Fixed structure fire support

Castle and Scout Tower:
1. Do NOT spawn actors in the arena
2. Stay in their board slot positions
3. Shoot projectiles at enemy troops in the arena
4. Use `get_fixed_shooter_origin(slot_coord)` to determine projectile origin
5. Attack logic runs in `_process_fixed_structure_attacks()`

### Siege resolution

When all enemy troops are eliminated:
1. Surviving winning troops chase toward the enemy's `CastleContactAnchor`
2. Siege target is the **contact anchor position**, not the castle unit position
3. `get_castle_contact_position(side)` returns the anchor coordinates
4. Castle damage is applied by turn-flow layer after battle ends

## Known limitations

1. Battle formations, targeting, projectile timing, and siege logic are still prototype-grade and intentionally simplified.
2. Offer UI is text-button based rather than fully card-rendered.
3. The scene is a development sandbox only and is not connected to the main run/start flow yet.
4. Some legacy phase2 spec tests (`test_ten_kings_phase2_battle_deploy`, `test_ten_kings_phase2_board_presentation`, `test_ten_kings_phase2_siege_resolution`) expect an older battle model and are currently failing - they need to be updated or removed.

## Test coverage

Contract tests for the current battle model:

| Test file | Coverage |
|-----------|----------|
| `test_ten_kings_battle_troops_only_spawn.gd` | Verifies only troops spawn in arena, castle/tower excluded |
| `test_ten_kings_fixed_structures_fire_support.gd` | Verifies castle/tower can attack without being arena units |
| `test_ten_kings_siege_uses_contact_anchor.gd` | Verifies siege uses contact anchors, not unit positions |
| `test_ten_kings_card_library.gd` | Verifies card classification helpers |
| `test_ten_kings_arena_anchor_contract.gd` | Verifies arena anchor wiring |
| `test_ten_kings_arena_layout_contract.gd` | Verifies board/corridor layout |
| `test_ten_kings_battle_lane_readability.gd` | Verifies formation positioning |
| `test_ten_kings_guaranteed_troop.gd` | Verifies troop guarantee in hand at setup and can_end_turn blocking |
