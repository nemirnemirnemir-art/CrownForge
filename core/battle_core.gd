extends Node
## BattleCore - Autoload singleton (no class_name needed)

const API_VERSION := 1

## Constants
const MOBS_PER_WAVE: int = 10

## State
var _active_mobs: Array = []
var _wave_number: int = 0
var _is_wave_active: bool = false
var _wave_timer: float = 0.0

## === PUBLIC API ===

func get_active_mobs() -> Array:
    return _active_mobs

func is_wave_active() -> bool:
    return _is_wave_active

func get_wave_timer() -> float:
    return _wave_timer

func start_wave() -> void:
    # Only start wave if GameScene is active
    var tree = Engine.get_main_loop()
    if tree is SceneTree:
        var current_scene = tree.current_scene
        if not current_scene or not current_scene.is_in_group("game_scene"):
            return
    
    _wave_number += 1
    _is_wave_active = true
    # DO NOT CLEAR active_mobs here to allow continuous spawning
    EventBus.wave_started.emit(_wave_number)

func complete_wave() -> void:
    if not _is_wave_active:
        # print("[BattleCore] ⚠️ complete_wave() called but wave is not active")
        return
    
    # print("[BattleCore] 🎉 Completing wave %d" % _wave_number)
    _is_wave_active = false
    EventBus.wave_completed.emit(_wave_number)
    
    # Note: StageCore will subscribe to wave_completed and handle stage advancement

func register_mob(mob: Node) -> void:
    if not _active_mobs.has(mob):
        _active_mobs.append(mob)

func unregister_mob(mob: Node) -> void:
    if _active_mobs.has(mob):
        _active_mobs.erase(mob)
        var mob_name: String = str(mob.name) if is_instance_valid(mob) else "INVALID"
        EventBus.enemy_killed.emit(mob_name)
        
        # print("[BattleCore] unregister_mob: %s, remaining: %d, wave_active: %s" % [mob_name, _active_mobs.size(), _is_wave_active])
        
        # Check wave completion - ONLY if GameScene is active
        if _active_mobs.is_empty() and _is_wave_active:
            # Verify GameScene is the current active scene before completing wave
            var tree = Engine.get_main_loop()
            if tree is SceneTree:
                var current_scene = tree.current_scene
                if current_scene and current_scene.is_in_group("game_scene"):
                    # print("[BattleCore] ✅ Wave complete! All enemies defeated.")
                    complete_wave()
                else:
                    # GameScene is not active
                    # Don't complete wave - just clear the wave state
                    print("[BattleCore] ⚠️ Wave would be complete, but GameScene is not active. Clearing wave state.")
                    _is_wave_active = false
                    _active_mobs.clear()

func _award_gold_for_wave() -> void:
    var stage = StageCore.get_current_stage()
    var gold = DamageCalculator.calculate_gold_reward(stage)
    EconomyCore.add_gold(gold)

@warning_ignore("UNUSED_PRIVATE_CLASS_VARIABLE")
var _food_starvation_timer: float = 0.0
const STARVATION_DURATION: float = 3.0

func _process(_delta: float) -> void:
    # Wave timer logic removed as per user request
    pass

func _handle_wave_timeout() -> void:
    # Logic removed
    pass
