# King Abilities Tooltip and Building Info Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve king abilities informational tooltips and stabilize building menu info behavior without redesigning the HUD or menu layout.

**Architecture:** Keep the current HUD and menu structure intact. Expand tooltip scene structure and tooltip text composition in `KingSpellHud`, then change `BuildingMenu` hover behavior so the details panel remains stable and falls back to the selected building instead of hiding on hover end.

**Tech Stack:** Godot 4.x, GDScript, `.tscn` UI scenes, existing singleton state from `KingSpellState`

---

### Task 1: Expand the king ability tooltip scene

**Files:**
- Modify: `scenes/ui/hud/KingSpellHud.tscn`
- Modify: `scripts/ui/hud/KingSpellHud.gd`

**Step 1: Add structured tooltip nodes**

Add dedicated labels for:

- title
- type line
- description section header/body
- effect section header/body
- status section header/body

Keep the tooltip anchored and hidden by default.

**Step 2: Run a focused scene syntax check**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: no scene parse error from `KingSpellHud.tscn`

**Step 3: Bind new tooltip nodes in script**

Update `KingSpellHud.gd` to resolve the new labels with `@onready` references.

**Step 4: Verify parsing again**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: no parse errors from missing nodes or paths.

### Task 2: Populate structured king ability tooltip content

**Files:**
- Modify: `scripts/ui/hud/KingSpellHud.gd`
- Reference: `scripts/ui/spells/CharacterCreationSpellCatalog.gd`
- Reference: `core/king_spell_state.gd`

**Step 1: Build helper methods for tooltip sections**

Add helpers that compute:

- ability type text
- effect text
- status text
- requirements text for passive and active abilities

Use authoritative runtime state from `KingSpellState`.

**Step 2: Update hover refresh logic**

Populate each tooltip section on hover instead of using a single body/status line.

**Step 3: Run parser check**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: no GDScript parser errors.

**Step 4: Manual runtime verification**

Verify in game:

- active tooltip shows description, effect, cooldown or requirement
- passive tooltip shows description, reward/effect, condition progress, already-used state

### Task 3: Rework the upgrade button tooltip into the same information style

**Files:**
- Modify: `scenes/ui/hud/KingSpellHud.tscn`
- Modify: `scripts/ui/hud/KingSpellHud.gd`
- Reference: `core/king_spell_state.gd`

**Step 1: Expand upgrade tooltip structure**

Add labels for:

- title
- summary
- current level
- next cost or maxed state

**Step 2: Replace plain text composition**

Generate structured text from current `active_upgrade_level` and `get_next_upgrade_cost()`.

**Step 3: Run parser check**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: no scene or script parse errors.

**Step 4: Manual runtime verification**

Verify in game:

- hovering the upgrade button shows current progress
- next cost is listed clearly
- maxed state is shown when upgrades are exhausted

### Task 4: Stabilize building menu hover/details behavior

**Files:**
- Modify: `scripts/ui/building/BuildingMenu.gd`
- Reference: `scripts/ui/town/BuildingsTooltip.gd`

**Step 1: Keep the details panel mounted**

Change hover behavior so hover temporarily overrides the displayed building, but hover end restores the selected building instead of hiding the panel.

**Step 2: Ensure selection and resource refresh respect the same source-of-truth**

When resources change, update the currently displayed building info using hovered id first, selected id second.

**Step 3: Run parser check**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: no parser errors.

**Step 4: Manual runtime verification**

Verify in game:

- moving between building tiles does not make the menu jump
- details panel remains stable
- hover info overrides selected info temporarily
- hover end restores selected building info

### Task 5: Final verification

**Files:**
- Modify: `scripts/ui/hud/KingSpellHud.gd`
- Modify: `scripts/ui/building/BuildingMenu.gd`
- Modify: `scenes/ui/hud/KingSpellHud.tscn`

**Step 1: Run full parser check**

Run: `godot --headless --path c:\Godot\clickcer --check-only`
Expected: project parses successfully.

**Step 2: Smoke-test UI manually**

Verify:

- king ability slots still function
- active cooldowns still update
- passive abilities still lock after use
- upgrade button still purchases correctly
- building details still update after resource changes

**Step 3: Commit**

```bash
git add docs/plans/2026-03-11-king-abilities-tooltips-design.md docs/plans/2026-03-11-king-abilities-tooltips-implementation.md scenes/ui/hud/KingSpellHud.tscn scripts/ui/hud/KingSpellHud.gd scripts/ui/building/BuildingMenu.gd
git commit -m "feat: improve king ability tooltips and stabilize building info"
```
