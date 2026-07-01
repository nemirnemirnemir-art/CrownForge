extends SceneTree

const TARGET_PATHS := {
	"res://scripts/ui/hud/WaveEnemyHUD.gd": ["EventBus"],
	"res://scripts/game_scene/GameSceneStages.gd": ["StageCore"],
	"res://scripts/game_scene/GameSceneDebug.gd": ["StageCore", "HeroCore", "EconomyCore", "ResourceCore", "CastleCore"],
	"res://scripts/game_scene/GameSceneSignals.gd": ["EventBus", "HeroCore"],
	"res://scripts/game_scene/GameScenePauseState.gd": ["TickManager"],
	"res://scripts/ui/overlays/HomeseekerArrivalOverlay.gd": ["TickManager"],
	"res://scripts/ui/overlays/MinotaurArrivalOverlay.gd": ["TickManager"],
}

var _failed: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for script_path in TARGET_PATHS.keys():
		_validate_script(script_path, TARGET_PATHS[script_path])

	if _failed > 0:
		quit(1)
		return

	print("[test_ui_gamescene_safe_singleton_preload_paths] PASS")
	quit(0)


func _validate_script(script_path: String, singleton_names: Array) -> void:
	var script_res := load(script_path) as Script
	if script_res == null:
		_fail("failed to load script: %s" % script_path)
		return

	var source: String = script_res.source_code
	for singleton_name_variant in singleton_names:
		var singleton_name := String(singleton_name_variant)
		if source.find("%s." % singleton_name) >= 0:
			_fail("%s still contains bare %s access" % [script_path, singleton_name])
		if source.find("if %s" % singleton_name) >= 0:
			_fail("%s still contains bare %s truthiness check" % [script_path, singleton_name])
		if source.find("if not %s" % singleton_name) >= 0:
			_fail("%s still contains bare negated %s truthiness check" % [script_path, singleton_name])
		if source.find("or %s" % singleton_name) >= 0:
			_fail("%s still contains bare %s boolean expression" % [script_path, singleton_name])
		if source.find("or not %s" % singleton_name) >= 0:
			_fail("%s still contains bare negated %s boolean expression" % [script_path, singleton_name])
		if source.find("and %s" % singleton_name) >= 0:
			_fail("%s still contains bare %s boolean expression" % [script_path, singleton_name])
		if source.find("and not %s" % singleton_name) >= 0:
			_fail("%s still contains bare negated %s boolean expression" % [script_path, singleton_name])


func _fail(message: String) -> void:
	_failed += 1
	push_error("[test_ui_gamescene_safe_singleton_preload_paths] FAIL: %s" % message)
