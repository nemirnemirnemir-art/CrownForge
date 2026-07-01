extends SceneTree

const ProphecyWaveSpawnerScript := preload("res://scripts/game_scene/modules/ProphecyWaveSpawner.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var spawner = ProphecyWaveSpawnerScript.new()
	if spawner == null:
		push_error("[test_prophecy_wave_spawner_cycle_state] failed to instantiate spawner")
		quit(1)
		return

	if not bool(spawner.call("is_intro_wave_pending")):
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 1 must start with intro wave pending")
		quit(1)
		return

	var intro_patterns: Array = spawner.call("get_intro_patterns")
	if intro_patterns.size() != 1:
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 1 intro pattern missing")
		quit(1)
		return

	spawner.call("consume_intro_wave")
	if bool(spawner.call("is_intro_wave_pending")):
		push_error("[test_prophecy_wave_spawner_cycle_state] intro wave should be consumed after opening")
		quit(1)
		return

	spawner.complete_batch()
	if int(spawner.get_prophecy_level()) != 2:
		push_error("[test_prophecy_wave_spawner_cycle_state] complete_batch must advance prophecy level to 2")
		quit(1)
		return
	if not bool(spawner.call("is_intro_wave_pending")):
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 2 must open with intro wave pending")
		quit(1)
		return

	spawner.complete_batch()
	spawner.complete_batch()
	if int(spawner.get_prophecy_level()) != 4:
		push_error("[test_prophecy_wave_spawner_cycle_state] complete_batch chain must advance prophecy level to 4")
		quit(1)
		return
	if bool(spawner.call("is_intro_wave_pending")):
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 4 must not schedule intro wave")
		quit(1)
		return

	spawner.set_queue([[{"id": "wave"}]], null, 8)
	if bool(spawner.call("has_pending_boss_wave")):
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 4 boss must not open before selected queue is exhausted")
		quit(1)
		return
	spawner.advance_wave()
	if not bool(spawner.call("has_pending_boss_wave")):
		push_error("[test_prophecy_wave_spawner_cycle_state] prophecy 4 must schedule final boss after selected waves")
		quit(1)
		return

	print("[test_prophecy_wave_spawner_cycle_state] PASS")
	quit(0)
