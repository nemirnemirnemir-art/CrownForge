extends RefCounted
class_name UnitTraitLibrary

const TRAITS_DOC_PATH := "res://docs/unit_traits.txt"
const DOC_NAME_ALIASES := {
    "crossbowman": ["Crossbowman"],
    "assassin": ["Assassin"],
    "black_sheep": ["Black Sheep"],
    "small_bones": ["Small Bones"],
    "gnome": ["Gnome"],
    "hunter": ["Hunter"],
    "madman": ["Madman", "Clown"],
    "militia": ["Militia"],
    "peasant": ["Peasant"],
    "slinger": ["Slinger"],
    "black_swordsman": ["Black Swordsman"],
    "swordsman": ["Swordsman", "Swordman"],
    "whipman": ["Whipman"],
}

static var _doc_lines: Array[String] = []
static var _loaded: bool = false
static var _png_regex: RegEx = null
static var _punct_regex: RegEx = null
static var _space_regex: RegEx = null

static func get_trait_text(unit_id: String, cfg: Variant = null) -> String:
    _ensure_loaded()
    var resolved_unit_id := _normalize_unit_id(unit_id)
    var candidates := _build_name_candidates(resolved_unit_id, cfg)
    for candidate in candidates:
        var prefix := candidate.strip_edges()
        if prefix == "":
            continue
        var marker := prefix + " "
        for line in _doc_lines:
            if line.begins_with(marker):
                return _clean_trait_text(line.substr(marker.length(), line.length() - marker.length()))
    if cfg != null and "trait_description" in cfg:
        var fallback := _clean_trait_text(String(cfg.trait_description))
        if fallback != "":
            return fallback
    return ""

static func is_duplicate_trait_text(candidate_text: String, trait_text: String) -> bool:
    var a := normalize_trait_text(candidate_text)
    var b := normalize_trait_text(trait_text)
    if a == "" or b == "":
        return false
    return a == b or a.contains(b) or b.contains(a)

static func normalize_trait_text(text: String) -> String:
    _ensure_regexes()
    var cleaned := _clean_trait_text(text).to_lower()
    cleaned = cleaned.replace("for each", "per")
    cleaned = cleaned.replace("on the battlefield", "")
    cleaned = cleaned.replace("troops", "troop")
    cleaned = cleaned.replace("units", "unit")
    cleaned = cleaned.replace("militias", "militia")
    cleaned = cleaned.replace("madmen", "madman")
    cleaned = cleaned.replace("crossbowmen", "crossbowman")
    cleaned = cleaned.replace("swordsmen", "swordsman")
    cleaned = cleaned.replace("whipmen", "whipman")
    cleaned = _punct_regex.sub(cleaned, " ", true)
    cleaned = _space_regex.sub(cleaned, " ", true).strip_edges()
    return cleaned

static func _ensure_loaded() -> void:
    if _loaded:
        return
    _loaded = true
    _ensure_regexes()
    _doc_lines.clear()
    if not FileAccess.file_exists(TRAITS_DOC_PATH):
        return
    var file := FileAccess.open(TRAITS_DOC_PATH, FileAccess.READ)
    if file == null:
        return
    while not file.eof_reached():
        var raw_line := String(file.get_line()).strip_edges()
        if raw_line == "":
            continue
        _doc_lines.append(_clean_trait_text(raw_line))

static func _ensure_regexes() -> void:
    if _png_regex == null:
        _png_regex = RegEx.new()
        _png_regex.compile("[A-Za-z0-9_-]+\\.png")
    if _punct_regex == null:
        _punct_regex = RegEx.new()
        _punct_regex.compile("[^a-z0-9%+ ]+")
    if _space_regex == null:
        _space_regex = RegEx.new()
        _space_regex.compile("\\s+")

static func _clean_trait_text(text: String) -> String:
    _ensure_regexes()
    var cleaned := _png_regex.sub(String(text), "", true)
    cleaned = cleaned.replace("Icon-Unit-Class-", "")
    cleaned = cleaned.replace("Unit-", "")
    cleaned = _space_regex.sub(cleaned, " ", true).strip_edges()
    return cleaned

static func _build_name_candidates(unit_id: String, cfg: Variant) -> Array[String]:
    var out: Array[String] = []
    if cfg != null and "display_name" in cfg:
        _append_unique(out, String(cfg.display_name))
    if DOC_NAME_ALIASES.has(unit_id):
        for alias_name in DOC_NAME_ALIASES[unit_id]:
            _append_unique(out, String(alias_name))
    _append_unique(out, _title_case(unit_id.replace("_", " ")))
    return out

static func _append_unique(out: Array[String], value: String) -> void:
    var normalized := value.strip_edges()
    if normalized == "":
        return
    if not out.has(normalized):
        out.append(normalized)

static func _normalize_unit_id(unit_id: String) -> String:
    var id := String(unit_id).strip_edges().to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            id = String(parts[0])
    if id == "clown":
        return "madman"
    if id == "swordman":
        return "swordsman"
    if id == "assasin":
        return "assassin"
    return id

static func _title_case(text: String) -> String:
    var words := text.split(" ", false)
    for i in range(words.size()):
        var word := String(words[i]).strip_edges()
        if word == "":
            continue
        words[i] = word[0].to_upper() + word.substr(1, word.length() - 1)
    return " ".join(words)
