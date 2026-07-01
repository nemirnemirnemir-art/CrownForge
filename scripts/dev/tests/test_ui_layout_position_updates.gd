extends SceneTree

const GameSceneScene := preload("res://scenes/game/GameScene.tscn")
const MapLayoutScene := preload("res://scenes/map/MapLayout.tscn")

const EXPECTED_UI_BG_POS := Vector2(1180.0, 864.0)
const EXPECTED_BUILDING_MENU_TOP := 797.0
const EXPECTED_BUILDING_MENU_BOTTOM := 1127.0
const EXPECTED_CLOSE_BTN_LEFT := -24.0
const EXPECTED_CLOSE_BTN_TOP := -76.0
const EXPECTED_CLOSE_BTN_RIGHT := 60.0
const EXPECTED_CLOSE_BTN_BOTTOM := 8.0
const EXPECTED_SLOT0_POS := Vector2(97.0, -6.0)
const EXPECTED_WALL_POS_X := 493.0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var game_scene := GameSceneScene.instantiate()
	if game_scene == null:
		push_error("[test_ui_layout_position_updates] failed to instantiate GameScene")
		quit(1)
		return

	var ui_bg := game_scene.get_node_or_null("UI_main_background") as Sprite2D
	if ui_bg == null:
		push_error("[test_ui_layout_position_updates] UI_main_background not found")
		quit(1)
		return
	if ui_bg.position.distance_to(EXPECTED_UI_BG_POS) > 0.01:
		push_error("[test_ui_layout_position_updates] expected UI_main_background at %s, got %s" % [EXPECTED_UI_BG_POS, ui_bg.position])
		quit(1)
		return

	var building_menu := game_scene.get_node_or_null("UILayer/BuildingMenu") as Control
	if building_menu == null:
		push_error("[test_ui_layout_position_updates] BuildingMenu not found")
		quit(1)
		return
	if absf(building_menu.offset_top - EXPECTED_BUILDING_MENU_TOP) > 0.01:
		push_error("[test_ui_layout_position_updates] BuildingMenu offset_top mismatch: expected %.1f, got %.1f" % [EXPECTED_BUILDING_MENU_TOP, building_menu.offset_top])
		quit(1)
		return
	if absf(building_menu.offset_bottom - EXPECTED_BUILDING_MENU_BOTTOM) > 0.01:
		push_error("[test_ui_layout_position_updates] BuildingMenu offset_bottom mismatch: expected %.1f, got %.1f" % [EXPECTED_BUILDING_MENU_BOTTOM, building_menu.offset_bottom])
		quit(1)
		return

	var hero_bar := game_scene.get_node_or_null("UILayer/HeroBar") as Control
	if hero_bar == null:
		push_error("[test_ui_layout_position_updates] HeroBar not found")
		quit(1)
		return
	var hero_bar_bg := hero_bar.get_node_or_null("Background") as ColorRect
	if hero_bar_bg == null:
		push_error("[test_ui_layout_position_updates] HeroBar Background node not found")
		quit(1)
		return
	if hero_bar_bg.visible:
		push_error("[test_ui_layout_position_updates] HeroBar Background must be hidden")
		quit(1)
		return

	var hero_card := game_scene.get_node_or_null("UILayer/HeroCard") as Control
	if hero_card == null:
		push_error("[test_ui_layout_position_updates] HeroCard not found")
		quit(1)
		return
	var close_btn := hero_card.get_node_or_null("MainContainer/RightPanel/HeaderContainer/CloseButton") as TextureButton
	if close_btn == null:
		push_error("[test_ui_layout_position_updates] HeroCard CloseButton not found")
		quit(1)
		return
	if absf(close_btn.offset_left - EXPECTED_CLOSE_BTN_LEFT) > 0.01 or \
		absf(close_btn.offset_top - EXPECTED_CLOSE_BTN_TOP) > 0.01 or \
		absf(close_btn.offset_right - EXPECTED_CLOSE_BTN_RIGHT) > 0.01 or \
		absf(close_btn.offset_bottom - EXPECTED_CLOSE_BTN_BOTTOM) > 0.01:
		push_error("[test_ui_layout_position_updates] HeroCard CloseButton offsets mismatch")
		quit(1)
		return

	var map_layout := MapLayoutScene.instantiate() as MapLayout
	if map_layout == null:
		push_error("[test_ui_layout_position_updates] failed to instantiate MapLayout")
		quit(1)
		return
	get_root().add_child(map_layout)
	await process_frame

	var slot0 := map_layout.get_node_or_null("BuildSlot0") as Node2D
	if slot0 == null:
		push_error("[test_ui_layout_position_updates] BuildSlot0 not found")
		quit(1)
		return
	if slot0.position.distance_to(EXPECTED_SLOT0_POS) > 0.01:
		push_error("[test_ui_layout_position_updates] BuildSlot0 expected %s, got %s" % [EXPECTED_SLOT0_POS, slot0.position])
		quit(1)
		return

	var wall := map_layout.get_node_or_null("Wall") as Node2D
	if wall == null:
		push_error("[test_ui_layout_position_updates] Wall not found in MapLayout")
		quit(1)
		return
	if absf(wall.position.x - EXPECTED_WALL_POS_X) > 0.01:
		push_error("[test_ui_layout_position_updates] Wall X expected %.1f, got %.1f" % [EXPECTED_WALL_POS_X, wall.position.x])
		quit(1)
		return

	print("[test_ui_layout_position_updates] PASS")
	quit(0)
