# Ten Kings Tooltip And Arena Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove inline text from Ten Kings board cells, move slot details into hover tooltips, restore a real central battle corridor, and align battle deployment/formation logic with the new layout.

**Architecture:** Keep `TenKingsPrototype.gd` as the scene orchestrator, move slot-detail presentation into a dedicated tooltip UI module, and make `TenKingsBattleManager.gd` consume explicit arena-anchor positions instead of relying on the current near-edge-to-edge board layout. Board UI and battle world-space remain intentionally separate: slots stay in UI-space, actors fight in `BattleLayer`, and battle-space gets a fixed center corridor.

**Tech Stack:** Godot 4.3, GDScript, `.tscn`-authored UI/layout, headless SceneTree tests under `scripts/dev/tests/`

---

### Task 1: Make board cells visual-only again

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Create: `scripts/dev/tests/test_ten_kings_board_slot_visual_only.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_ten_kings_board_slot_visual_only.gd` that verifies:
- occupied slots do not show `Lv.`, `xN`, `% dmg`, `Block`, or multiline text inside the slot
- troop slots still show representative pack icons
- building slots still show a single icon visual
- the slot exposes hover signals or a hover-ready contract without rendering details inline

Suggested checks:
- create a `TenKingsBoardSlotUI` instance
- call `setup(Vector2i(0, 0))`
- call `update_display(...)` with troop payload and verify `_pack_grid.visible == true`
- verify the label used for details is absent or empty after update

**Step 2: Run test to verify it fails**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_board_slot_visual_only.gd`

Expected: FAIL because `TenKingsBoardSlotUI.gd` still renders multiline level/detail text inside the cell.

**Step 3: Write minimal implementation**

- In `TenKingsBoardSlotUI.gd`:
  - remove visible inline details from the slot body
  - keep only visual state:
    - background color
    - troop pack preview
    - building icon
    - lock/empty state
    - drag highlight
  - add hover-oriented signals, for example:
    - `slot_hover_started(slot_pos: Vector2i)`
    - `slot_hover_ended(slot_pos: Vector2i)`
- In `TenKingsPrototype.gd`:
  - stop relying on slot-internal text as the only detail presentation path
  - preserve existing drag/drop behavior

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/dev/ten_kings/TenKingsBoardSlotUI.gd scripts/dev/ten_kings/TenKingsPrototype.gd scripts/dev/tests/test_ten_kings_board_slot_visual_only.gd
git commit -m "feat: make ten kings board slots visual only"
```

### Task 2: Add a dedicated hover tooltip for board details

**Files:**
- Create: `scenes/dev/ten_kings/TenKingsBoardTooltip.tscn`
- Create: `scripts/dev/ten_kings/TenKingsBoardTooltip.gd`
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Create: `scripts/dev/tests/test_ten_kings_board_tooltip_contract.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_ten_kings_board_tooltip_contract.gd` that verifies:
- the prototype scene has a dedicated tooltip node
- the tooltip starts hidden
- hover on an occupied slot shows the tooltip
- tooltip can be hidden on hover exit
- tooltip payload includes the correct details:
  - card display name
  - level
  - units for troops
  - smith bonus if present
  - steel coat stacks if present
  - castle HP if the slot contains castle

**Step 2: Run test to verify it fails**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_board_tooltip_contract.gd`

Expected: FAIL because no dedicated tooltip scene/controller exists yet.

**Step 3: Write minimal implementation**

- Create `TenKingsBoardTooltip.tscn` as a small `PanelContainer` with a layout like:
  - `VBoxContainer`
  - title label
  - body label(s)
- Create `TenKingsBoardTooltip.gd` with methods such as:
  - `show_for_slot(details: Dictionary, screen_pos: Vector2) -> void`
  - `hide_tooltip() -> void`
  - `_clamp_to_viewport()` helper
- Modify `TenKingsPrototype.tscn` to add the tooltip under the root UI layer
- Modify `TenKingsPrototype.gd` to:
  - connect board-slot hover signals
  - build detail payloads from `TenKingsPlayerState` + `TenKingsBoardState`
  - show the tooltip near the cursor without covering the slot

Suggested tooltip fields:
- title: `Paladin`, `Scout Tower`, `Castle`, etc.
- line 1: `Level 2`
- line 2: `Units: 6`
- line 3: `Smith bonus: +4%`
- line 4: `Steel Coat: 2`
- castle special line: `Castle HP: 100`

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add scenes/dev/ten_kings/TenKingsBoardTooltip.tscn scripts/dev/ten_kings/TenKingsBoardTooltip.gd scenes/dev/TenKingsPrototype.tscn scripts/dev/ten_kings/TenKingsPrototype.gd scripts/dev/tests/test_ten_kings_board_tooltip_contract.gd
git commit -m "feat: add ten kings board hover tooltip"
```

