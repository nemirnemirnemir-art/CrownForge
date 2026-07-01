extends SceneTree

const GAME_SCENE_PATH := "res://scripts/game/GameScene.gd"
const WAVE_REWARD_MENU_PATH := "res://scripts/ui/rewards/WaveRewardMenu.gd"
const MAP_SLOT_PATH := "res://scripts/map/MapSlot.gd"
const GAME_SPEED_UI_PATH := "res://scripts/ui/hud/GameSpeedUI.gd"

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_mine_visual_and_runtime_guards] %s" % message)
	quit(1)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing file: %s" % path)
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_fail("Unable to open file: %s" % path)
		return ""
	return f.get_as_text()


func _require_contains(haystack: String, needle: String, reason: String) -> bool:
	if haystack.find(needle) == -1:
		_fail(reason)
		return false
	return true


func _require_not_contains(haystack: String, needle: String, reason: String) -> bool:
	if haystack.find(needle) != -1:
		_fail(reason)
		return false
	return true


func _init() -> void:
	var game_scene_text := _read_text(GAME_SCENE_PATH)
	if not _require_contains(game_scene_text, "func _on_enemies_cleared()", "GameScene must keep _on_enemies_cleared"):
		return
	if not _require_contains(game_scene_text, "if not is_inside_tree():", "GameScene._on_enemies_cleared must guard detached node"):
		return

	var wave_menu_text := _read_text(WAVE_REWARD_MENU_PATH)
	if not _require_contains(wave_menu_text, "func _debug_dump_state", "WaveRewardMenu must keep debug dump helper"):
		return
	if not _require_contains(wave_menu_text, "if is_inside_tree():", "WaveRewardMenu._debug_dump_state must guard tree access"):
		return

	var map_slot_text := _read_text(MAP_SLOT_PATH)
	if not _require_contains(map_slot_text, "const MINE_VISUALS", "MapSlot must define mine active/inactive visuals"):
		return
	if not _require_contains(map_slot_text, "const MINE_ACTIVE_ROTATION_DEGREES", "MapSlot must define active mine wobble rotation"):
		return
	if not _require_contains(map_slot_text, "_update_active_mine_animation", "MapSlot must animate active mines"):
		return
	if not _require_contains(map_slot_text, "_apply_mine_visual_state", "MapSlot must switch mine active/inactive textures"):
		return
	if not _require_contains(map_slot_text, "buddhist_temple", "MapSlot must special-case buddhist_temple scale"):
		return

	var game_speed_text := _read_text(GAME_SPEED_UI_PATH)
	if not _require_contains(game_speed_text, "_settings_button.global_position =", "GameSpeedUI must position settings button explicitly"):
		return
	if not _require_not_contains(game_speed_text, "visible_rect.position + visible_rect.size * 0.5", "GameSpeedUI settings button must not stay at screen center"):
		return

	print("[test_mine_visual_and_runtime_guards] PASS")
	quit(0)
