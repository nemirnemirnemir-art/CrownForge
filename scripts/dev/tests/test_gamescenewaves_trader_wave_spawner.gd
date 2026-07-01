extends SceneTree

const TraderWaveSpawnerScript := preload("res://scripts/game_scene/modules/TraderWaveSpawner.gd")


class FakePattern:
	extends RefCounted

	var mob_1_id: String = "goblin_shaman"
	var mob_1_count: int = 2
	var mob_2_enabled: bool = false
	var mob_2_id: String = ""
	var mob_2_count: int = 0


class SpawnRecorder:
	extends RefCounted

	var prophecy_calls: Array = []
	var fallback_calls: Array = []

	func spawn_prophecy(patterns: Array, track_for_wave: bool) -> int:
		prophecy_calls.append([patterns.size(), track_for_wave])
		return 3

	func spawn_fallback(enemy_id: String, count: int, track_for_wave: bool) -> int:
		fallback_calls.append([enemy_id, count, track_for_wave])
		return 4


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var spawner = TraderWaveSpawnerScript.new()
	if spawner == null:
		push_error("[test_gamescenewaves_trader_wave_spawner] failed to instantiate helper")
		quit(1)
		return

	spawner.setup_trader_cycle(1, 3, 2)
	_assert_single_pattern(spawner.get_patterns(), "goblin_bandit", 1, "goblin_crossbowman", 1, "prophecy 1 trader")

	spawner.setup_trader_cycle(2, 6, 2)
	_assert_single_pattern(spawner.get_patterns(), "goblin_bandit", 3, "goblin_fire_mage", 1, "prophecy 2 trader")

	spawner.setup_trader_cycle(3, 9, 2)
	_assert_single_pattern(spawner.get_patterns(), "stone_golem", 2, "", 0, "prophecy 3 trader")

	var recorder := SpawnRecorder.new()
	var rewards: Array = []
	var wave_state: Dictionary = {"current_wave_rewards": []}

	spawner._trader_patterns = [FakePattern.new()]
	var spawned: int = spawner.spawn_wave(
		rewards,
		wave_state,
		Callable(recorder, "spawn_prophecy"),
		Callable(recorder, "spawn_fallback")
	)
	if spawned != 3 or recorder.prophecy_calls.size() != 1 or recorder.fallback_calls.size() != 0:
		push_error("[test_gamescenewaves_trader_wave_spawner] prophecy spawn branch mismatch")
		quit(1)
		return
	if rewards.size() != 1 or wave_state["current_wave_rewards"].size() != 1:
		push_error("[test_gamescenewaves_trader_wave_spawner] trader reward append mismatch")
		quit(1)
		return

	rewards.clear()
	wave_state["current_wave_rewards"] = []
	spawner._trader_patterns = []
	spawned = spawner.spawn_wave(
		rewards,
		wave_state,
		Callable(recorder, "spawn_prophecy"),
		Callable(recorder, "spawn_fallback")
	)
	if spawned != 4 or recorder.fallback_calls.size() != 1:
		push_error("[test_gamescenewaves_trader_wave_spawner] fallback spawn branch mismatch")
		quit(1)
		return

	print("[test_gamescenewaves_trader_wave_spawner] PASS")
	quit(0)


func _assert_single_pattern(patterns: Array, mob_1_id: String, mob_1_count: int, mob_2_id: String, mob_2_count: int, context: String) -> void:
	if patterns.size() != 1:
		push_error("[test_gamescenewaves_trader_wave_spawner] %s must have exactly one pattern, got %d" % [context, patterns.size()])
		quit(1)
		return
	var pattern = patterns[0]
	if pattern == null:
		push_error("[test_gamescenewaves_trader_wave_spawner] %s pattern is null" % context)
		quit(1)
		return
	if String(pattern.mob_1_id) != mob_1_id or int(pattern.mob_1_count) != mob_1_count:
		push_error("[test_gamescenewaves_trader_wave_spawner] %s mob_1 mismatch" % context)
		quit(1)
		return
	var expected_mob_2_enabled := mob_2_id != "" and mob_2_count > 0
	if bool(pattern.mob_2_enabled) != expected_mob_2_enabled:
		push_error("[test_gamescenewaves_trader_wave_spawner] %s mob_2_enabled mismatch" % context)
		quit(1)
		return
	if expected_mob_2_enabled and (String(pattern.mob_2_id) != mob_2_id or int(pattern.mob_2_count) != mob_2_count):
		push_error("[test_gamescenewaves_trader_wave_spawner] %s mob_2 mismatch" % context)
		quit(1)