### Task 3: Rebuild the scene layout around a real central battle corridor

**Files:**
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`
- Create: `scripts/dev/tests/test_ten_kings_arena_layout_contract.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_ten_kings_arena_layout_contract.gd` that verifies:
- slot size is `80x80`
- player and AI board panels no longer touch edge-to-edge
- a central corridor exists between the two board panels
- the corridor width is sufficient for readable battle presentation (recommend a minimum contract, e.g. `>= 180px`)
- the decorative arena header/panel does not consume the whole corridor width

**Step 2: Run test to verify it fails**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_arena_layout_contract.gd`

Expected: FAIL because the current scene still places `PlayerBoardPanel` and `AiBoardPanel` directly adjacent at the midpoint and the slots are still larger than the desired fallback size.

**Step 3: Write minimal implementation**

- In `TenKingsBoardSlotUI.gd`, restore `custom_minimum_size = Vector2(80.0, 80.0)`
- In `TenKingsPrototype.tscn`:
  - reduce `PlayerBoardPanel` width
  - reduce `AiBoardPanel` width
  - move `AiBoardPanel` farther right
  - preserve a central battle corridor between them
  - move the decorative battle label/header so it does not block the actor lane
- Keep the lower UI readable; avoid letting the bottom panel visually eat the battle corridor

Recommended layout contract:
- left board fixed on the left side
- right board fixed on the right side
- center corridor reserved for actors and combat readability

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add scenes/dev/TenKingsPrototype.tscn scripts/dev/ten_kings/TenKingsBoardSlotUI.gd scripts/dev/tests/test_ten_kings_arena_layout_contract.gd
git commit -m "fix: restore ten kings battle corridor layout"
```

### Task 4: Add explicit arena anchors for formation and siege targeting

**Files:**
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Create: `scripts/dev/tests/test_ten_kings_arena_anchor_contract.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_ten_kings_arena_anchor_contract.gd` that verifies:
- the scene exposes dedicated battle-lane anchors
- `TenKingsPrototype.gd` can resolve those anchors into `BattleLayer` positions
- `TenKingsBattleManager.gd` can consume anchor-driven target positions for deploy and formation rather than relying only on hardcoded `x` constants

**Step 2: Run test to verify it fails**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_arena_anchor_contract.gd`

Expected: FAIL because the current scene/battle flow does not define explicit anchor nodes for the new corridor contract.

**Step 3: Write minimal implementation**

Add explicit `BattleLayer` anchor nodes, for example:
- `ArenaAnchors/PlayerFrontAnchor`
- `ArenaAnchors/PlayerRangedAnchor`
- `ArenaAnchors/PlayerBackAnchor`
- `ArenaAnchors/AiFrontAnchor`
- `ArenaAnchors/AiRangedAnchor`
- `ArenaAnchors/AiBackAnchor`
- `ArenaAnchors/PlayerCastleContactAnchor`
- `ArenaAnchors/AiCastleContactAnchor`

