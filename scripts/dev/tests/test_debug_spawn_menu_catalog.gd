extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var script = load("res://scripts/ui/debug/DebugSpawnMenu.gd")
	if script == null:
		push_error("[test_debug_spawn_menu_catalog] failed to load DebugSpawnMenu.gd")
		quit(1)
		return

	var catalog_script = load("res://scripts/ui/debug/modules/DebugSpawnMenuCatalog.gd")
	if catalog_script == null:
		push_error("[test_debug_spawn_menu_catalog] failed to load DebugSpawnMenuCatalog.gd")
		quit(1)
		return

	if catalog_script.MOB_SCENES.size() == 0:
		push_error("[test_debug_spawn_menu_catalog] MOB_SCENES is empty")
		quit(1)
		return

	if catalog_script.SPELL_CONFIGS.size() == 0:
		push_error("[test_debug_spawn_menu_catalog] SPELL_CONFIGS is empty")
		quit(1)
		return

	var resolver_script = load("res://scripts/ui/debug/modules/DebugHeroIdResolver.gd")
	if resolver_script == null:
		push_error("[test_debug_spawn_menu_catalog] failed to load DebugHeroIdResolver.gd")
		quit(1)
		return

	var actions_script = load("res://scripts/ui/debug/modules/DebugSpawnActions.gd")
	if actions_script == null:
		push_error("[test_debug_spawn_menu_catalog] failed to load DebugSpawnActions.gd")
		quit(1)
		return

	print("[test_debug_spawn_menu_catalog] PASS")
	quit(0)
