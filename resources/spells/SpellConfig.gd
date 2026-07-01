class_name SpellConfig
extends Resource

## Spell configuration resource - defines spell properties and behavior

@export var spell_id: String = ""
@export var spell_name: String = ""
@export var icon: Texture2D = null
@export_multiline var description: String = ""

@export_group("Targeting")
@export var target_radius: float = 100.0  ## Visual targeting circle radius in pixels
@export var target_type: String = "area"  ## "area", "point", "self"

@export_group("Effect")
@export var effect_scene: PackedScene = null  ## Spell effect prefab to instantiate
@export var duration: float = 0.0  ## For lingering effects (seconds)
@export var damage: float = 0.0  ## Instant damage
@export var damage_per_second: float = 0.0  ## DoT (damage over time)

@export_group("Inventory")
@export var max_stacks: int = 99  ## Maximum stack count in a single slot

const SPELL_ICON_DIR := "res://assets/vfx/spells"

## Returns the icon or a generated placeholder if no icon is set
func get_icon_or_placeholder() -> Texture2D:
    if icon != null:
        return icon

    var resolved_icon := _resolve_icon_texture()
    if resolved_icon != null:
        return resolved_icon
    
    # Generate unique color based on spell_id hash
    var h = spell_id.hash()
    var hue = fmod(abs(float(h)), 360.0) / 360.0
    var color1 = Color.from_hsv(hue, 0.7, 0.9)
    var color2 = Color.from_hsv(fmod(hue + 0.15, 1.0), 0.6, 0.6)
    
    var gradient = Gradient.new()
    gradient.set_color(0, color1)
    gradient.set_color(1, color2)
    
    var tex = GradientTexture2D.new()
    tex.gradient = gradient
    tex.width = 64
    tex.height = 64
    tex.fill = GradientTexture2D.FILL_RADIAL
    tex.fill_from = Vector2(0.5, 0.5)
    tex.fill_to = Vector2(1.0, 1.0)
    
    return tex


func _resolve_icon_texture() -> Texture2D:
    var icon_paths_by_key := _collect_icon_paths()
    if not icon_paths_by_key.is_empty():
        for file_base in _build_icon_candidates():
            var key := file_base.to_lower()
            if not icon_paths_by_key.has(key):
                continue
            var mapped_path := String(icon_paths_by_key[key])
            var mapped_tex := _try_load_texture(mapped_path)
            if mapped_tex != null:
                return mapped_tex

    for file_base in _build_icon_candidates():
        var path := "%s/%s.png" % [SPELL_ICON_DIR, file_base]
        if not _resource_file_exists(path):
            continue
        var tex := _try_load_texture(path)
        if tex != null:
            return tex
    return null


func _try_load_texture(path: String) -> Texture2D:
    if not _resource_file_exists(path):
        return null

    var imported := load(path) as Texture2D
    if imported != null:
        return imported

    var image := Image.new()
    var fs_path := ProjectSettings.globalize_path(path)
    var err := image.load(fs_path)
    if err != OK:
        return null

    return ImageTexture.create_from_image(image)


func _resource_file_exists(path: String) -> bool:
    var fs_path := ProjectSettings.globalize_path(path)
    return FileAccess.file_exists(fs_path)


func _collect_icon_paths() -> Dictionary:
    var out := {}
    var dir := DirAccess.open(SPELL_ICON_DIR)
    if dir == null:
        return out

    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
            var base_name := file_name.substr(0, file_name.length() - 4)
            var key := _sanitize_file_base(base_name).to_lower()
            if key != "" and not out.has(key):
                out[key] = "%s/%s" % [SPELL_ICON_DIR, file_name]
        file_name = dir.get_next()
    dir.list_dir_end()

    return out


func _build_icon_candidates() -> Array[String]:
    var out: Array[String] = []

    _push_icon_candidate(out, spell_name)
    _push_icon_candidate(out, spell_name.to_lower())
    _push_icon_candidate(out, spell_name.replace(" ", "_"))
    _push_icon_candidate(out, spell_name.to_lower().replace(" ", "_"))

    var id := spell_id.strip_edges()
    _push_icon_candidate(out, id)
    _push_icon_candidate(out, id.replace("_", " "))

    var title := _to_title_case(id)
    _push_icon_candidate(out, title)
    _push_icon_candidate(out, title.replace(" ", "_"))

    return out


func _push_icon_candidate(out: Array[String], value: String) -> void:
    var candidate := _sanitize_file_base(value)
    if candidate == "":
        return
    if out.has(candidate):
        return
    out.append(candidate)


func _sanitize_file_base(value: String) -> String:
    var cleaned := value.strip_edges()
    if cleaned == "":
        return ""
    var forbidden := ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"]
    for token in forbidden:
        cleaned = cleaned.replace(token, "")
    return cleaned


func _to_title_case(id: String) -> String:
    var parts := id.split("_", false)
    if parts.is_empty():
        return id
    for i in range(parts.size()):
        parts[i] = String(parts[i]).capitalize()
    return " ".join(parts)