Then:
- in `TenKingsPrototype.gd`, resolve those anchors and pass them to `TenKingsBattleManager.gd`
- in `TenKingsBattleManager.gd`, derive deploy/formation target positions from anchors
- keep wrappers/facade style in `TenKingsPrototype.gd`; do not move battle logic into the scene orchestrator

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add scenes/dev/TenKingsPrototype.tscn scripts/dev/ten_kings/TenKingsPrototype.gd scripts/dev/ten_kings/TenKingsBattleManager.gd scripts/dev/tests/test_ten_kings_arena_anchor_contract.gd
git commit -m "feat: add ten kings arena anchors"
```

### Task 5: Align deploy and siege flow with the new battle corridor

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsUnit.gd`
- Create: `scripts/dev/tests/test_ten_kings_battle_lane_readability.gd`

**Step 1: Write the failing test**

Create `scripts/dev/tests/test_ten_kings_battle_lane_readability.gd` that verifies:
- units still deploy from board-slot origins
- formation targets end up in the reserved center corridor instead of under the boards
- winning troops chase toward castle-contact anchors inside that corridor flow
- battle does not end while winning troops are still visibly outside the castle contact zone

**Step 2: Run test to verify it fails**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_battle_lane_readability.gd`

Expected: FAIL because current deploy/siege behavior predates the new corridor contract.

**Step 3: Write minimal implementation**

- Preserve board-slot origin deployment in `TenKingsPrototype.gd`
- Update `TenKingsBattleManager.gd` so deploy/formation targets live inside the explicit arena corridor
- Use explicit castle-contact anchors (or equivalent explicit contact positions) for siege completion
- Keep `TenKingsUnit.gd` chase behavior consistent with the corridor-aware siege finish rule

**Step 4: Run test to verify it passes**

Run the same command.

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/dev/ten_kings/TenKingsPrototype.gd scripts/dev/ten_kings/TenKingsBattleManager.gd scripts/dev/ten_kings/TenKingsUnit.gd scripts/dev/tests/test_ten_kings_battle_lane_readability.gd
git commit -m "fix: align ten kings deploy and siege with arena lane"
```

### Task 6: Update docs for the tooltip and arena-layout contract

**Files:**
- Modify: `docs/dev/TEN_KINGS_PROTOTYPE.md`
- Modify: `docs/ARCHITECTURE.md`
- Modify: `docs/PROJECT_NAVIGATOR.md`

**Step 1: Update focused prototype docs**

Document that:
- board cells are visual-only
- slot details are presented through a hover tooltip
- the prototype reserves a central battle corridor between the two boards
- deploy and siege positioning use explicit arena anchors / contact points

**Step 2: Update architecture docs**

Document the split between:
- board UI-space
- tooltip UI-space
- battle world-space

**Step 3: Update navigator**

Add the new tooltip scene/script and any new anchor-related scene responsibilities.

**Step 4: Verify docs are coherent**

Read back the updated docs and confirm they match the final runtime contract.

**Step 5: Commit**

```bash
git add docs/dev/TEN_KINGS_PROTOTYPE.md docs/ARCHITECTURE.md docs/PROJECT_NAVIGATOR.md
git commit -m "docs: update ten kings tooltip and arena layout contract"
```

### Task 7: Final verification batch

**Files:**
- Verify all modified Ten Kings files
- Verify all new Ten Kings tests

**Step 1: Run focused tests**

Run:
- `C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_board_slot_visual_only.gd`
- `C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_board_tooltip_contract.gd`
- `C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_arena_layout_contract.gd`
- `C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_arena_anchor_contract.gd`
- `C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --script res://scripts/dev/tests/test_ten_kings_battle_lane_readability.gd`

Expected: PASS for all focused tests.

**Step 2: Run scene verification**

Run:
`C:/Godot/Godot_v4.3-stable_win64.exe --headless --path C:/Godot/clickcer --scene res://scenes/dev/TenKingsPrototype.tscn --quit-after 2`

Expected: scene boots without new Ten Kings script errors.

**Step 3: Manual editor verification**

Check visually:
- there is no multiline text inside board cells
- hover tooltip appears and follows the cursor sanely
- player and AI boards no longer touch each other
- battle actors fight in the central corridor instead of visually overlapping the boards

**Step 4: Commit**

```bash
git status
```

Confirm the working tree contains only the intended implementation/doc/test updates before continuing with any PR or merge flow.
