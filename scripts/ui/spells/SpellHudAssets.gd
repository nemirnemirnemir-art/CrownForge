class_name SpellHudAssets
extends RefCounted

const PLACEHOLDER_DIR := "res://assets/ui/spells/placeholders"
const ACTIVE_PLACEHOLDER_PATH := "%s/active_block.png" % PLACEHOLDER_DIR
const PASSIVE_PLACEHOLDER_PATH := "%s/passive_block.png" % PLACEHOLDER_DIR
const FALLBACK_PLACEHOLDER_PATH := "res://assets/ui/craft_panel/block_inventory.png"

static func ensure_placeholders() -> void:
	return

static func get_active_placeholder() -> Texture2D:
	ensure_placeholders()
	return _load_texture_or_fallback(ACTIVE_PLACEHOLDER_PATH)

static func get_passive_placeholder() -> Texture2D:
	ensure_placeholders()
	return _load_texture_or_fallback(PASSIVE_PLACEHOLDER_PATH)

static func _load_texture_or_fallback(path: String) -> Texture2D:
	var texture := _try_load_texture(path)
	if texture != null:
		return texture
	return _try_load_texture(FALLBACK_PLACEHOLDER_PATH)

static func _try_load_texture(path: String) -> Texture2D:
	if not _file_exists(path):
		return null
	var imported := load(path) as Texture2D
	if imported != null:
		return imported
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	return ImageTexture.create_from_image(image)

static func _file_exists(path: String) -> bool:
	return FileAccess.file_exists(ProjectSettings.globalize_path(path))
