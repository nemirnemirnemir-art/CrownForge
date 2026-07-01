extends SceneTree

const GameSceneInputControllerScript := preload("res://scripts/game_scene/GameSceneInputController.gd")


class FakeDebugManager:
	extends RefCounted

	func handle_input(_event: InputEvent) -> void:
		pass


class FakeScene:
	extends Node

	var release_mode_enabled: bool = true
	var town_menu_open_count: int = 0
	var _debug_manager := FakeDebugManager.new()
	var _debug_building_upgrades_module = null
	var building_menu = null

	func open_town_menu() -> void:
		town_menu_open_count += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene := FakeScene.new()
	get_root().add_child(scene)

	var ui_root := Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(ui_root)

	var line_edit := LineEdit.new()
	line_edit.custom_minimum_size = Vector2(200.0, 30.0)
	ui_root.add_child(line_edit)

	var controller := GameSceneInputControllerScript.new()
	controller.initialize(scene)

	line_edit.grab_focus()
	await process_frame

	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.echo = false
	key_event.keycode = KEY_G

	controller.handle_input(key_event)
	if scene.town_menu_open_count != 0:
		push_error("[test_game_scene_input_controller_text_focus] KEY_G must not open town menu while LineEdit is focused")
		quit(1)
		return

	line_edit.release_focus()
	await process_frame

	controller.handle_input(key_event)
	if scene.town_menu_open_count != 1:
		push_error("[test_game_scene_input_controller_text_focus] KEY_G must open town menu when no text input is focused")
		quit(1)
		return

	print("[test_game_scene_input_controller_text_focus] PASS")
	quit(0)
