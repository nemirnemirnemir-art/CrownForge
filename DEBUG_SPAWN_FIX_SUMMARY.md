# Debug Mob Spawning Bug Fix

## Problem
- Debug spawn buttons (F10 menu) создают мобов через прямой `instantiate()` вместо использования waves manager
- Это вызывало неправильный setup:
  - Мобы спавнились напрямую в замок, а не в область респа портала
  - `behavior_target_type` был установлен на `"bridge"` вместо `"wall"`
  - Не использовались правильные spawn markers
- Рабочий spawnпуть (wave/prophecy/profession) работал корректно через `WaveSpawnService`

## Root Cause
1. `DebugSpawnActions.on_spawn_mob()` делал `scene.instantiate()` и вручную ставил позицию
2. Неправильно устанавливал `behavior_target_type = "bridge"` (должно быть `"wall"`)
3. По контрасту, `WaveSpawnService.spawn_mob_scene()` всё делал правильно

## Solution Implemented

### 1. Added public debug API in GameScene (scripts/game/GameScene.gd:150-163)
```gdscript
func debug_spawn_enemy_id(enemy_id: String, count: int = 1) -> int:
    if _waves_manager:
        var spawned = _waves_manager.debug_spawn_enemy_id(enemy_id, count)
        print("[GameScene] Debug spawn %s x%d -> %d" % [enemy_id, count, spawned])
        return spawned
    else:
        push_warning("[GameScene] Waves manager not ready, cannot spawn %s" % enemy_id)
        return 0
```
- Delegates to waves manager (uses same path as prophecy/wave spawn)
- Ensures proper portal area spawning and mob setup

### 2. Updated DebugSpawnActions (scripts/ui/debug/modules/DebugSpawnActions.gd:118-139)
```gdscript
func on_spawn_mob(mob_name: String) -> void:
    if not _ensure_game_scene():
        return
    
    var enemy_id := _map_display_name_to_enemy_id(mob_name)
    if enemy_id == "":
        push_error("[DebugSpawnMenu] Unknown mob name: %s" % mob_name)
        return
    
    # Delegate to game_scene which uses waves manager
    if game_scene.has_method("debug_spawn_enemy_id"):
        var spawned = game_scene.debug_spawn_enemy_id(enemy_id, 1)
        print("[DebugSpawnActions] Spawned %s (id=%s) via waves manager: %d mobs" % [mob_name, enemy_id, spawned])
    else:
        push_error("[DebugSpawnActions] GameScene missing debug_spawn_enemy_id method")
```
- Removed direct `instantiate()` and manual position setting
- Maps display names (GoblinBandit) to enemy_id (goblin_bandit)
- Uses new `debug_spawn_enemy_id()` API

### 3. Added ID mapping function in DebugSpawnActions
```gdscript
func _map_display_name_to_enemy_id(display_name: String) -> String:
    var name_map := {
        "GoblinBandit": "goblin_bandit",
        "BlueSlime": "blue_slime",
        "GoblinCrossbowman": "goblin_crossbowman",
        ...
    }
    return name_map.get(display_name, "")
```
- Ensures consistency with MobSceneRegistry IDs
- Handles all mobs from DebugSpawnMenuCatalog

## Files Changed
1. `scripts/game/GameScene.gd` - Added `debug_spawn_enemy_id()` method
2. `scripts/ui/debug/modules/DebugSpawnActions.gd` - Refactored `on_spawn_mob()` and added `_map_display_name_to_enemy_id()`

## Tests Added
1. `scripts/dev/tests/test_debug_spawn_mob_via_waves_manager.gd` - Verifies spawns use portal area
2. `scripts/dev/tests/test_debug_spawn_actions_delegation.gd` - Verifies delegation to game_scene

## Verification Steps
1. Open debug menu (F10)
2. Click any mob Spawn button (e.g., GoblinBandit, WallBuster, Dragon)
3. Verify mob appears in ring around portal (right side of screen), NOT inside castle
4. Verify mobs move toward wall correctly
5. Check console logs show: `[GameScene] Debug spawn goblin_bandit x1 -> 1`
6. Compare with profession/wave spawn - should behave identically

## Technical Details
- Mobs from portal should have `behavior_target_type = "wall"` (set by WaveSpawnService:42)
- Mobs get random spawn position from ring of spawn markers
- Mobs get correct `assault_lane_y`, `bridge_position`, `portal_position`
- Portal spawn area uses markers created by MapLayout around portal center + offset
- This ensures all spawn paths (debug, wave, prophecy) are consistent
