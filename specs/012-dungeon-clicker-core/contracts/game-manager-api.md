# API Contract: GameManager

**Phase**: 1 - Design  
**Date**: 2025-11-23  
**Status**: ✅ Complete

## Overview

GameManager is an autoload singleton that manages global game state, progression, and persistence.

## Public API

### State Properties

```gdscript
var current_gold: float
var current_stars: int
var current_stage: int
var max_stage_reached: int
var base_damage: float
var upgrade_level: int
```

**Access**: Read-write from any script via `GameManager.property_name`

**Validation**: 
- All numeric values must be >= 0 (except stage which is >= 1)
- `max_stage_reached >= current_stage`

---

### Core Functions

#### `add_gold(amount: float) -> void`

Adds gold to player's current gold.

**Parameters**:
- `amount: float` - Gold amount to add (must be >= 0)

**Behavior**:
- Adds `amount` to `current_gold`
- Calls `save_game()` automatically
- Emits signal or updates UI if needed

**Example**:
```gdscript
GameManager.add_gold(10.5)  # Adds 10.5 gold
```

**Edge Cases**:
- Negative amount: Clamp to 0 or ignore
- Overflow: Use float max (unlikely for MVP)

---

#### `add_stars(amount: int) -> void`

Adds permanent stars to player.

**Parameters**:
- `amount: int` - Stars to add (must be >= 0)

**Behavior**:
- Adds `amount` to `current_stars`
- Permanent bonus applies immediately via damage calculation
- Calls `save_game()` automatically

**Example**:
```gdscript
GameManager.add_stars(5)  # Adds 5 stars
```

**Edge Cases**:
- Negative amount: Clamp to 0 or ignore

---

#### `go_to_next_stage() -> void`

Advances player to the next stage.

**Behavior**:
- Increments `current_stage`
- Updates `max_stage_reached` if `current_stage > max_stage_reached`
- Calls `save_game()` automatically
- Can trigger stage change events

**Example**:
```gdscript
GameManager.go_to_next_stage()  # Stage 5 → Stage 6
```

**Edge Cases**:
- Stage overflow: Cap at reasonable maximum (e.g., 9999)

---

#### `prestige() -> void`

Resets progress and awards permanent stars.

**Behavior**:
1. Calculates stars: `stars_earned = floor(max_stage_reached / 50)`
2. Adds stars: `current_stars += stars_earned`
3. Resets: `current_gold = 0`, `current_stage = 1`, `upgrade_level = 0`
4. Permanent damage bonus applies via star multiplier in damage calculation
5. Calls `save_game()` automatically

**Example**:
```gdscript
GameManager.prestige()  # Reset with stars based on max_stage_reached
```

**Edge Cases**:
- Prestige at stage 1: Awards 0 stars, but still resets
- Stars calculation: Uses floor division, minimum 0

---

#### `save_game() -> void`

Saves current game state to file.

