# Ten Kings Castle Fire And Structure Damage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the gray arena obstruction, add player-castle auto/manual fire with editable scene-driven splash damage, add crowd-compatible fixed-structure attacks and per-slot damage totals, and finish the supporting UI/UX rules without re-asking already answered questions.

**Architecture:** Keep combat centralized in `TenKingsBattleManager.gd` and the crowd runtime, but move all building/castle projectile behavior into crowd-compatible fixed-structure processing. Use scene-driven effects for castle splash visuals and editable radii, aggregate damage by board slot with integer counters only, and render post-battle damage totals on board slots after combat ends. Avoid per-frame UI churn during combat.

**Tech Stack:** Godot 4.3, GDScript, scene-driven effects (`.tscn`), `res://scripts/dev/ten_kings/`, `res://scenes/dev/`, headless SceneTree tests.

---

## Locked Decisions (Do Not Re-Ask)

These decisions are already approved by the user. The next engineer/AI should implement them directly unless the repository makes them impossible.

- The gray visual layer covering the battle arena must be removed.
- The "main building" means `castle`.
- Only the **player castle** has fire modes.
- The player castle fire modes are:
  - `auto` (default, active by default)
  - `manual`
- AI castle is always automatic.
- Manual castle fire targets a **ground point**, not a specific unit.
- Holding the mouse in manual mode must still obey the normal castle cooldown.
- Castle splash must use a **scene-driven** effect (`.tscn`) with editable settings, not hardcoded-only radii.
- Castle impact has 3 damage zones:
  - inner: `100%`
  - middle: `50%`
  - outer: `25%`
- On impact, the 3 gray rings should appear in very fast sequence.
- No pre-shot targeting circle/preview should be shown to the player.
- Because AI buildings are hidden from the main screen, AI structure shots must originate from **offscreen right, vertically centered**, not from a visible board panel.
- Player structure shots must originate from the actual player build slot positions.
- Only the rule "do not allow a second castle" must be enforced.
- Other placements/upgrades must continue to work.
- Damage totals shown on cells are **summed per board slot**.
- Damage numbers clear when the **next battle starts**.
- Damage numbers appear on player board and inside the AI board popup.
- Damage numbers use `res://assets/ui/fonts/ThaleahFat.ttf`.
- Damage numbers are integer/rounded, not decimals.
- Do not ask obvious confirmation questions for already specified resources/paths/values when the repo confirms them.

---

## Relevant Existing Files

### Main prototype and UI
- `scenes/dev/TenKingsPrototype.tscn`
- `scripts/dev/ten_kings/TenKingsPrototype.gd`
- `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`

### Combat systems
- `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- `scripts/dev/ten_kings/TenKingsBattleDebug.gd`

### Existing effects / projectiles
- `scripts/dev/ten_kings/TenKingsProjectileEffect.gd`
- `scenes/dev/ten_kings/effects/TenKingsProjectileEffect.tscn`

### Board / placement rules
- `scripts/dev/ten_kings/TenKingsBoardState.gd`
- `scripts/dev/ten_kings/TenKingsTurnFlow.gd`
- `scripts/dev/ten_kings/TenKingsPlayerState.gd`

### Fonts
- `assets/ui/fonts/ThaleahFat.ttf`

---

## Known Current Problems To Solve

1. The battle arena is visibly covered by a gray layer during battle.
2. Crowd mode currently focuses on soldier-vs-soldier behavior, but fixed structures need full support.
3. Player castle lacks auto/manual firing.
4. Castle splash is not scene-driven/editable yet.
5. Structure projectile origins do not follow the new UI rules.
6. A second castle is not explicitly forbidden by board rules.
7. Post-battle damage totals per board slot are not displayed.
8. Current debug output is better than before, but does not break out structure damage and splash behavior clearly enough.

---

## Task 1: Remove the gray arena obstruction

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_battle_arena_unobstructed.gd`
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`

**Step 1: Write the failing test**
- Instantiate `TenKingsPrototype.tscn`.
- Assert battle mode preserves arena width but does not leave a visible gray `PanelContainer` above the actual battle.
- The test should verify the battle-state layout strategy rather than manually parsing screenshots.

**Step 2: Run test to verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_battle_arena_unobstructed.gd"`

**Step 3: Implement the fix**
- Current likely root cause: `ArenaPanel` still visually renders a panel even though children are hidden/transparent.
- Replace current battle-mode behavior with one of these:
  - recommended: hide visual panel and swap in a layout-only spacer,
  - acceptable: replace theme/stylebox with fully transparent no-draw state during battle.
- Preserve the arena width and the player board width behavior already introduced.

**Step 4: Re-run the test**
- Expected: PASS

---

## Task 2: Make crowd mode return fixed structures properly

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_crowd_fixed_structures_exist.gd`
- Modify: `scripts/dev/ten_kings/TenKingsCrowdBuilder.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`

**Step 1: Write the failing test**
- Build a board containing `castle`, `scout_tower`, and troops.
- Assert crowd preparation returns two channels of battle entities:
  - `soldiers`
  - `fixed_structures`
- Assert every fixed structure preserves `source_slot`.

**Step 2: Run the test and verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_crowd_fixed_structures_exist.gd"`

