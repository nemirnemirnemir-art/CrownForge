extends RefCounted
class_name MainUISignalFlow

func connect_signals(event_bus, resource_core, castle_core, reset_dialog, callbacks: Dictionary) -> void:
	_connect_signal(event_bus, "gold_changed", callbacks.get("gold_changed", Callable()))
	_connect_signal(event_bus, "stars_changed", callbacks.get("stars_changed", Callable()))
	_connect_signal(event_bus, "stage_changed", callbacks.get("stage_changed", Callable()))
	_connect_signal(event_bus, "game_loaded", callbacks.get("game_loaded", Callable()))
	if event_bus and event_bus.has_signal("forge_cores_changed"):
		_connect_signal(event_bus, "forge_cores_changed", callbacks.get("forge_cores_changed", Callable()))
	if resource_core:
		_connect_signal(resource_core, "resource_changed", callbacks.get("resource_changed", Callable()))
	if castle_core:
		_connect_signal(castle_core, "game_over", callbacks.get("game_over", Callable()))
	if reset_dialog != null:
		_connect_signal(reset_dialog, "confirmed", callbacks.get("reset_confirmed", Callable()))

func _connect_signal(target, signal_name: String, callback: Callable) -> void:
	if target == null or not callback.is_valid():
		return
	if not target.has_signal(signal_name):
		return
	if not target.is_connected(signal_name, callback):
		target.connect(signal_name, callback)
