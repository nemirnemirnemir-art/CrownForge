extends RefCounted
class_name UnitFaceLibrary

const HERO_FACES_DIR := "res://assets/characters/faces/heroes/"
const MOB_FACE_HINTS := {
    "goblinbandit": "res://assets/characters/enemies/tinyEnemies/goblin/walk/Torch_Red.png",
    "blueslime": "res://assets/characters/enemies/tinyEnemies/slime/Thief_Slime.png",
    "goblincrossbowman": "res://assets/characters/enemies/tinyEnemies/arrowman/Goblin_Archer.png",
    "goblinswordsman": "res://assets/characters/enemies/tinyEnemies/goblin_warrior/Goblin_Warrior.png",
    "goblinshaman": "res://assets/characters/enemies/tinyEnemies/lightingmag/Shaman.png",
    "goblinfiremage": "res://assets/characters/enemies/tinyEnemies/firemag/Fire_Mage.png",
    "goblinlightningmage": "res://assets/characters/enemies/tinyEnemies/lightingmag/Shaman.png",
    "goblinlizard": "res://assets/characters/enemies/tinyEnemies/lizard/Lizard.png",
    "goblingiant": "res://assets/characters/enemies/tinyEnemies/golem/PaddleFish.png",
    "wallbuster": "res://assets/characters/enemies/tinyEnemies/wallbuster/Barrel_Purple.png",
    "goblinbatrider": "res://assets/characters/enemies/tinyEnemies/bat/Bat_Rider.png",
    "goblinpig": "res://assets/characters/enemies/tinyEnemies/pig/Pig.png",
    "crabrider": "res://assets/characters/enemies/tinyEnemies/crab/Crab_Rider.png",
    "stonegolem": "res://assets/characters/enemies/tinyEnemies/golem/PaddleFish.png",
    "sunfaced": "res://assets/characters/enemies/tinyEnemies/Sunface/Bear.png",
    "gnoll": "res://assets/characters/enemies/tinyEnemies/gnoll/Gnoll.png",
    "dragon": "res://assets/characters/bosses/dragon/drakewalk/1.png",
    "homeseekerboss": "res://assets/characters/bosses/homeseeker/Troll_Idle.png",
    "minotaurboss": "res://assets/characters/bosses/minotaur/Minotaur_walk/1.png",
}
const PLACEHOLDER_FACE_PATH := "res://assets/ui/buttons/button_close.png"

const FACE_NAME_ALIASES := {
    "swordsman": ["swordman", "light_legionary"],
    "light_legionary": ["light legionary", "swordsman", "swordman"],
    "healer_mage": ["healer mage"],
    "small_bones": ["small_bones"],
    "assassin": ["assasin"],
    "crossbowman": ["crossbowman"],
    "gnome": ["gnome"],
    "slinger": ["slinger"],
    "peasant": ["peasant"],
    "light_spearman": ["light_spearman"],
    "goose_rider": ["goose_rider"],
    "ballista": ["balista"],
    "lightning_mage": ["lighting_mage"],
    "minotaur": ["minoutaur"],
    "musketeer": ["mushketer"],
    "black_swordsman": ["black_swordman"],
    "pangolin": ["pangoling"],
    "familiar": ["familliar"],
    "rider": ["rider"],
    "white_unicorn": ["white unicorn"],
    "ram": ["ram"],
}

static var _hero_face_files_by_lower: Dictionary = {}
static var _hero_face_files_loaded: bool = false
static var _placeholder_face: Texture2D = null

static func get_face_texture(unit_id: String, display_name: String = "", fallback: Texture2D = null) -> Texture2D:
    var path := get_face_path(unit_id, display_name)
    if path != "" and ResourceLoader.exists(path):
        return load(path) as Texture2D
    var placeholder := get_placeholder_face_texture()
    if fallback != null:
        return fallback
    if placeholder != null:
        return placeholder
    return fallback

static func get_mob_face_texture(mob_id: String, fallback: Texture2D = null) -> Texture2D:
    var path := get_mob_face_path(mob_id)
    if path != "" and ResourceLoader.exists(path):
        return load(path) as Texture2D
    if fallback != null:
        return fallback
    return get_placeholder_face_texture()

static func get_placeholder_face_texture() -> Texture2D:
    if _placeholder_face == null and ResourceLoader.exists(PLACEHOLDER_FACE_PATH):
        _placeholder_face = load(PLACEHOLDER_FACE_PATH) as Texture2D
    return _placeholder_face

static func get_face_path(unit_id: String, display_name: String = "") -> String:
    _ensure_hero_face_cache()
    for candidate in _build_candidates(unit_id, display_name):
        var candidate_lower := candidate.to_lower()
        if _hero_face_files_by_lower.has(candidate_lower):
            return HERO_FACES_DIR + String(_hero_face_files_by_lower[candidate_lower])
    return ""

static func get_mob_face_path(mob_id: String) -> String:
    var normalized := String(mob_id).strip_edges().to_lower().replace("_", "")
    if MOB_FACE_HINTS.has(normalized):
        var path := String(MOB_FACE_HINTS[normalized])
        if ResourceLoader.exists(path):
            return path
    return ""

static var _building_candidates: bool = false

static func _build_candidates(unit_id: String, display_name: String) -> Array[String]:
    # Prevent re-entrancy that could cause stack overflow
    if _building_candidates:
        return []
    _building_candidates = true
    
    var normalized_id := String(unit_id).strip_edges().to_lower()
    var normalized_display := String(display_name).strip_edges().to_lower()
    var candidates: Array[String] = []

    _append_candidate(candidates, normalized_display)
    _append_candidate(candidates, normalized_display.replace(" ", "_"))
    _append_candidate(candidates, normalized_id)
    _append_candidate(candidates, normalized_id.replace("_", " "))

    if FACE_NAME_ALIASES.has(normalized_id):
        for alias_value in FACE_NAME_ALIASES[normalized_id]:
            var alias := String(alias_value).to_lower()
            _append_candidate(candidates, alias)
            _append_candidate(candidates, alias.replace(" ", "_"))
            # Limit candidates to prevent excessive iterations
            if candidates.size() >= 20:
                break

    _building_candidates = false
    return candidates

static func _ensure_hero_face_cache() -> void:
    if _hero_face_files_loaded:
        return
    _hero_face_files_loaded = true
    _hero_face_files_by_lower.clear()
    var dir := DirAccess.open(HERO_FACES_DIR)
    if dir == null:
        return
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
            _hero_face_files_by_lower[file_name.to_lower().get_basename()] = file_name
        file_name = dir.get_next()
    dir.list_dir_end()

static func _append_candidate(candidates: Array[String], value: String) -> void:
    var trimmed := value.strip_edges()
    if trimmed == "":
        return
    if candidates.has(trimmed):
        return
    candidates.append(trimmed)
