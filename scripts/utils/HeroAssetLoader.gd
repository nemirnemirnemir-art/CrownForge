extends Node
class_name HeroAssetLoader

const UnitFaceLibraryScript := preload("res://scripts/utils/UnitFaceLibrary.gd")

## Helper to load hero animations dynamically from folders
## Maps hero_id to folder structure

# Mapping: hero_id -> {folder: folder_name, prefix: subfolder_prefix}
# Mapping: hero_id -> {folder: folder_name, prefix: subfolder_prefix}
const HERO_FOLDER_MAP = {
    "slinger": {"folder": "slinger", "prefix": "slinger"},
    "hunter": {"folder": "hunter", "prefix": "hunter"},
    "archer": {"folder": "Archer", "prefix": "archer"},
    "crossbowman": {"folder": "Archer", "prefix": "archer"},
    "peasant": {"folder": "peasant", "prefix": "peasant"},
    "light_legionary": {"folder": "Light_legionary", "prefix": "l_legionary"},
    "swordsman": {"folder": "Light_legionary", "prefix": "l_legionary"},
    "light_spearman": {"folder": "Light_Spearman", "prefix": "light_spearman"},
    "militia": {"folder": "Light_Spearman", "prefix": "light_spearman"},
    "mercenary": {"folder": "Mercenary", "prefix": ""},
    "gnome": {"folder": "Mercenary", "prefix": ""}
}

const HERO_ID_ALIASES = {
    "singer": "slinger",
    "assasin": "assassin",
    "smallbones": "small_bones",
    "swordman": "swordsman",
    "clown": "madman"
}

const DIRECT_ANIMATION_FOLDER_MAP = {
    "slinger": [
        "res://assets/characters/tinyHeroes/Slinger",
        "res://assets/characters/tinyHeroes/slinger"
    ],
    "hunter": [
        "res://assets/characters/tinyHeroes/Hunter",
        "res://assets/characters/tinyHeroes/hunter"
    ],
    "madman": [
        "res://assets/characters/tinyHeroes/Madman",
        "res://assets/characters/tinyHeroes/madman"
    ],
    "clown": [
        "res://assets/characters/tinyHeroes/Madman",
        "res://assets/characters/tinyHeroes/madman"
    ],
    "black_sheep": [
        "res://assets/characters/tinyHeroes/Black_Sheep",
        "res://assets/characters/tinyHeroes/black_sheep"
    ],
    "ballista": [
        "res://assets/characters/tinyHeroes/Ballista",
        "res://assets/characters/tinyHeroes/ballista"
    ],
    "paladin": [
        "res://assets/characters/tinyHeroes/Paladin",
        "res://assets/characters/tinyHeroes/paladin"
    ],
    "paladin_mage": [
        "res://assets/characters/tinyHeroes/Paladin",
        "res://assets/characters/tinyHeroes/paladin"
    ],
	"minotaur": [
		"res://assets/characters/tinyHeroes/Minotaur",
		"res://assets/characters/tinyHeroes/minotaur"
	],
	"hydra": [
		"res://assets/characters/tinyHeroes/Hydra"
	]
}

const PLACEHOLDER_SPRITE_DIR := "res://assets/characters/unit_placeholders"
const SUMMON_PLACEHOLDER_DIR := "res://assets/characters/summons"

## === MANUAL ICON CONFIGURATION ===
## Add your custom icon paths here. This takes priority over auto-detection.
## Format: "hero_id": "res://path/to/icon.png"
const MANUAL_ICON_OVERRIDES = {
    "slinger": "res://assets/characters/faces/heroes/Slinger.png",
    "archer": "res://assets/characters/faces/heroes/Crossbowman.png",
    "crossbowman": "res://assets/characters/faces/heroes/Crossbowman.png",
    "peasant": "res://assets/characters/faces/heroes/peasant.png",
    "light_legionary": "res://assets/characters/faces/heroes/Light_Legionary.png",
    "swordsman": "res://assets/characters/faces/heroes/Light_Legionary.png",
    "light_spearman": "res://assets/characters/faces/heroes/Light_Spearman.png",
    "militia": "res://assets/characters/faces/heroes/Light_Spearman.png",
    "mercenary": "res://assets/characters/faces/heroes/Gnome.png",
    "gnome": "res://assets/characters/faces/heroes/Gnome.png",
    "hunter": "res://assets/characters/faces/heroes/Hunter.png",
    "assassin": "res://assets/characters/faces/heroes/assasin.png",
    "assasin": "res://assets/characters/faces/heroes/assasin.png",
    "bone_warrior": "res://assets/characters/faces/heroes/bone_warrior.png",
    "undead_bone_warrior": "res://assets/characters/faces/heroes/bone_warrior.png"
}

