extends RefCounted
class_name SaveAutosaveFlow


func request_save(state: Dictionary, is_loading: bool, now_sec: float, debounce_sec: float) -> void:
	if is_loading:
		return
	state["save_requested"] = true
	state["save_due_time"] = now_sec + debounce_sec


func process_tick(state: Dictionary, now_sec: float, save_game: Callable) -> bool:
	if not bool(state.get("save_requested", false)):
		return false
	if now_sec < float(state.get("save_due_time", 0.0)):
		return false
	state["save_requested"] = false
	if save_game.is_valid():
		save_game.call()
	return true
