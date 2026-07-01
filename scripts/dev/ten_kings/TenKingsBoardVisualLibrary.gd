class_name TenKingsBoardVisualLibrary
extends RefCounted

const CardLib = preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

const _BUILDING_PATHS := {
	CardLib.CARD_CASTLE: "res://assets/takefromthis/on_field/Castle_Blue.png",
	CardLib.CARD_SCOUT_TOWER: "res://assets/takefromthis/on_field/Tower_Blue.png",
	CardLib.CARD_FARM: "res://assets/takefromthis/on_field/House_Blue.png",
	CardLib.CARD_BLACKSMITH: "res://assets/takefromthis/on_field/Blacksmith.png",
}

const _TROOP_FRAME_PATHS := {
	CardLib.CARD_SOLDIER: [
		"res://assets/takefromthis/on_field/idle/soldier/1.png",
		"res://assets/takefromthis/on_field/idle/soldier/2.png",
		"res://assets/takefromthis/on_field/idle/soldier/3.png",
		"res://assets/takefromthis/on_field/idle/soldier/4.png",
		"res://assets/takefromthis/on_field/idle/soldier/5.png",
		"res://assets/takefromthis/on_field/idle/soldier/6.png",
		"res://assets/takefromthis/on_field/idle/soldier/7.png",
		"res://assets/takefromthis/on_field/idle/soldier/8.png",
	],
	CardLib.CARD_ARCHER: [
		"res://assets/takefromthis/on_field/idle/archer/1.png",
		"res://assets/takefromthis/on_field/idle/archer/2.png",
		"res://assets/takefromthis/on_field/idle/archer/3.png",
		"res://assets/takefromthis/on_field/idle/archer/4.png",
		"res://assets/takefromthis/on_field/idle/archer/5.png",
		"res://assets/takefromthis/on_field/idle/archer/6.png",
	],
	CardLib.CARD_PALADIN: [
		"res://assets/takefromthis/on_field/idle/paladin/idle/1.png",
		"res://assets/takefromthis/on_field/idle/paladin/idle/2.png",
		"res://assets/takefromthis/on_field/idle/paladin/idle/3.png",
	],
}

var _building_cache: Dictionary = {}
var _troop_cache: Dictionary = {}


func get_building_texture(card_id: StringName, _side: int = 0) -> Texture2D:
	if _building_cache.has(card_id):
		return _building_cache[card_id] as Texture2D
	var path: String = String(_BUILDING_PATHS.get(card_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	_building_cache[card_id] = texture
	return texture


func get_troop_frames(card_id: StringName, _side: int = 0) -> Array[Texture2D]:
	if _troop_cache.has(card_id):
		return (_troop_cache[card_id] as Array[Texture2D]).duplicate()
	var result: Array[Texture2D] = []
	var frame_paths: Array = _TROOP_FRAME_PATHS.get(card_id, [])
	for frame_path_value: Variant in frame_paths:
		var frame_path: String = String(frame_path_value)
		if not ResourceLoader.exists(frame_path):
			continue
		var texture := load(frame_path) as Texture2D
		if texture != null:
			result.append(texture)
	_troop_cache[card_id] = result
	return result.duplicate()
