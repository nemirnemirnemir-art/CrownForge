# King Abilities Tooltip and Building Info Design

## Scope

This change does not redesign the king abilities HUD layout, slot arrangement, or the overall building menu structure.

The goal is limited to:

- reworking the informational king abilities popup so it clearly explains what an ability does, what it gives, and what conditions or status apply
- reworking the active ability upgrade button tooltip into the same informational style
- fixing building menu hover/info behavior so the menu no longer jumps when hover changes

## Current Problems

### King abilities

The current `AbilityTooltip` is a minimal three-line popup. It shows a title, description, and a single status line, but it does not separate:

- core effect
n- upgrade scaling or reward information
- requirements and temporary unavailability
- runtime state such as cooldown or already used

The upgrade tooltip has similar problems and currently behaves like a plain text box.

### Building menu

`BuildingMenu` currently hides the details panel on hover end. Because the details panel participates in layout, repeated show/hide cycles cause visible movement or jumping.

## Recommended Approach

### Option A: Structured tooltip sections without layout changes

Keep the existing HUD and building menu layout. Expand only the content model and scene structure of the tooltip UI.

For king abilities:

- title
- type line (`Active Ability` / `Passive Ability`)
- description section
- effect or reward section
- status section

For upgrade tooltip:

- title
- summary line
- current level
- next cost or maxed state

For building menu:

- keep details panel mounted and stable
- on hover, show hovered building info
- on hover end, fall back to selected building info instead of hiding the panel

This is the recommended approach because it addresses readability and jumping without redesigning the rest of the UI.

### Option B: Replace tooltip with a separate side info panel

This would improve readability further, but it would change the current UI structure too much and violates the clarified scope.

### Option C: Text-only improvements in existing labels

This is the lowest-risk option, but it would still leave the UI visually weak and not sufficiently informative.

## Chosen Design

Use Option A.

### King abilities tooltip behavior

The tooltip should:

- appear on slot hover
- keep the existing hover anchoring behavior
- present information in clear sections
- show runtime conditions using authoritative state from `KingSpellState`

The tooltip content should distinguish between:

- what the ability does
- what benefit or reward the player gets
- why it cannot currently be used, if applicable
- cooldown or already-used state

### Upgrade tooltip behavior

The upgrade tooltip should:

- use the same visual structure as the abilities tooltip
- explain that it improves active king abilities
- show current upgrade progress
- show next upgrade cost when available
- show max-state text when fully upgraded

### Building info behavior

The building details panel should stay visible whenever there is either:

- a currently selected building
- a currently hovered building

Hover becomes a temporary override of the selected building. When hover ends, the panel should restore the selected building instead of disappearing. This removes layout churn and prevents the menu from jumping.

## Affected Files

- `scenes/ui/hud/KingSpellHud.tscn`
- `scripts/ui/hud/KingSpellHud.gd`
- `scripts/ui/building/BuildingMenu.gd`

Potentially no changes are needed in `BuildingsTooltip.gd` unless extra stabilization is required after the menu fix.

## Validation

After implementation, verify:

- hovering an active ability shows structured info
- hovering a passive ability shows structured info and requirement status
- hovering the upgrade button shows level and next cost
- building menu does not jump when moving between tiles
- building info returns to the selected building after hover ends
