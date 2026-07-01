extends RefCounted
class_name SpecialWaveFlow


func handle_all_enemies_cleared(state: Dictionary, current_wave: int, update_previews: Callable, trader_complete: Callable, prophecy_complete: Callable, clear_previews: Callable, batch_finished: Callable, notify_game_scene: Callable) -> void:
	if bool(state.get("current_wave_is_prophecy", false)):
		if update_previews.is_valid():
			update_previews.call()
	elif bool(state.get("current_wave_is_boss", false)):
		if clear_previews.is_valid():
			clear_previews.call()
	elif bool(state.get("current_wave_is_trader", false)):
		if trader_complete.is_valid():
			trader_complete.call(current_wave)
		if prophecy_complete.is_valid():
			prophecy_complete.call()
		if update_previews.is_valid():
			update_previews.call()
		if batch_finished.is_valid():
			batch_finished.call()
	if notify_game_scene.is_valid():
		notify_game_scene.call()