const ICON_MAP = {
    "slinger": "slinger",
    "archer": "archer",
    "crossbowman": "archer",
    "peasant": "peasant",
    "light_legionary": "light_legionary",
    "swordsman": "light_legionary",
    "light_spearman": "light_spearman",
    "militia": "light_spearman",
    "mercenary": "mercenary",
    "gnome": "mercenary",
    "hunter": "hunter",
    "assassin": "assassin",
    "assasin": "assasin"
}

static func load_hero_sprite_frames(hero_id: String) -> SpriteFrames:
    # Get base ID (strip _1, _2 suffix for clones)
    var base_id = _get_base_id(hero_id)

    if DIRECT_ANIMATION_FOLDER_MAP.has(base_id):
        var direct_paths: Array = DIRECT_ANIMATION_FOLDER_MAP[base_id]
        for candidate in direct_paths:
            var direct_path := String(candidate)
            var direct_frames := _load_direct_folder_frames(direct_path)
            if direct_frames != null:
                return direct_frames

    var placeholder_frames := _load_placeholder_frames(base_id)
    if placeholder_frames != null:
        return placeholder_frames

    var frames = SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")
    
    # Get folder config
    var config = HERO_FOLDER_MAP.get(base_id, {"folder": base_id, "prefix": base_id})
    var folder_name = String(config.get("folder", base_id))
    var prefix = String(config.get("prefix", base_id))
    var base_path = "res://assets/characters/heroes_from_website/" + folder_name

    # Define animations to look for
    var anim_map = {}
    
    if base_id == "mercenary":
        anim_map = {
            "idle": ["idle_2"],
            "walk": ["walk"],
            "attack": ["attack"]
        }
    elif base_id == "light_spearman":
        # Folder structure: light_spearman_idle, light_spearman_walk...
        # So suffix is _idle, but prefix is light_spearman
        anim_map = {
            "idle": ["_idle"],
            "walk": ["_walk"],
            "attack": ["_attack"]
        }
    elif base_id == "light_legionary":
        # Folder structure: l_legionary_idle, l_legionary_walk...
        # So suffix is _idle, but prefix is l_legionary (defined in map)
        anim_map = {
            "idle": ["_idle"],
            "walk": ["_walk"],
            "attack": ["_attack"]
        }
    elif base_id == "archer":
            # Folder structure: archer_idle, archer_walk...
        anim_map = {
            "idle": ["_idle"],
            "walk": ["_walk"],
            "attack": ["_attack"]
        }
    else:
        # Default fallback (Slinger/Peasant)
        anim_map = {
            "idle": ["_idle", "_walk", "_move"],
            "walk": ["_walk", "_move"],
            "attack": ["_attack"]
        }
    
    for anim_name in anim_map.keys():
        frames.add_animation(anim_name)
        frames.set_animation_loop(anim_name, anim_name != "attack")
        frames.set_animation_speed(anim_name, 10.0)
        
        var suffixes = anim_map[anim_name]
        var found = false
        
        for suffix in suffixes:
            var subfolder_name = prefix + suffix
            var full_path = base_path + "/" + subfolder_name
            
            var dir = DirAccess.open(full_path)
            if dir:
                found = true
                dir.list_dir_begin()
                var file_name = dir.get_next()
                var file_list = []
                
                while file_name != "":
                    if not file_name.begins_with("."):
                        if file_name.ends_with(".png"):
                            file_list.append(file_name)
                    file_name = dir.get_next()
                
                # Sort numerically
                file_list.sort_custom(func(a, b): return a.get_basename().to_int() < b.get_basename().to_int())
                
                for f in file_list:
                    var tex_path = full_path + "/" + f
                    var tex := _load_texture2d(tex_path)
                    if tex:
                        frames.add_frame(anim_name, tex)
                
                break
        
        if not found:
            # print("[HeroAssetLoader] Warning: No animation found for %s -> %s" % [hero_id, anim_name])
            pass
            
    return frames

static func _load_direct_folder_frames(base_path: String) -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")

    var has_any := false
    var anim_to_folder_candidates := {
        "idle": ["idle", "run", "walk", "move"],
        "walk": ["walk", "run", "move", "idle"],
        "attack": ["attack", "atk", "strike"]
    }

    for anim_name in anim_to_folder_candidates.keys():
        frames.add_animation(anim_name)
        frames.set_animation_loop(anim_name, anim_name != "attack")
        frames.set_animation_speed(anim_name, 12.0 if anim_name == "attack" else 10.0)

        var folder_candidates: Array = anim_to_folder_candidates[anim_name]
        for folder_name in folder_candidates:
            var folder := base_path + "/" + String(folder_name)
            var file_list := _collect_sorted_png_files(folder)
            if file_list.is_empty():
                continue
            for file_name in file_list:
                var tex := _load_texture2d(folder + "/" + file_name)
                if tex:
                    frames.add_frame(anim_name, tex)
                    has_any = true
            break

    _copy_animation_if_missing(frames, "idle", "walk", true)
    _copy_animation_if_missing(frames, "walk", "idle", true)
    _copy_animation_if_missing(frames, "attack", "walk", false)

    if not has_any:
        return null
    return frames

