extends RefCounted
class_name ArtifactRuntimeShellFlow


func connect_event_bus(event_bus, on_enemy_killed: Callable, on_wave_started: Callable, on_hero_died: Callable, on_game_loaded: Callable) -> void:
	if event_bus == null:
		return
	if not event_bus.enemy_killed.is_connected(on_enemy_killed):
		event_bus.enemy_killed.connect(on_enemy_killed)
	if not event_bus.wave_started.is_connected(on_wave_started):
		event_bus.wave_started.connect(on_wave_started)
	if not event_bus.hero_died.is_connected(on_hero_died):
		event_bus.hero_died.connect(on_hero_died)
	if not event_bus.game_loaded.is_connected(on_game_loaded):
		event_bus.game_loaded.connect(on_game_loaded)