**Behavior**:
- Serializes GameState to JSON
- Writes to `user://save.json`
- Handles file errors gracefully (logs, doesn't crash)

**Example**:
```gdscript
GameManager.save_game()  # Saves current state
```

**Edge Cases**:
- File write error: Log error, continue game
- Invalid data: Validate before saving

---

#### `load_game() -> bool`

Loads game state from file.

**Returns**: `true` if load successful, `false` if file doesn't exist or invalid

**Behavior**:
- Reads from `user://save.json`
- Parses JSON and restores GameState
- Validates loaded data
- Returns `false` if file missing or invalid

**Example**:
```gdscript
if GameManager.load_game():
    print("Game loaded successfully")
else:
    print("Starting new game")
```

**Edge Cases**:
- File doesn't exist: Returns `false`, starts with defaults
- Corrupted JSON: Returns `false`, starts with defaults
- Invalid values: Validate and clamp to safe ranges

---

#### `get_click_damage() -> float`

Calculates and returns current click damage.

**Returns**: Total click damage (float)

**Behavior**:
- Calls `DamageCalculator.calculate_click_damage()`
- Uses: `base_damage`, `upgrade_multiplier`, `current_stars`
- Returns calculated damage

**Example**:
```gdscript
var damage = GameManager.get_click_damage()  # e.g., 12.5
```

**Formula**: `base_damage * upgrade_multiplier * (1 + current_stars * 0.02)`

---

#### `can_afford_upgrade() -> bool`

Checks if player can afford next upgrade.

**Returns**: `true` if player has enough gold, `false` otherwise

**Behavior**:
- Calculates next upgrade price
- Compares with `current_gold`
- Returns result

**Example**:
```gdscript
if GameManager.can_afford_upgrade():
    GameManager.purchase_upgrade()
```

---

#### `purchase_upgrade() -> bool`

Purchases next upgrade level.

**Returns**: `true` if purchase successful, `false` if insufficient gold

**Behavior**:
1. Checks if player can afford upgrade
2. Deducts gold: `current_gold -= upgrade_price`
3. Increments: `upgrade_level += 1`
4. Recalculates: `upgrade_multiplier`
5. Calls `save_game()` automatically
6. Returns `true` on success

**Example**:
```gdscript
if GameManager.purchase_upgrade():
    print("Upgrade purchased!")
else:
    print("Not enough gold")
```

**Edge Cases**:
- Insufficient gold: Returns `false`, no changes
- Price calculation: Uses formula: `BASE_PRICE * (SCALE_FACTOR ^ upgrade_level)`

---

## Internal Functions (Private)

### `_calculate_upgrade_multiplier() -> float`

Calculates upgrade multiplier from upgrade level.

**Formula**: `1.0 + (UPGRADE_DAMAGE_PER_LEVEL * upgrade_level)`

---

### `_calculate_upgrade_price() -> float`

Calculates price for next upgrade.

**Formula**: `UPGRADE_BASE_PRICE * (UPGRADE_SCALE_FACTOR ^ upgrade_level)`

---

## Constants

```gdscript
const UPGRADE_BASE_PRICE: float = 10.0
const UPGRADE_SCALE_FACTOR: float = 1.5
const UPGRADE_DAMAGE_PER_LEVEL: float = 0.1
const PRESTIGE_STAGE_DIVISOR: int = 50
const STAR_DAMAGE_BONUS: float = 0.02
```

---

## Usage Examples

### Basic State Access

```gdscript
# Read state
var gold = GameManager.current_gold
var stage = GameManager.current_stage

# Modify state (use functions when available)
GameManager.add_gold(10.0)
```

### Upgrade Purchase Flow

```gdscript
if GameManager.can_afford_upgrade():
    if GameManager.purchase_upgrade():
        print("Upgrade successful!")
        # UI updates automatically via update_display()
```

### Prestige Flow

```gdscript
var stars_before = GameManager.current_stars
GameManager.prestige()
var stars_after = GameManager.current_stars
var stars_earned = stars_after - stars_before
print("Earned ", stars_earned, " stars from prestige")
```

### Save/Load Flow

```gdscript
# On game start
func _ready():
    if not GameManager.load_game():
        # Start with defaults
        GameManager.current_stage = 1
        GameManager.current_gold = 0.0

# On state change (automatic in GameManager functions)
# GameManager.save_game() is called automatically
```

---

## Error Handling

All functions handle errors gracefully:
- Invalid parameters: Clamp to valid ranges or ignore
- File errors: Log and continue (don't crash)
- Calculation errors: Return safe defaults

---

## Thread Safety

GameManager is not thread-safe. All access must be from main thread (Godot's default).

---

## Performance Considerations

- Save operations are synchronous (blocking)
- Save called automatically on state changes (may be frequent)
- Consider debouncing saves if performance issues arise
- For MVP, synchronous saves are acceptable

---

## Future Extensions

Potential additions (out of scope for MVP):
- Signals for state changes (for UI updates)
- Save slot system (multiple saves)
- Cloud save integration
- Analytics hooks (out of scope)