static func has_placeholder_sprite(hero_id: String) -> bool:
    return _get_placeholder_sprite_path(hero_id) != ""

static func _get_placeholder_sprite_path(hero_id: String) -> String:
    var base_id := _get_base_id(hero_id)
    if base_id == "":
        return ""

    var candidate := "%s/%s.png" % [PLACEHOLDER_SPRITE_DIR, base_id]
    if ResourceLoader.exists(candidate) or FileAccess.file_exists(candidate):
        return candidate

    var summon_candidate := "%s/%s/%s.png" % [SUMMON_PLACEHOLDER_DIR, base_id, base_id]
    if ResourceLoader.exists(summon_candidate) or FileAccess.file_exists(summon_candidate):
        return summon_candidate
    return ""

static func _load_placeholder_frames(hero_id: String) -> SpriteFrames:
    var sprite_path := _get_placeholder_sprite_path(hero_id)
    if sprite_path == "":
        return null

    var tex := _load_texture2d(sprite_path)
    if tex == null:
        return null

    return _build_single_texture_frames(tex)

static func _build_single_texture_frames(tex: Texture2D) -> SpriteFrames:
    var frames := SpriteFrames.new()
    if frames.has_animation("default"):
        frames.remove_animation("default")

    var animation_names := ["idle", "walk", "attack"]
    for anim_name in animation_names:
        frames.add_animation(anim_name)
        frames.set_animation_loop(anim_name, anim_name != "attack")
        frames.set_animation_speed(anim_name, 8.0)
        for _i in range(4):
            frames.add_frame(anim_name, tex)

    return frames

static func _copy_animation_if_missing(frames: SpriteFrames, target_animation: String, source_animation: String, should_loop: bool) -> void:
    if not frames.has_animation(target_animation):
        return
    if not frames.has_animation(source_animation):
        return
    if frames.get_frame_count(target_animation) > 0:
        return

    var source_count := frames.get_frame_count(source_animation)
    if source_count <= 0:
        return

    for i in range(source_count):
        var tex := frames.get_frame_texture(source_animation, i)
        if tex:
            frames.add_frame(target_animation, tex, frames.get_frame_duration(source_animation, i))

    frames.set_animation_loop(target_animation, should_loop)

static func _collect_sorted_png_files(folder_path: String) -> Array[String]:
    var files: Array[String] = []
    var dir := DirAccess.open(folder_path)
    if dir == null:
        return files

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
            files.append(file_name)
        file_name = dir.get_next()
    dir.list_dir_end()

    files.sort_custom(func(a: String, b: String):
        var a_num := a.get_basename().to_int()
        var b_num := b.get_basename().to_int()
        if a_num == b_num:
            return a < b
        return a_num < b_num
    )
    return files

static func _load_texture2d(resource_path: String) -> Texture2D:
    var import_meta_path := "%s.import" % resource_path
    if ResourceLoader.exists(import_meta_path):
        var imported := load(resource_path) as Texture2D
        if imported:
            return imported

    var fs_path := ProjectSettings.globalize_path(resource_path)
    if not FileAccess.file_exists(fs_path):
        return null

    var image := Image.new()
    var err := image.load(fs_path)
    if err != OK:
        return null

    return ImageTexture.create_from_image(image)

static func get_hero_icon_path(hero_id: String) -> String:
    if MANUAL_ICON_OVERRIDES.has(hero_id):
        return MANUAL_ICON_OVERRIDES[hero_id]
        
    var base_id = _get_base_id(hero_id)
    if MANUAL_ICON_OVERRIDES.has(base_id):
        return MANUAL_ICON_OVERRIDES[base_id]

    var face_path := UnitFaceLibraryScript.get_face_path(base_id)
    if face_path != "":
        return face_path

    var placeholder_icon := _get_placeholder_sprite_path(base_id)
    if placeholder_icon != "":
        return placeholder_icon

    return UnitFaceLibraryScript.PLACEHOLDER_FACE_PATH

static func get_hero_card_path(hero_id: String) -> String:
    var base_id = _get_base_id(hero_id)
    # Capitalize first letter for card filename
    var _card_name = base_id.capitalize()
    # Fallback to icon if specific card art not found
    return get_hero_icon_path(hero_id)

static func _get_base_id(hero_id: String) -> String:
    var normalized_id := String(hero_id).strip_edges().to_lower()
    if normalized_id == "":
        return normalized_id
    # Check if it ends with _N pattern (clone)
    var parts = normalized_id.rsplit("_", true, 1)
    if parts.size() == 2 and parts[1].is_valid_int():
        normalized_id = String(parts[0])

    if HERO_ID_ALIASES.has(normalized_id):
        normalized_id = String(HERO_ID_ALIASES[normalized_id])

    return normalized_id
