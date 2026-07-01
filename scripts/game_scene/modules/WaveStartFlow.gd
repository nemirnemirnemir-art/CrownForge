extends RefCounted
class_name WaveStartFlow


func begin_wave(wave_number: int, facade_state: Dictionary, wave_state: Dictionary, wave_timer_bar, battle_core, trader_spawner, wave_state_flow) -> void:
	if wave_timer_bar != null and wave_timer_bar.has_method("clear_wave_preview"):
		wave_timer_bar.clear_wave_preview(wave_number)

	if battle_core != null and battle_core.has_method("start_wave"):
		battle_core.start_wave()

	facade_state["current_wave"] = wave_number
	if trader_spawner != null and trader_spawner.has_method("get_post_trader_first_wave_number") and trader_spawner.has_method("set_post_trader_first_wave_number"):
		if wave_number == int(trader_spawner.get_post_trader_first_wave_number()):
			trader_spawner.set_post_trader_first_wave_number(-1)

	if wave_state_flow != null and wave_state_flow.has_method("begin_wave"):
		wave_state_flow.begin_wave(wave_state)

	facade_state["current_wave_is_intro"] = false
	facade_state["current_wave_is_prophecy"] = false
	facade_state["current_wave_is_trader"] = false
	facade_state["current_wave_is_boss"] = false
	facade_state["current_wave_is_placeholder"] = false
	facade_state["current_wave_display_number"] = 0
	facade_state["current_wave_use_prophecy_defaults"] = false
	facade_state["current_wave_open_prophecy_after_reward"] = false
	facade_state["current_wave_show_victory_after_reward"] = false
	facade_state["wave_active"] = bool(wave_state.get("wave_active", true))


func notify_wave_started(wave_number: int, wave_state_flow, wave_state: Dictionary, emit_wave_spawned: Callable, emit_wave_started_with_mobs: Callable) -> void:
	if emit_wave_spawned.is_valid():
		emit_wave_spawned.call(wave_number)

	if wave_state_flow == null or not wave_state_flow.has_method("get_current_wave_counts"):
		return

	var current_counts: Dictionary = wave_state_flow.get_current_wave_counts(wave_state)
	if current_counts.is_empty() or not emit_wave_started_with_mobs.is_valid():
		return
	emit_wave_started_with_mobs.call(wave_number, current_counts)
