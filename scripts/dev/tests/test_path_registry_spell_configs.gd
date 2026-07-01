extends SceneTree

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var shields_path := String(PathRegistryScript.resolve_spell_config_path("shields_up"))
	if shields_path == "":
		push_error("[test_path_registry_spell_configs] expected non-empty path for shields_up")
		quit(1)
		return

	if not ResourceLoader.exists(shields_path):
		push_error("[test_path_registry_spell_configs] resolved spell config path must exist: %s" % shields_path)
		quit(1)
		return

	var ids := PathRegistryScript.list_spell_config_ids(false)
	if not ids.has("shields_up"):
		push_error("[test_path_registry_spell_configs] shields_up must be listed in non-legendary pool")
		quit(1)
		return

	var legendary_ids := PathRegistryScript.list_spell_config_ids(true)
	if legendary_ids.has("shields_up"):
		push_error("[test_path_registry_spell_configs] shields_up must not be listed in legendary-only pool")
		quit(1)
		return

	print("[test_path_registry_spell_configs] PASS")
	quit(0)