**Step 3: Change builder contract**
- `TenKingsCrowdBuilder.expand_stacks_to_soldiers()` should return a dictionary:
  - `soldiers: Array`
  - `fixed_structures: Array`
- Each fixed structure must include:
  - `card_id`
  - `position`
  - `source_slot`
  - `side`
  - `attack_dmg`
  - `attack_cd`
  - `attack_range`
  - anything else required for runtime

**Step 4: Update crowd battle start path**
- `TenKingsBattleManager._start_crowd_battle()` must consume the new builder dictionary and store `_player_fixed_structures` / `_ai_fixed_structures` in crowd mode as well.

**Step 5: Re-run the test**
- Expected: PASS

---

## Task 3: Add player castle fire modes and manual input routing

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_player_castle_fire_mode_contract.gd`
- Create: `scripts/dev/tests/test_ten_kings_player_castle_manual_click_fire.gd`
- Modify: `scenes/dev/TenKingsPrototype.tscn`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`

**Step 1: Write the fire-mode contract test**
- Assert the player castle has two firing modes:
  - `auto`
  - `manual`
- Assert default is `auto`.

**Step 2: Write the manual click-fire test**
- Assert battle clicks in manual mode are converted into a fire command at a world point.
- Assert holding the mouse still respects cooldown and does not spam instantly.

**Step 3: Add the fire mode UI**
- Add an `[auto]` toggle/button to the main prototype HUD.
- When active, castle auto-targets nearest valid enemy.
- When inactive/manual, clicks in battle area request a castle shot at ground position.

**Step 4: Add input routing in `TenKingsPrototype.gd`**
- Convert screen click -> battle world point.
- Forward to battle manager only if:
  - battle is active,
  - player castle exists,
  - mode is manual.
- Holding the mouse should request shots repeatedly, but the manager must enforce cooldown.

**Step 5: Re-run both tests**
- Expected: PASS

---

## Task 4: Create scene-driven castle impact splash

**Files:**
- Create: `scenes/dev/ten_kings/effects/TenKingsCastleImpact.tscn`
- Create: `scripts/dev/ten_kings/TenKingsCastleImpact.gd`
- Create: `scripts/dev/tests/test_ten_kings_castle_impact_damage_falloff.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`

**Step 1: Write the failing splash damage test**
- Build a small battle setup with units placed at controlled distances from the impact point.
- Assert damage falloff is:
  - inner ring -> 100%
  - middle ring -> 50%
  - outer ring -> 25%

**Step 2: Run test to verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_castle_impact_damage_falloff.gd"`

**Step 3: Build the editable impact scene**
- `TenKingsCastleImpact.gd` should expose exported properties editable in the scene:
  - `inner_radius`
  - `middle_radius`
  - `outer_radius`
  - `inner_multiplier`
  - `middle_multiplier`
  - `outer_multiplier`
  - timing for rapid gray ring reveal
- The scene should own the visual ring effect data, not hardcode all values in manager code.

**Step 4: Integrate impact scene into castle firing**
- Both player manual and auto castle fire should use the same impact pipeline.
- Manager computes affected targets by distance from impact point.
- Apply splash to crowd-mode soldiers and legacy-mode units if needed.

**Step 5: Re-run splash test**
- Expected: PASS

---

## Task 5: Add scout tower arrows and structure projectile origin policy

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_structure_projectile_origins.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd` if helper origin APIs are needed

**Step 1: Write the failing origin test**
- Assert player structure shots originate from real player slot positions.
- Assert AI structure shots originate from right-side offscreen centered origin.

**Step 2: Run test and verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_structure_projectile_origins.gd"`

**Step 3: Implement origin helpers**
- Player `castle` / `scout_tower`:
  - use real board slot centers from player build grid.
- AI `castle` / `scout_tower`:
  - use synthesized origin from offscreen right, vertically near battle center.

**Step 4: Split structure weapon behaviors**
- `castle` uses cannonball projectile + splash impact.
- `scout_tower` uses arrow projectile + direct target hit.

**Step 5: Re-run origin test**
- Expected: PASS

---

## Task 6: Forbid a second castle while keeping normal upgrades valid

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_no_second_castle.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBoardState.gd`

**Step 1: Write the failing castle rule test**
- Assert:
  - board cannot place a second castle on another empty slot,
  - non-castle placements still work,
  - castle upgrades on the existing castle slot still work if current upgrade rules allow them.

**Step 2: Run test and verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_no_second_castle.gd"`

**Step 3: Implement rule in `TenKingsBoardState.gd`**
- In `can_place_card()`:
  - if `card_id == CASTLE_ID` and board already has a castle in a different slot, reject placement.
- Preserve same-slot castle upgrade semantics.

