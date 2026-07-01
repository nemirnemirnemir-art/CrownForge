extends RefCounted
class_name HeroSceneRegistry

const HERO_SCENE_DIR := "res://scenes/heroes"

const UNIT_ID_ALIASES := {
    "assasin": "assassin",
    "smallbones": "small_bones",
    "swordman": "swordsman",
    "clown": "madman",
    "undead_bone_warrior": "bone_warrior",
    "familiar": "small_bones",
    "infernals": "infernal_general",
    "mega_militia": "militia",
}

static func resolve_unit_id(hero_id: String) -> String:
    var unit_id := String(hero_id).strip_edges().to_lower()
    if unit_id == "":
        return ""

    if unit_id.contains("_"):
        var parts := unit_id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            unit_id = String(parts[0])

    if UNIT_ID_ALIASES.has(unit_id):
        unit_id = String(UNIT_ID_ALIASES[unit_id])

    return unit_id

static func get_scene_path(hero_id: String) -> String:
    var unit_id := resolve_unit_id(hero_id)
    if unit_id == "":
        return ""

    var path := "%s/%s.tscn" % [HERO_SCENE_DIR, unit_id]
    if ResourceLoader.exists(path):
        return path
    return ""

static func has_scene(hero_id: String) -> bool:
    return get_scene_path(hero_id) != ""

static func load_scene(hero_id: String) -> PackedScene:
    var path := get_scene_path(hero_id)
    if path == "":
        return null
    return load(path) as PackedScene

static func get_registered_unit_ids() -> Array[String]:
    var ids: Array[String] = []
    var dir := DirAccess.open(HERO_SCENE_DIR)
    if dir == null:
        return ids

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".tscn"):
            ids.append(file_name.get_basename().to_lower())
        file_name = dir.get_next()
    dir.list_dir_end()

    ids.sort()
    return ids
