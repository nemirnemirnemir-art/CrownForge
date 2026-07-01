extends Node

const SETTINGS_PATH := "user://game_settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_UI := "ui"
const KEY_MUSIC_VOLUME := "music_volume"
const KEY_SFX_VOLUME := "sfx_volume"
const KEY_DAMAGE_NUMBERS_ENABLED := "damage_numbers_enabled"
const KEY_DAMAGE_NUMBERS_CUSTOMIZED := "damage_numbers_customized"
const KEY_DAMAGE_FLASH_ENABLED := "damage_flash_enabled"
const KEY_PAUSE_AFTER_PROPHECY := "pause_after_prophecy"

var _music_volume: int = 50
var _sfx_volume: int = 50
var _damage_numbers_enabled: bool = true
var _damage_numbers_customized: bool = false
var _damage_flash_enabled: bool = false
var _pause_after_prophecy: bool = true

func _ready() -> void:
	_load_settings()

func get_music_volume() -> int:
	return _music_volume

func set_music_volume(value: int) -> void:
	_music_volume = clampi(value, 0, 100)
	_save_settings()

func get_sfx_volume() -> int:
	return _sfx_volume

func set_sfx_volume(value: int) -> void:
	_sfx_volume = clampi(value, 0, 100)
	_save_settings()

func is_damage_numbers_enabled() -> bool:
	return _damage_numbers_enabled

func set_damage_numbers_enabled(enabled: bool) -> void:
	_damage_numbers_enabled = enabled
	_damage_numbers_customized = true
	_save_settings()

func is_damage_flash_enabled() -> bool:
	return _damage_flash_enabled

func set_damage_flash_enabled(enabled: bool) -> void:
	_damage_flash_enabled = enabled
	_save_settings()

func is_pause_after_prophecy_enabled() -> bool:
	return _pause_after_prophecy

func set_pause_after_prophecy_enabled(enabled: bool) -> void:
	_pause_after_prophecy = enabled
	_save_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		return
	_music_volume = clampi(int(config.get_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, _music_volume)), 0, 100)
	_sfx_volume = clampi(int(config.get_value(SECTION_AUDIO, KEY_SFX_VOLUME, _sfx_volume)), 0, 100)
	_damage_numbers_customized = bool(config.get_value(SECTION_UI, KEY_DAMAGE_NUMBERS_CUSTOMIZED, false))
	if _damage_numbers_customized:
		_damage_numbers_enabled = bool(config.get_value(SECTION_UI, KEY_DAMAGE_NUMBERS_ENABLED, _damage_numbers_enabled))
	else:
		_damage_numbers_enabled = true
	_damage_flash_enabled = bool(config.get_value(SECTION_UI, KEY_DAMAGE_FLASH_ENABLED, _damage_flash_enabled))
	_pause_after_prophecy = bool(config.get_value(SECTION_UI, KEY_PAUSE_AFTER_PROPHECY, _pause_after_prophecy))

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, KEY_MUSIC_VOLUME, _music_volume)
	config.set_value(SECTION_AUDIO, KEY_SFX_VOLUME, _sfx_volume)
	config.set_value(SECTION_UI, KEY_DAMAGE_NUMBERS_ENABLED, _damage_numbers_enabled)
	config.set_value(SECTION_UI, KEY_DAMAGE_NUMBERS_CUSTOMIZED, _damage_numbers_customized)
	config.set_value(SECTION_UI, KEY_DAMAGE_FLASH_ENABLED, _damage_flash_enabled)
	config.set_value(SECTION_UI, KEY_PAUSE_AFTER_PROPHECY, _pause_after_prophecy)
	config.save(SETTINGS_PATH)
