extends SceneTree

func _settings_path() -> String:
	return ProjectSettings.globalize_path("user://game_settings.cfg")

func _delete_settings_file() -> void:
	if FileAccess.file_exists(_settings_path()):
		DirAccess.remove_absolute(_settings_path())

func _init() -> void:
	var settings_script: Script = load("res://core/game_settings.gd") as Script
	_delete_settings_file()
	var settings: Node = settings_script.new()
	settings._load_settings()
	assert(settings.is_damage_numbers_enabled() == true)
	assert(settings.is_damage_flash_enabled() == false)
	assert(settings.is_pause_after_prophecy_enabled() == true)
	settings.set_damage_numbers_enabled(false)
	settings._load_settings()
	assert(settings.is_damage_numbers_enabled() == false)
	settings.set_damage_numbers_enabled(true)
	settings.set_damage_flash_enabled(true)
	settings.set_pause_after_prophecy_enabled(false)
	settings._load_settings()
	assert(settings.is_damage_numbers_enabled() == true)
	assert(settings.is_damage_flash_enabled() == true)
	assert(settings.is_pause_after_prophecy_enabled() == false)
	_delete_settings_file()
	print("[test_game_settings_flags] PASS")
	quit()
