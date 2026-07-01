extends RefCounted
class_name WaveSpawnBranchFlow


## Dispatches spawn for any wave type, including wave 0.
## Returns { "spawned", "is_prophecy", "is_trader", "is_placeholder", "display_number" }.
func dispatch(wave_number: int, queue_state: Dictionary,
        spawn_wave_zero: Callable, spawn_intro: Callable, spawn_trader: Callable, spawn_prophecy: Callable, spawn_boss: Callable,
        spawn_placeholder: Callable, spawn_random: Callable) -> Dictionary:
    var result := {
        "spawned": 0,
        "is_intro": false,
        "is_prophecy": false,
        "is_trader": false,
        "is_boss": false,
        "is_placeholder": false,
        "display_number": 0,
        "use_prophecy_defaults": false,
        "open_prophecy_after_reward": false,
        "show_victory_after_reward": false,
    }
    var state := {
        "current_wave_is_intro": false,
        "current_wave_is_prophecy": false,
        "current_wave_is_trader": false,
        "current_wave_is_boss": false,
        "current_wave_is_placeholder": false,
        "current_wave_display_number": 0,
        "current_wave_use_prophecy_defaults": false,
        "current_wave_open_prophecy_after_reward": false,
        "current_wave_show_victory_after_reward": false,
    }
    if wave_number == 0:
        if bool(queue_state.get("boss_pending", false)):
            state["current_wave_is_boss"] = true
            state["current_wave_show_victory_after_reward"] = bool(queue_state.get("boss_victory", false))
            if spawn_boss.is_valid():
                result["spawned"] = int(spawn_boss.call())
            result["is_boss"] = true
            result["show_victory_after_reward"] = state["current_wave_show_victory_after_reward"]
            return result
        result["spawned"] = int(spawn_wave_zero.call()) if spawn_wave_zero.is_valid() else 0
        return result
    result["spawned"] = resolve_spawn_branch(wave_number, state, queue_state, spawn_intro, spawn_trader, spawn_prophecy, spawn_boss, spawn_placeholder, spawn_random)
    result["is_intro"] = bool(state.get("current_wave_is_intro", false))
    result["is_prophecy"] = bool(state.get("current_wave_is_prophecy", false))
    result["is_trader"] = bool(state.get("current_wave_is_trader", false))
    result["is_boss"] = bool(state.get("current_wave_is_boss", false))
    result["is_placeholder"] = bool(state.get("current_wave_is_placeholder", false))
    result["display_number"] = int(state.get("current_wave_display_number", 0))
    result["use_prophecy_defaults"] = bool(state.get("current_wave_use_prophecy_defaults", false))
    result["open_prophecy_after_reward"] = bool(state.get("current_wave_open_prophecy_after_reward", false))
    result["show_victory_after_reward"] = bool(state.get("current_wave_show_victory_after_reward", false))
    return result


func resolve_spawn_branch(wave_number: int, state: Dictionary, queue_state: Dictionary, spawn_intro: Callable, spawn_trader: Callable, spawn_prophecy: Callable, spawn_boss: Callable, spawn_placeholder: Callable, spawn_random: Callable) -> int:
    state["current_wave_is_intro"] = false
    state["current_wave_is_prophecy"] = false
    state["current_wave_is_trader"] = false
    state["current_wave_is_boss"] = false
    state["current_wave_is_placeholder"] = false
    state["current_wave_display_number"] = 0
    state["current_wave_use_prophecy_defaults"] = false
    state["current_wave_open_prophecy_after_reward"] = false
    state["current_wave_show_victory_after_reward"] = false

    if wave_number == 0:
        return 0
    if bool(queue_state.get("intro_pending", false)):
        state["current_wave_is_intro"] = true
        state["current_wave_use_prophecy_defaults"] = true
        state["current_wave_open_prophecy_after_reward"] = true
        if spawn_intro.is_valid():
            var intro_result: Variant = spawn_intro.call()
            return intro_result if intro_result is int else 0
        return 0
    if bool(queue_state.get("is_trader", false)):
        state["current_wave_is_trader"] = true
        if spawn_trader.is_valid():
            var trader_result: Variant = spawn_trader.call()
            return trader_result if trader_result is int else 0
        return 0
    if bool(queue_state.get("has_queue", false)):
        state["current_wave_is_prophecy"] = true
        state["current_wave_display_number"] = int(queue_state.get("display", 0))
        if spawn_prophecy.is_valid():
            var patterns: Array = queue_state.get("patterns", [])
            return int(spawn_prophecy.call(patterns))
        return 0
    if bool(queue_state.get("boss_pending", false)):
        state["current_wave_is_boss"] = true
        state["current_wave_show_victory_after_reward"] = bool(queue_state.get("boss_victory", false))
        if spawn_boss.is_valid():
            var boss_result: Variant = spawn_boss.call()
            return boss_result if boss_result is int else 0
        return 0
    if bool(queue_state.get("pending", false)):
        state["current_wave_is_placeholder"] = true
        if spawn_placeholder.is_valid():
            return int(spawn_placeholder.call(wave_number))
        return 0
    if spawn_random.is_valid():
        return int(spawn_random.call(wave_number))
    return 0
