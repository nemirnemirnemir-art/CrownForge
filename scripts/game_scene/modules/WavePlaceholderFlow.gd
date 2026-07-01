extends RefCounted
class_name WavePlaceholderFlow


func spawn_placeholder_wave(wave_number: int, prophecy_level: int, generator, spawn_enemy: Callable, fallback: Callable, track_for_wave: bool = true) -> int:
	var level: int = clampi(prophecy_level, 1, 7)
	var patterns_to_spawn: int = clampi(1 + int(wave_number / 4), 1, 2)
	if generator == null:
		return fallback.call(wave_number, track_for_wave) if fallback.is_valid() else 0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if generator.has_method("setup"):
		generator.setup(rng, patterns_to_spawn, level)
	var spawned: int = 0
	for i in range(patterns_to_spawn):
		var pattern = generator.generate_pattern(level)
		if pattern == null:
			continue
		if spawn_enemy.is_valid():
			spawned += int(spawn_enemy.call(String(pattern.mob_1_id), int(pattern.mob_1_count), track_for_wave))
			if bool(pattern.mob_2_enabled) and String(pattern.mob_2_id) != "":
				spawned += int(spawn_enemy.call(String(pattern.mob_2_id), int(pattern.mob_2_count), track_for_wave))
	if spawned <= 0:
		return fallback.call(wave_number, track_for_wave) if fallback.is_valid() else 0
	return spawned
