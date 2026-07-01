extends SceneTree

const GameSceneWavesScript := preload("res://scripts/game_scene/GameSceneWaves.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var waves = GameSceneWavesScript.new()
	var game_scene := Node2D.new()
	var parent := Node2D.new()
	get_root().add_child(parent)
	parent.add_child(game_scene)

	waves.initialize(game_scene, Node2D.new(), Rect2())
	parent.remove_child(game_scene)
	await process_frame

	var singleton = waves.call("_get_singleton", "BattleCore")
	if singleton != null:
		push_error("[test_gamescenewaves_safe_singleton_lookup] expected null singleton lookup after scene leaves tree")
		quit(1)
		return

	print("[test_gamescenewaves_safe_singleton_lookup] PASS")
	quit(0)
