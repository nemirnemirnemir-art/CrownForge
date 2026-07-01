extends SceneTree

const SkillsPanelIconCacheScript := preload("res://scripts/ui/hud/skills_panel/SkillsPanelIconCache.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var cache: SkillsPanelIconCache = SkillsPanelIconCacheScript.new()
	if cache == null:
		push_error("[test_skillspanel_icon_cache] failed to instantiate cache")
		quit(1)
		return

	# Nonexistent skill ID returns null (no file at that path)
	var result: Texture2D = cache.get_icon(999)
	if result != null:
		push_error("[test_skillspanel_icon_cache] expected null for missing skill 999, got texture")
		quit(1)
		return

	# Second call for same missing ID returns same null (cached)
	var result2: Texture2D = cache.get_icon(999)
	if result2 != null:
		push_error("[test_skillspanel_icon_cache] cached null should remain null on second call")
		quit(1)
		return

	# Cache hit: calling same ID twice should return identical object
	var hit1: Texture2D = cache.get_icon(1)
	var hit2: Texture2D = cache.get_icon(1)
	if hit1 != hit2:
		push_error("[test_skillspanel_icon_cache] cache should return same Texture2D instance for same skill ID")
		quit(1)
		return

	print("[test_skillspanel_icon_cache] PASS")
	quit(0)
