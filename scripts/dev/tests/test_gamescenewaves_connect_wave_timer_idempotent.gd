extends SceneTree

const GameSceneWavesScript := preload("res://scripts/game_scene/GameSceneWaves.gd")


class FakeWaveTimer:
	extends RefCounted

	signal wave_triggered(wave_number: int)

	var paused_values: Array[bool] = []

	func set_paused(value: bool) -> void:
		paused_values.append(value)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var waves = GameSceneWavesScript.new()
	var host := Node2D.new()
	var map_container := Node2D.new()
	host.add_child(map_container)
	get_root().add_child(host)
	waves.initialize(host, map_container, Rect2())

	var timer := FakeWaveTimer.new()
	waves.connect_wave_timer(timer)
	waves.connect_wave_timer(timer)

	if timer.wave_triggered.get_connections().size() != 1:
		push_error("[test_gamescenewaves_connect_wave_timer_idempotent] wave_triggered must only have one connection")
		quit(1)
		return

	print("[test_gamescenewaves_connect_wave_timer_idempotent] PASS")
	quit(0)
