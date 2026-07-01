extends SceneTree

const ProphecyWaveSpawnerScript := preload("res://scripts/game_scene/modules/ProphecyWaveSpawner.gd")


class FakeTraderSpawner:
	extends RefCounted

	var setup_calls: Array = []

	func setup_trader_cycle(prophecy_level: int, current_wave: int, queue_size: int) -> void:
		setup_calls.append([prophecy_level, current_wave, queue_size])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var spawner = ProphecyWaveSpawnerScript.new()
	if spawner == null:
		push_error("[test_gamescenewaves_prophecy_wave_spawner_state] failed to instantiate helper")
		quit(1)
		return

	if not spawner.is_selection_pending():
		push_error("[test_gamescenewaves_prophecy_wave_spawner_state] initial selection pending mismatch")
		quit(1)
		return
	if spawner.get_display_index() != 0:
		push_error("[test_gamescenewaves_prophecy_wave_spawner_state] initial display index mismatch")
		quit(1)
		return

	var trader_spawner := FakeTraderSpawner.new()
	spawner.set_queue([[{"id": "wave"}]], trader_spawner, 5)

	if spawner.is_selection_pending():
		push_error("[test_gamescenewaves_prophecy_wave_spawner_state] queue selection pending mismatch")
		quit(1)
		return
	if spawner.get_display_index() != 0:
		push_error("[test_gamescenewaves_prophecy_wave_spawner_state] display index should reset on queue set")
		quit(1)
		return

	print("[test_gamescenewaves_prophecy_wave_spawner_state] PASS")
	quit(0)
