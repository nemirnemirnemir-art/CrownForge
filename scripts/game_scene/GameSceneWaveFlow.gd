extends RefCounted
class_name GameSceneWaveFlow

var _host = null
var _waves_manager = null
var _wave_reward_menu = null
var _open_prophecy_menu: Callable = Callable()
var _pending_open_prophecy: bool = false
var _pending_show_victory: bool = false
var _waves_paused_before_reward_open: bool = false


func _debug_log(context: String, extra: Dictionary = {}) -> void:
	var waves_paused: Variant = null
	if _waves_manager and _waves_manager.has_method("is_paused"):
		waves_paused = _waves_manager.is_paused()
	print("[WaveFlow][DEBUG] %s | pending_open_prophecy=%s paused_before_reward=%s waves_paused=%s extra=%s" % [
		context,
		str(_pending_open_prophecy),
		str(_waves_paused_before_reward_open),
		str(waves_paused),
		str(extra),
	])


func initialize(host, waves_manager, wave_reward_menu, open_prophecy_menu: Callable) -> void:
	_host = host
	_waves_manager = waves_manager
	_wave_reward_menu = wave_reward_menu
	_open_prophecy_menu = open_prophecy_menu


func consume_pending_open_prophecy() -> bool:
	if not _pending_open_prophecy:
		return false
	_pending_open_prophecy = false
	return true


func request_victory_after_reward_close() -> void:
	_pending_show_victory = true


func on_wave_completed(wave_number: int) -> void:
	_debug_log("on_wave_completed:enter", {"wave_number": wave_number})
	if _waves_manager and _waves_manager.has_method("is_paused"):
		_waves_paused_before_reward_open = bool(_waves_manager.is_paused())
	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(true)

	if wave_number == 0:
		_pending_open_prophecy = true

	var use_prophecy_defaults := wave_number == 0
	if _waves_manager and _waves_manager.has_method("consume_use_prophecy_defaults_flag"):
		use_prophecy_defaults = use_prophecy_defaults or bool(_waves_manager.consume_use_prophecy_defaults_flag())
	if _waves_manager and _waves_manager.has_method("consume_open_prophecy_after_reward_flag"):
		_pending_open_prophecy = _pending_open_prophecy or bool(_waves_manager.consume_open_prophecy_after_reward_flag())
	if _waves_manager and _waves_manager.has_method("consume_victory_after_reward_flag"):
		_pending_show_victory = _pending_show_victory or bool(_waves_manager.consume_victory_after_reward_flag())

	if _wave_reward_menu == null:
		return

	var rewards: Array = []
	var prophecy_level: int = 1
	if _waves_manager and _waves_manager.has_method("get_current_wave_rewards"):
		rewards = _waves_manager.get_current_wave_rewards()
	if _waves_manager and _waves_manager.has_method("get_prophecy_level"):
		prophecy_level = int(_waves_manager.get_prophecy_level())
	_debug_log("on_wave_completed:open_reward", {"wave_number": wave_number, "prophecy_level": prophecy_level, "reward_count": rewards.size()})
	_wave_reward_menu.open(rewards, prophecy_level, use_prophecy_defaults)


func on_wave_reward_menu_closed() -> void:
	_debug_log("on_wave_reward_menu_closed:enter")
	if _pending_show_victory:
		_pending_show_victory = false
		if _waves_manager and _waves_manager.has_method("set_paused"):
			_waves_manager.set_paused(true)
		if _host != null and _host.has_method("show_prophecy_victory"):
			_host.show_prophecy_victory()
		_debug_log("on_wave_reward_menu_closed:show_victory")
		return
	if _pending_open_prophecy:
		_pending_open_prophecy = false
		if _waves_manager and _waves_manager.has_method("set_paused"):
			_waves_manager.set_paused(_waves_paused_before_reward_open)
		_debug_log("on_wave_reward_menu_closed:open_prophecy")
		if _open_prophecy_menu.is_valid():
			_open_prophecy_menu.call()
		return
	if _waves_manager and _waves_manager.has_method("set_paused"):
		_waves_manager.set_paused(_waves_paused_before_reward_open)
	_debug_log("on_wave_reward_menu_closed:resume_done")


func on_prophecy_batch_finished() -> void:
	_pending_open_prophecy = true
	_debug_log("on_prophecy_batch_finished")
