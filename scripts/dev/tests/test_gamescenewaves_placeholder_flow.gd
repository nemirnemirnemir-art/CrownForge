extends SceneTree

const PlaceholderFlowScript := preload("res://scripts/game_scene/modules/WavePlaceholderFlow.gd")


class FakePattern:
	extends RefCounted

	var mob_1_id: String = "goblin_bandit"
	var mob_1_count: int = 2
	var mob_2_enabled: bool = false
	var mob_2_id: String = ""
	var mob_2_count: int = 0


class FakeGenerator:
	extends RefCounted

	var patterns: Array = []

	func setup(_rng, _patterns_to_spawn: int, _level: int) -> void:
		pass

	func generate_pattern(_level: int):
		if patterns.is_empty():
			return null
		return patterns.pop_front()


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = PlaceholderFlowScript.new()
	if flow == null:
		push_error("[test_gamescenewaves_placeholder_flow] failed to instantiate helper")
		quit(1)
		return

	var spawned_calls: Array = []
	var pattern := FakePattern.new()
	var gen := FakeGenerator.new()
	gen.patterns = [pattern]

	var result: int = flow.spawn_placeholder_wave(
		4,
		3,
		gen,
		func(enemy_id: String, count: int, track: bool) -> int:
			spawned_calls.append([enemy_id, count, track])
			return count,
		func(wave_number: int, track: bool) -> int:
			spawned_calls.append(["fallback", wave_number, track])
			return 5,
		true
	)
	if result != 2 or spawned_calls.size() != 1:
		push_error("[test_gamescenewaves_placeholder_flow] generated placeholder wave mismatch")
		quit(1)
		return

	spawned_calls.clear()
	result = flow.spawn_placeholder_wave(6, 2, null, func(_a, _b, _c) -> int: return 0, func(wave_number: int, track: bool) -> int:
		spawned_calls.append([wave_number, track])
		return 6, true)
	if result != 6 or spawned_calls.is_empty():
		push_error("[test_gamescenewaves_placeholder_flow] fallback placeholder mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_placeholder_flow] PASS")
	quit(0)
