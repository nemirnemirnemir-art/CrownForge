extends SceneTree

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const DebugSpawnMenuCatalogScript := preload("res://scripts/ui/debug/modules/DebugSpawnMenuCatalog.gd")


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var failures: Array[String] = []
	var roster_ids := _build_expected_spell_roster()
	var catalog_ids := _to_string_array(DebugSpawnMenuCatalogScript.SPELL_CONFIGS)
	var config_ids := PathRegistryScript.list_spell_config_ids(false)
	var legendary_ids := PathRegistryScript.list_spell_config_ids(true)

	_assert_missing_ids(failures, "debug catalog is missing spell ids", roster_ids, catalog_ids)
	_assert_missing_ids(failures, "PathRegistry non-legendary list is missing spell ids", roster_ids, config_ids)

	var smoke_scene_paths := _load_verify_scene_paths()
	for spell_id in roster_ids:
		var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
		if config == null:
			failures.append("failed to load spell config for '%s'" % spell_id)
			continue

		if config.effect_scene == null:
			failures.append("spell '%s' is in smoke roster but has no effect_scene configured" % spell_id)
			continue

		var scene_path := String(config.effect_scene.resource_path)
		if scene_path == "":
			failures.append("spell '%s' effect_scene has empty resource_path" % spell_id)
			continue

		if not smoke_scene_paths.has(scene_path):
			failures.append("spell '%s' scene '%s' is missing from verify_scenes roster" % [spell_id, scene_path])

		var loaded_scene := load(scene_path)
		if loaded_scene == null:
			failures.append("spell '%s' scene failed to load: %s" % [spell_id, scene_path])

	for spell_id in legendary_ids:
		var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
		if config == null:
			failures.append("failed to load legendary spell config for '%s'" % spell_id)
			continue
		if config.effect_scene == null:
			continue
		var scene_path := String(config.effect_scene.resource_path)
		if scene_path == "":
			failures.append("legendary spell '%s' effect_scene has empty resource_path" % spell_id)
			continue
		if not smoke_scene_paths.has(scene_path):
			failures.append("legendary spell '%s' scene '%s' is missing from verify_scenes roster" % [spell_id, scene_path])

	if not failures.is_empty():
		for message in failures:
			push_error("[test_spell_scene_smoke_roster] %s" % message)
		quit(1)
		return

	print("[test_spell_scene_smoke_roster] PASS")
	quit(0)


func _build_expected_spell_roster() -> Array[String]:
	var expected_ids := PathRegistryScript.list_spell_config_ids(false)
	var roster: Array[String] = []
	for spell_id in expected_ids:
		var config := PathRegistryScript.load_spell_config(spell_id) as SpellConfig
		if config == null:
			continue
		if config.effect_scene == null:
			continue
		_append_unique_string(roster, spell_id)
	return roster


func _load_verify_scene_paths() -> Dictionary:
	var script := load("res://scripts/dev/verify/verify_scenes.gd") as GDScript
	var out: Dictionary = {}
	if script == null:
		return out

	var script_constants: Dictionary = script.get_script_constant_map()
	var paths: Variant = script_constants.get("SCENE_PATHS", [])
	if paths is Array:
		for raw_path in paths:
			var scene_path := String(raw_path)
			if scene_path != "":
				out[scene_path] = true
	return out


func _assert_missing_ids(failures: Array[String], label: String, expected_ids: Array[String], actual_ids: Array[String]) -> void:
	var missing_ids: Array[String] = []
	for spell_id in expected_ids:
		if actual_ids.has(spell_id):
			continue
		missing_ids.append(spell_id)
	if missing_ids.is_empty():
		return
	failures.append("%s: %s" % [label, ", ".join(missing_ids)])


func _to_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		_append_unique_string(out, String(value))
	return out


func _append_unique_string(target: Array[String], value: String) -> void:
	if value == "":
		return
	if target.has(value):
		return
	target.append(value)
