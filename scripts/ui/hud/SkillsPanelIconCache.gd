class_name SkillsPanelIconCache

## Lazy-loads and caches skill textures by index.

const ICON_PATH_PATTERN := "res://assets/gameplay/skills/%d.png"

var _cache: Dictionary = {}

func get_icon(skill_index: int) -> Texture2D:
	if _cache.has(skill_index):
		return _cache[skill_index]
	var path := ICON_PATH_PATTERN % skill_index
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		if texture != null:
			_cache[skill_index] = texture
			return texture
	_cache[skill_index] = null
	return null
