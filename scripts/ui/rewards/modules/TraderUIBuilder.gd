extends RefCounted
class_name TraderUIBuilder

## Handles UI building and tooltips for the Trader menu

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const BuildingUpgradeDataScript := preload("res://scripts/ui/town/buildings/BuildingUpgradeData.gd")

func setup_empty_tile(tile: Control) -> void:
    if tile == null:
        return
    if tile.has_method("setup"):
        tile.setup("", null, null, 0)
    if tile.has_method("set_purchased"):
        tile.set_purchased(true)

func make_placeholder_icon(key: String) -> Texture2D:
    var k := String(key)
    var h := k.hash()
    var hue := fmod(abs(float(h)), 360.0) / 360.0
    var color1 := Color.from_hsv(hue, 0.7, 0.9)
    var color2 := Color.from_hsv(fmod(hue + 0.15, 1.0), 0.6, 0.6)
    var gradient := Gradient.new()
    gradient.set_color(0, color1)
    gradient.set_color(1, color2)
    var tex := GradientTexture2D.new()
    tex.gradient = gradient
    tex.width = 64
    tex.height = 64
    tex.fill = GradientTexture2D.FILL_RADIAL
    tex.fill_from = Vector2(0.5, 0.5)
    tex.fill_to = Vector2(1.0, 1.0)
    return tex

func build_tooltip_text(tile: Control, artifact_catalog: Object, building_registry: Object) -> String:
    var k := String(tile.get("kind"))
    var p: Variant = tile.get("payload")
    match k:
        "artifact":
            var id := String(p)
            if artifact_catalog == null:
                return id
            var def = artifact_catalog.call("get_def", id)
            var name_str := String(def.get("name", id))
            var desc := String(def.get("description", ""))
            if desc != "":
                return "%s\n%s" % [name_str, desc]
            return name_str
        "building":
            if building_registry == null:
                return String(p)
            var cfg = building_registry.call("get_building", String(p))
            if cfg == null:
                return String(p)
            var name_str: String = String(p)
            if "display_name" in cfg:
                name_str = String(cfg.display_name)
            var desc: String = ""
            if "description" in cfg:
                desc = String(cfg.description)
            if desc != "":
                return "%s\n%s" % [name_str, desc]
            return name_str
        "spell":
            var id := String(p)
            var config = PathRegistryScript.load_spell_config(id)
            if config == null:
                return id
            var name_str := String(config.get("display_name")) if "display_name" in config else id
            var desc := String(config.get("description")) if "description" in config else ""
            if desc != "":
                return "%s\n%s" % [name_str, desc]
            return name_str
        "building_upgrade":
            if p is Dictionary:
                var d := p as Dictionary
                var b := String(d.get("building_id", ""))
                var idx := int(d.get("upgrade_index", 0))
                var defs: Array = []
                if BuildingUpgradeDataScript:
                    defs = BuildingUpgradeDataScript.get_upgrades(b)
                if idx < defs.size():
                    var udef_v: Variant = defs[idx]
                    if udef_v is Dictionary:
                        var udef: Dictionary = udef_v as Dictionary
                        var uname := String(udef.get("name", "Upgrade"))
                        var udesc := String(udef.get("desc", ""))
                        if udesc != "":
                            return "%s\n%s" % [uname, udesc]
                        return uname
            return "Building Upgrade"
        "troop_training":
            return "Troop Training\nChoose a bonus for a troop class"
    return ""

func show_tooltip(tooltip_panel: PanelContainer, tooltip_label: Label, text: String, tile: Control, viewport_rect: Rect2) -> void:
    if tooltip_panel == null or tooltip_label == null:
        return
    tooltip_label.text = text
    tooltip_panel.visible = true
    
    # We must await one frame externally for size recalculation if needed,
    # but the positioning math can be run here after that await
    var tile_pos := tile.global_position
    var tp_size := tooltip_panel.size
    var screen_size := viewport_rect.size
    var tx := tile_pos.x - tp_size.x - 8.0
    if tx < 4.0:
        tx = tile_pos.x + tile.size.x + 8.0
    var ty := tile_pos.y
    if ty + tp_size.y > screen_size.y - 8.0:
        ty = screen_size.y - tp_size.y - 8.0
    tooltip_panel.global_position = Vector2(tx, ty)
