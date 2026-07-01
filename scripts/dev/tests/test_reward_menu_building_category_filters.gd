extends SceneTree

const MENU_SCRIPT_PATH := "res://scripts/ui/rewards/RewardMenuBaseProduction.gd"
const WAVE_MENU_SCRIPT_PATH := "res://scripts/ui/rewards/WaveRewardMenu.gd"
const GAME_SCENE_SCRIPT_PATH := "res://scripts/game/GameScene.gd"
const GAME_SCENE_TSCN_PATH := "res://scenes/game/GameScene.tscn"
const BUILDING_REGISTRY_TSCN_PATH := "res://core/buildings/BuildingRegistry.tscn"

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_reward_menu_building_category_filters] %s" % message)
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


func _init() -> void:
	var menu_script := _read_text(MENU_SCRIPT_PATH)
	if not _require_contains(menu_script, "@export var building_category", "RewardMenuBaseProduction must expose building_category export"):
		return
	if not _require_contains(menu_script, "get_buildings_by_category", "RewardMenuBaseProduction must build pool by category"):
		return
	if not _require_contains(menu_script, "building_category", "RewardMenuBaseProduction must use category variable"):
		return

	var wave_menu_script := _read_text(WAVE_MENU_SCRIPT_PATH)
	if not _require_contains(wave_menu_script, "\"production_established\"", "WaveRewardMenu must handle established production rewards"):
		return
	if not _require_contains(wave_menu_script, "_open_submenu(\"production_established\")", "WaveRewardMenu must open established production submenu"):
		return
	if not _require_contains(wave_menu_script, "_open_submenu(\"infrastructure\")", "WaveRewardMenu must open infrastructure submenu"):
		return

	var game_scene_script := _read_text(GAME_SCENE_SCRIPT_PATH)
	if not _require_contains(game_scene_script, "open_reward_menu_established_production", "GameScene must expose established production opener"):
		return
	if not _require_contains(game_scene_script, "open_reward_menu_kingdom_infrastructure", "GameScene must expose kingdom infrastructure opener"):
		return

	var game_scene_tscn := _read_text(GAME_SCENE_TSCN_PATH)
	if not _require_contains(game_scene_tscn, "RewardMenuEstablishedProduction", "GameScene.tscn must include established production reward menu node"):
		return
	if not _require_contains(game_scene_tscn, "RewardMenuKingdomInfrastructure", "GameScene.tscn must include kingdom infrastructure reward menu node"):
		return

	var registry_tscn := _read_text(BUILDING_REGISTRY_TSCN_PATH)
	if not _require_contains(registry_tscn, "buddhist_temple.tres", "BuildingRegistry must include buddhist_temple config"):
		return

	print("[test_reward_menu_building_category_filters] PASS")
	quit(0)
