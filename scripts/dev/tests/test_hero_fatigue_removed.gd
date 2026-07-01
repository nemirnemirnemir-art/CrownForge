extends SceneTree

const HERO_BATTLE_PATH := "res://core/hero/HeroBattle.gd"
const HERO_CORE_PATH := "res://core/hero_core.gd"
const HERO_BAR_PATH := "res://scripts/hero/bar/HeroBarDisplay.gd"
const HERO_BAR_LEGACY_PATH := "res://scripts/hero/legacy/HeroBarDisplay.gd"

var _failed: bool = false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_hero_fatigue_removed] %s" % message)
	quit(1)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		_fail("Missing file: %s" % path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Unable to open file: %s" % path)
		return ""
	return file.get_as_text()


func _require_not_contains(haystack: String, needle: String, reason: String) -> bool:
	if haystack.find(needle) != -1:
		_fail(reason)
		return false
	return true


func _init() -> void:
	var hero_battle_text := _read_text(HERO_BATTLE_PATH)
	if not _require_not_contains(hero_battle_text, "is_tired", "HeroBattle must no longer filter tired heroes"):
		return
	if not _require_not_contains(hero_battle_text, "add_fatigue", "HeroBattle must no longer apply fatigue after battles"):
		return
	if not _require_not_contains(hero_battle_text, "rest_hero", "HeroBattle must no longer rest heroes as a fatigue mechanic"):
		return

	var hero_core_text := _read_text(HERO_CORE_PATH)
	if not _require_not_contains(hero_core_text, "hero_fatigue_changed", "HeroCore must not expose fatigue signal anymore"):
		return
	if not _require_not_contains(hero_core_text, "func add_fatigue", "HeroCore must not expose add_fatigue API anymore"):
		return
	if not _require_not_contains(hero_core_text, "func rest_hero", "HeroCore must not expose rest_hero API anymore"):
		return

	var hero_bar_text := _read_text(HERO_BAR_PATH)
	if not _require_not_contains(hero_bar_text, "zz.png", "HeroBarDisplay must not show the Zz icon anymore"):
		return
	if not _require_not_contains(hero_bar_text, "is_hero_tired", "HeroBarDisplay must not query fatigue state anymore"):
		return

	var hero_bar_legacy_text := _read_text(HERO_BAR_LEGACY_PATH)
	if not _require_not_contains(hero_bar_legacy_text, "zz.png", "Legacy HeroBarDisplay must not show the Zz icon anymore"):
		return
	if not _require_not_contains(hero_bar_legacy_text, "is_tired", "Legacy HeroBarDisplay must not depend on tired state anymore"):
		return

	print("[test_hero_fatigue_removed] PASS")
	quit(0)
