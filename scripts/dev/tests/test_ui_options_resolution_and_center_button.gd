extends SceneTree

const OptionsMenuScene := preload("res://scenes/ui/settings/OptionsMenu.tscn")
const GameSpeedUIScene := preload("res://scenes/ui/hud/GameSpeedUI.tscn")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var options_menu := OptionsMenuScene.instantiate() as OptionsMenu
	if options_menu == null:
		push_error("[test_ui_options_resolution_and_center_button] failed to instantiate OptionsMenu")
		quit(1)
		return

	var resolution_slider := options_menu.get_node_or_null("MainPanel/VBoxContainer/ResolutionSlider") as OptionsSlider
	if resolution_slider == null:
		push_error("[test_ui_options_resolution_and_center_button] ResolutionSlider node is missing")
		quit(1)
		return

	if resolution_slider.min_value > 60 or resolution_slider.max_value < 100:
		push_error("[test_ui_options_resolution_and_center_button] ResolutionSlider range must include 60..100")
		quit(1)
		return

	get_root().add_child(options_menu)
	await process_frame

	var game_speed_ui := GameSpeedUIScene.instantiate() as HBoxContainer
	if game_speed_ui == null:
		push_error("[test_ui_options_resolution_and_center_button] failed to instantiate GameSpeedUI")
		quit(1)
		return

	get_root().add_child(game_speed_ui)
	await process_frame

	var settings_btn := game_speed_ui.get_node_or_null("SettingsButton") as TextureButton
	if settings_btn == null:
		push_error("[test_ui_options_resolution_and_center_button] SettingsButton is missing")
		quit(1)
		return

	var vp_size := get_root().get_visible_rect().size
	var expected_center := vp_size * 0.5
	var btn_size := settings_btn.size
	if btn_size == Vector2.ZERO:
		btn_size = settings_btn.custom_minimum_size
	var btn_center := settings_btn.global_position + btn_size * 0.5

	if btn_center.distance_to(expected_center) > 3.0:
		push_error("[test_ui_options_resolution_and_center_button] SettingsButton must be centered. expected=%s actual=%s" % [expected_center, btn_center])
		quit(1)
		return

	print("[test_ui_options_resolution_and_center_button] PASS")
	quit(0)
