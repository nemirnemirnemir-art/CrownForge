# 04 — Combat System

## Core Concept

9 Kings uses an **auto-battler** format:
- Players do NOT micro-manage units during battle
- Kingdom cards act autonomously based on their programmed behaviors
- Player's only direct combat input: King's active ability (manually triggered or set to auto)
- Battle ends when one side's units are all eliminated

---

## Battle Flow

```
PLACEMENT PHASE ends
        │
        ▼
BATTLE STARTS
  - All Troops deploy from their grid positions onto the battlefield
  - Towers remain on the grid (indestructible, stationary)
  - Buildings remain on grid (passive effects continue)
        │
        ▼
COMBAT LOOP (auto)
  - Troops move toward targets
  - Towers shoot at targets automatically
  - Status effects tick
  - Player can trigger King's active ability
        │
        ▼
BATTLE ENDS
  - One side has all units eliminated (or time limit? [MISSING])
  - Winner determined
```

---

## Targeting Rules

### Default Targeting
- [CONFIRMED] Default: closest enemy

### Special Targeting (per unit)
| Unit | Targeting Rule |
|------|---------------|
| Elf (Nature) | Most distant enemy |
| Executioner (Progress) | Lowest HP enemy |
| Thief (Greed) | Jumps to enemy backline |
| [All others] | Closest enemy [CONFIRMED as default] |

---

## Damage Types and Modifiers

### Base Damage
- [MISSING] Exact base damage values per card per level

### Critical Hits
- [CONFIRMED] Crit chance exists; modified by "Eyeglass" Decree (+20% crit chance, stackable x5)
- [CONFIRMED] Crit damage multiplied by "Iron Fist" Decree (doubles crit damage, stackable x3)
- [MISSING] Default crit chance (before decrees)
- [MISSING] Default crit damage multiplier

### Damage Amplification
- [CONFIRMED] "Weakspot" Decree: +50% damage vs frozen / stunned / poisoned enemies
- [CONFIRMED] "Sharp Blades" Decree: +30% attack (stackable x20)
- [CONFIRMED] Enchantments can boost damage (Swords: attack buff; details [MISSING])

### Scaling Damage (card-specific)
- [CONFIRMED] Soldier (Nothing): unique damage scaling [MISSING formula]
- [CONFIRMED] Paladin (Nothing): unique damage scaling [MISSING formula]
- [CONFIRMED] Mercenary (Greed): damage scales with current gold held
- [CONFIRMED] Demon's Altar (Blood): grows 0.5% per dead ally (permanent, cross-battle)
- [CONFIRMED] Dragon's Den (Nomads): grows 20% per destroyed plot
- [CONFIRMED] Lab Rat (Progress): levels up from adjacent upgrades; no level cap → no damage cap

---

## Status Effects

### Poison
- [CONFIRMED] Poison exists as a status effect
- [CONFIRMED] "Poison Thorns" Decree: enemies take poison on hit (stackable x20)
- [CONFIRMED] "Venom" Decree: poison applied twice (stackable x3)
- [CONFIRMED] "Weakspot" Decree: +50% damage vs poisoned enemies
- [CONFIRMED] Poison Vial (Nature) applies poison
- [MISSING] Poison damage per tick, duration, stacking cap

### Freeze / Stun
- [CONFIRMED] Freeze/stun exists (referenced by Weakspot Decree)
- [CONFIRMED] Frost (Nomads): freeze/slow effect
- [MISSING] Exact mechanics of freeze vs stun (duration, break condition)

### Roots
- [CONFIRMED] Orchard (Nature): traps enemies with roots
- [MISSING] Root duration, whether roots count as "stun" for Weakspot

---

## Towers in Combat

- [CONFIRMED] Towers CANNOT be attacked or destroyed by enemy units
- [CONFIRMED] Towers CANNOT receive Enchantments
- [CONFIRMED] Towers shoot projectiles automatically at enemies
- [CONFIRMED] Scout Tower (Nothing): basic ranged tower
- [CONFIRMED] Dispenser (Greed): scales with gold received
- [CONFIRMED] Spire (Spells): spell tower [MISSING: exact ability]
- [CONFIRMED] Trebuchet (Stone): extra projectiles per nearby construction
- [CONFIRMED] Ballista (Stone): heavy ranged
- [CONFIRMED] Flametower (Stone): fire-based
- [CONFIRMED] Citadel (Spells, Base): shoots chain lightning
- [CONFIRMED] Stronghold (Stone, Base): builds its own towers

---

## King's Active Ability

- [CONFIRMED] Each king has an active ability usable during battle
- [CONFIRMED] Player can trigger it manually OR set it to auto-trigger
- [MISSING] Cooldown, cost, or trigger conditions per king
- [MISSING] Full list of what each king's active ability does

---

## Lives and Defeat

- [CONFIRMED] Losing a battle = -1 life
- [CONFIRMED] Losing Year 33 Final Battle = ALL lives removed (instant run end)
- [MISSING] Starting life count
- [CONFIRMED] Rebirth Decree restores all lives

---

## Persistence Between Battles

- [CONFIRMED] Demon's Altar (Blood): growth is permanent — persists and compounds across battles
- [CONFIRMED] Trapper (Stone): traps placed persist between battles
- [INFERRED] Most unit stats reset between battles; scaling cards are exceptions
- [MISSING] Full list of what persists vs resets
