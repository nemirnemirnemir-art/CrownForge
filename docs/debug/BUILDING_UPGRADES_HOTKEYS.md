# Building Upgrades Debug Hotkeys (E/R)

## Overview
Debug hotkeys for mass-unlocking building upgrades in development/testing mode.

- **Only works in DEBUG MODE** (`release_mode_enabled = false` in GameScene)
- Hotkeys: **E** (available only) and **R** (all in game)
- Logged to Output console with detailed per-building info

---

## Hotkeys

### E - Unlock Available Upgrades
- Unlocks all upgrades that haven't been unlocked yet
- Targets both:
  - **Recipes** (buildings player has but hasn't built)
  - **Built buildings** on map (missing upgrade levels)
- Only increments counter for NEW unlocks
- Useful for testing game state after player progression

### R - Unlock All Upgrades in Game
- Unconditionally unlocks ALL ~193 upgrades
- Processes all 61 buildings (whether built or not)
- Unlocks every upgrade level for each building
- Use for testing complete game state

---

## Implementation Files

### 1. DebugBuildingUpgradesModule.gd (NEW)
**Location:** `scripts/ui/debug/modules/DebugBuildingUpgradesModule.gd`

Core logic module with two public methods:
- `unlock_all_available_upgrades()` - E key action
- `unlock_all_upgrades_in_game()` - R key action

**Design:**
- Extends `RefCounted` (lightweight utility)
- Gets building list from `BuildingPresentationData.get_all_buildings()` (canonical source)
- Uses `BuildingUpgradeCore.unlock_building_upgrade()` for each upgrade
- Tracks unlock counts and building details for logging
- Pretty-prints results to Output console

### 2. GameSceneInputController.gd (MODIFIED)
**Location:** `scripts/game_scene/GameSceneInputController.gd`

Added E/R hotkey handling in `handle_input()`:
```gdscript
if (not _scene.release_mode_enabled) and event is InputEventKey and event.pressed:
    if event.keycode == KEY_E and not event.echo:
        if _scene._debug_building_upgrades_module:
            _scene._debug_building_upgrades_module.unlock_all_available_upgrades()
        _scene.get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_R and not event.echo:
        if _scene._debug_building_upgrades_module:
            _scene._debug_building_upgrades_module.unlock_all_upgrades_in_game()
        _scene.get_viewport().set_input_as_handled()
        return
```

### 3. GameScene.gd (MODIFIED)
**Location:** `scripts/game/GameScene.gd`

Added module initialization:
```gdscript
var _debug_building_upgrades_module: DebugBuildingUpgradesModule

func _ready() -> void:
    # ... other init code ...
    _debug_building_upgrades_module = DebugBuildingUpgradesModule.new()
    _debug_building_upgrades_module.setup(BuildingUpgradeCore)
```

### 4. DebugSpawnMenu.gd (MODIFIED)
**Location:** `scripts/ui/debug/DebugSpawnMenu.gd`

Added E/R to Keybindings documentation (F10 menu → Keybindings section):
```
[E] - Unlock all AVAILABLE upgrades
[R] - Unlock ALL upgrades in game (~193)
```

---

## Console Output

### Example: E key (Available upgrades)
```
======================================================================
[DebugBuildingUpgrades] AVAILABLE UPGRADES UNLOCKED
======================================================================
Total buildings processed: 61
Total upgrades unlocked: 15

  academy_of_nature       : 2 upgrades (academy_of_nature:0, academy_of_nature:1)
  peasants_hut            : 1 upgrade (peasants_hut:0)
  ... (other buildings)
======================================================================
```

### Example: R key (All upgrades)
```
======================================================================
[DebugBuildingUpgrades] ALL UPGRADES IN GAME UNLOCKED
======================================================================
Total buildings processed: 61
Total upgrades unlocked: 128

  academy_of_fire         : 3 upgrades (academy_of_fire:0, academy_of_fire:1, academy_of_fire:2)
  academy_of_lightning    : 3 upgrades (...)
  ... (all 61 buildings)
======================================================================
```

---

## Technical Notes

### Architecture
- Module is separate from GameScene monolith (follows extraction rule)
- Only depends on BuildingPresentationData and BuildingUpgradeCore
- No side effects beyond upgrade unlocking
- Logging is optional (for debugging)

### Building Data Source
Uses `BuildingPresentationData.DATA` constant which contains canonical upgrade definitions:
```gdscript
{
    "building_id": {
        "description": "...",
        "upgrades": [
            {"name": "...", "desc": "..."},
            {"name": "...", "desc": "..."},
            ...
        ]
    },
    ...
}
```

### Upgrade Naming Convention
Format: `building_id:upgrade_index`
- Example: `academy_of_nature:0`, `academy_of_nature:1`, `academy_of_nature:2`
- Indices are 0-based, match array positions in BuildingPresentationData

### Release Safety
Code is wrapped in `if not _scene.release_mode_enabled:` check in GameSceneInputController.
In release mode:
- Hotkeys are non-functional
- Module is initialized but never invoked
- Zero performance impact

---

## Testing Checklist

- [ ] F10 opens debug menu, shows E/R in Keybindings section
- [ ] E key unlocks only unavailable upgrades
- [ ] E key output shows correct counts
- [ ] R key unlocks all 193 upgrades
- [ ] R key output shows all 61 buildings
- [ ] Console output formatting is correct
- [ ] Works only in debug mode (not in release)
- [ ] Input is properly consumed (set_input_as_handled)
- [ ] No crashes on multiple E/R presses
- [ ] Building upgrade UI reflects changes after unlock

---

## Future Enhancements (Optional)

1. Add undo/reset functionality
2. Per-building selective unlock (UI buttons in F11)
3. Track unlock history/statistics
4. Export unlock report to JSON
5. Hotkey configuration via F10 menu

