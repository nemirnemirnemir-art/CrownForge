extends SceneTree

const RunnerScript := preload("res://scripts/dev/qa/mechanics/magic_damage/MagicDamageRunner.gd")

var _failed := false


class LiveMapLayout:
	extends Node

	var slots: Array = []


class LiveGameScene:
	extends Node

	var map_layout_node: Node = null

	func _ready() -> void:
		add_to_group("game_scene")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_magic_damage_runner] %s" % message)
	quit(1)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var live_scene := LiveGameScene.new()
	live_scene.map_layout_node = LiveMapLayout.new()
	get_root().add_child(live_scene)
	await process_frame

	var active_result := RunnerScript.run_scenario("magic_ball_active")
	if String(active_result.get("status", "")) != "PASS":
		_fail("magic_ball_active must pass, got %s (%s)" % [active_result.get("status", ""), active_result.get("reason", "")])
		return

	var upgraded_result := RunnerScript.run_scenario("magic_ball_upgraded")
	if String(upgraded_result.get("status", "")) != "PASS":
		_fail("magic_ball_upgraded must pass, got %s (%s)" % [upgraded_result.get("status", ""), upgraded_result.get("reason", "")])
		return

	var combo_result := RunnerScript.run_scenario("full_combo")
	if String(combo_result.get("status", "")) != "PASS":
		_fail("full_combo must pass, got %s (%s)" % [combo_result.get("status", ""), combo_result.get("reason", "")])
		return

	print("[test_magic_damage_runner] PASS")
	quit(0)