**Step 4: Re-run castle rule test**
- Expected: PASS

---

## Task 7: Add per-slot battle damage totals for troops and buildings

**Files:**
- Create: `scripts/dev/tests/test_ten_kings_slot_damage_totals.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`
- Modify: `scripts/dev/ten_kings/TenKingsPrototype.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBoardSlotUI.gd`

**Step 1: Write the failing damage total test**
- Assert that battle damage is aggregated by slot, not by individual soldier.
- Assert troop damage is counted under the source troop slot.
- Assert building damage is counted under the structure slot.
- Assert totals clear when the next battle starts.

**Step 2: Run test and verify it fails**
Run:
`"/c/Godot/Godot_v4.3-stable_win64.exe" --headless --script "scripts/dev/tests/test_ten_kings_slot_damage_totals.gd"`

**Step 3: Add lightweight counters only**
- Keep an integer dictionary keyed by:
  - side
  - source_slot
- Update counters only on successful hit / damage application events.
- Do not update UI each frame.

**Step 4: Render damage totals after battle**
- Extend `TenKingsBoardSlotUI.gd` with a dedicated damage label overlay.
- Use white text and `res://assets/ui/fonts/ThaleahFat.ttf`.
- Show rounded integer totals.

**Step 5: Show on both boards**
- Player board always visible.
- AI popup board also shows its slot totals.

**Step 6: Clear totals at next battle start**
- Reset both runtime counters and visible labels before the next combat begins.

**Step 7: Re-run damage total test**
- Expected: PASS

---

## Task 8: Improve debug output for structure fire and melee pacing

**Files:**
- Modify: `scripts/dev/ten_kings/TenKingsCrowdRuntime.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleDebug.gd`
- Modify: `scripts/dev/ten_kings/TenKingsBattleManager.gd`

**Step 1: Extend heartbeat summary**
- Add structure-specific metrics:
  - `castle_attacks_player`
  - `castle_attacks_enemy`
  - `tower_attacks_player`
  - `tower_attacks_enemy`
  - `castle_damage_player`
  - `castle_damage_enemy`
  - `splash_inner_hits`
  - `splash_middle_hits`
  - `splash_outer_hits`
  - top slot damage contributors in current window

**Step 2: Add stateful castle debug snapshot**
- Keep non-spammy snapshots for:
  - fire mode (`auto` / `manual`)
  - last impact point
  - cooldown ready/not ready
  - last splash hit counts

**Step 3: Keep logs aggregated**
- No per-projectile spam.
- Preserve readable interval summaries only.

---

## Task 9: Add docs rule against obvious confirmation questions

**Files:**
- Modify: `docs/AGENTS.md`

**Step 1: Add a short explicit rule**
- If the user directly provides:
  - exact path/resource/value,
  - and repo confirms it,
  - and that answer does not change architecture,
  - do not ask a confirmation question.

**Step 2: Add one concrete example**
- Bad example:
  - user gives `C:\Godot\clickcer\assets\ui\fonts\ThaleahFat.ttf`
  - repo confirms it exists
  - AI asks “Use this font?”
- Good behavior:
  - AI uses it directly.

---

## Task 10: Final verification

**Files:**
- Test only

**Step 1: Run targeted tests**
- `test_ten_kings_battle_arena_unobstructed.gd`
- `test_ten_kings_crowd_fixed_structures_exist.gd`
- `test_ten_kings_player_castle_fire_mode_contract.gd`
- `test_ten_kings_player_castle_manual_click_fire.gd`
- `test_ten_kings_castle_impact_damage_falloff.gd`
- `test_ten_kings_structure_projectile_origins.gd`
- `test_ten_kings_no_second_castle.gd`
- `test_ten_kings_slot_damage_totals.gd`

**Step 2: Run smoke tests**
- `test_ten_kings_battle_flow.gd`
- existing crowd regression tests

**Step 3: Manual verification in `res://scenes/dev/TenKingsPrototype.tscn`**
- arena is unobstructed during battle
- player castle `[auto]` toggle works
- manual click/hold obeys cooldown
- cannonball impact shows 3 fast gray rings
- AI structure shots originate from right-center offscreen
- player structure shots originate from real slot positions
- second castle placement is rejected
- post-battle damage totals appear on player board and AI popup board
- totals clear at next battle start

---

## Implementation Notes For The Next AI

- Start with Task 1, not with the castle feature. The arena overlay bug needs to be eliminated first so battle visuals are reliable.
- Do not attempt castle/tower fire in crowd mode until Task 2 is done, because fixed structures are not fully wired through crowd mode yet.
- Do not hardcode castle splash radii directly into manager logic; the scene/script pair must expose editable exported values.
- Keep performance discipline:
  - aggregate damage counters only on attack/hit events,
  - do not touch slot labels every frame during battle,
  - clear and render totals only at battle boundaries.
- Use the locked decisions above as final requirements. Do not ask the user to reconfirm them unless the current repo makes one of them impossible.
