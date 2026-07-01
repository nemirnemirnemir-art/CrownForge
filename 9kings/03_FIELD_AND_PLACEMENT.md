# 03 — Field and Placement

## Grid Layout

- [CONFIRMED] Base grid: 3×3 = 9 slots
- [CONFIRMED] Grid expands via Tower event: +2 plots
- [CONFIRMED] After Year 33 in endless mode: further plots cost 30g each
- [CONFIRMED] Normal maximum: 11 slots
- [CONFIRMED] With perks: up to 13 slots

```
Default 3×3 grid:

  [ ][ ][ ]
  [ ][ ][ ]
  [ ][ ][ ]

After Tower event (11 slots):
  [ ][ ][ ][ ][ ]
  [ ][ ][ ]
  [ ][ ][ ]
  (exact layout of expansion [MISSING])
```

---

## Plot Types

### Standard Plot
- [CONFIRMED] Holds any card type (Troop, Building, Tower, Enchantment, Tome, Base)
- [CONFIRMED] One card per plot
- [CONFIRMED] Cards upgrade by placing a duplicate on an already-occupied plot

### Plot States
- **Empty** — available to place a card
- **Occupied (level 1)** — single card placed
- **Occupied (level 2)** — duplicate placed on existing card
- **Occupied (level 3)** — second duplicate placed; max level (except Base + Ingenious perk)
- **Destroyed** — [CONFIRMED] plots can be destroyed; King of Nomads' Dragon's Den scales with destroyed plots

---

## Placement Rules

### Basic Rules
- [CONFIRMED] Cards are placed on plots before each battle
- [MISSING] Whether placement is free (unlimited moves) or constrained per turn
- [MISSING] Whether cards can be freely repositioned each year or only placed once

### Upgrade Placement
- [CONFIRMED] Placing a duplicate card on an occupied plot upgrades it (not a new card on a new slot)
- [CONFIRMED] Level cap is 3 (with exception for Base + Ingenious perk)
- [INFERRED] You must own duplicate copies of a card to upgrade it

### Special Placement Cases
- [CONFIRMED] King of Nomads "Migration" Tome: moves existing plots to new positions
- [CONFIRMED] King of Stone "Stronghold" Base: builds its own towers (places towers automatically)
- [CONFIRMED] King of Stone "Trapper": places traps; traps persist between battles (cross-battle persistence)

---

## Adjacency Mechanics

### Mounting (King of Nature)
- [CONFIRMED] Boar (Troop): can be mounted by an adjacent troop
- [CONFIRMED] Raptor (Troop): can be mounted by an adjacent troop
- [MISSING] Exact mechanical effect of mounting (speed boost? damage boost? both?)
- [MISSING] Which directions count as "adjacent" (orthogonal only, or diagonal too?)

### Blacksmith (King of Nothing)
- [CONFIRMED from meta] Blacksmith buffs adjacent troops — very strong engine card
- [MISSING] Exact buff values and adjacency definition

### Trebuchet (King of Stone)
- [CONFIRMED] Shoots extra projectiles per nearby construction
- [MISSING] Radius of "nearby" (1 tile? All tiles?)

### Lab Rat (King of Progress)
- [CONFIRMED] Lab Rat levels up when adjacent plots level up
- [CONFIRMED] Lab Rat has NO level cap
- [MISSING] Whether "adjacent" is orthogonal, diagonal, or both

---

## Plot Destruction

- [CONFIRMED] Plots can be destroyed during a run (by enemy effects or certain mechanics)
- [CONFIRMED] Dragon's Den (King of Nomads) grows 20% per destroyed plot — intentional synergy
- [CONFIRMED] "Razing" is a Merchant card that intentionally destroys a plot
- [INFERRED] Destroying plots is a strategic choice for Nomads builds, not just a downside
- [MISSING] Which enemy abilities can destroy plots
- [MISSING] Whether destroyed plots can be rebuilt

---

## Slot Economy

### Standard Run
| Source | Slots Gained |
|--------|-------------|
| Starting grid | 9 |
| Tower event | +2 |
| **Total (normal max)** | **11** |

### With Perks
- [CONFIRMED] Perks can expand to 13 slots
- [MISSING] Which specific perks grant extra slots

### Cost Scaling (Endless Mode)
- [CONFIRMED] After Year 33: additional plots cost 30g each
- [MISSING] Whether cost increases with each purchase or stays at 30g
