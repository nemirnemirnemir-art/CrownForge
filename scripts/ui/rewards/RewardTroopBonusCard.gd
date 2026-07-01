extends Panel
class_name RewardTroopBonusCard

signal selected(offer_id: String)

@onready var portraits_box: HBoxContainer = get_node_or_null("PortraitsBox")
@onready var name_label: Label = get_node_or_null("NameLabel")
@onready var description_label: Label = get_node_or_null("DescriptionLabel")
@onready var choose_button: Button = get_node_or_null("ChooseButton")

var offer_id: String = ""

func _ready() -> void:
    if choose_button:
        choose_button.pressed.connect(_on_choose_pressed)

func setup(new_offer_id: String) -> void:
    offer_id = new_offer_id

    var parts := offer_id.split("_", false)
    if parts.size() != 2:
        if name_label:
            name_label.text = offer_id
        return

    var stat_key := String(parts[0])
    var class_id := int(parts[1])

    var stat_name := "HP" if stat_key == "hp" else "DMG"
    var unit_class_name: String = _get_unit_class_name(class_id)

    if name_label:
        name_label.text = "+15% " + stat_name + " " + unit_class_name

    if description_label:
        description_label.text = "Increases base stats for all units of this class."

    _rebuild_portraits(class_id)

func _on_choose_pressed() -> void:
    if offer_id != "":
        selected.emit(offer_id)

func _rebuild_portraits(class_id: int) -> void:
    if portraits_box == null:
        return

    for ch in portraits_box.get_children():
        ch.queue_free()

    var heroes := _get_owned_heroes_for_class(class_id)
    var limit := 4
    for i in range(min(limit, heroes.size())):
        var hero: Dictionary = heroes[i]
        var icon_id := str(hero.get("icon_id", ""))
        var tex := _load_icon_texture(icon_id)
        var base_id := _base_id_from_hero_id(str(hero.get("id", "")))
        var unit_count := _count_units_of_type(base_id)

        var container := VBoxContainer.new()
        container.alignment = BoxContainer.ALIGNMENT_CENTER

        var rect := TextureRect.new()
        rect.custom_minimum_size = Vector2(46, 46)
        rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        rect.texture = tex
        rect.tooltip_text = str(hero.get("name", hero.get("id", "")))
        container.add_child(rect)

        var count_label := Label.new()
        count_label.text = "x%d" % unit_count
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        count_label.add_theme_font_size_override("font_size", 14)
        count_label.add_theme_color_override("font_color", Color.WHITE)
        count_label.add_theme_color_override("font_outline_color", Color.BLACK)
        count_label.add_theme_constant_override("outline_size", 3)
        container.add_child(count_label)

        portraits_box.add_child(container)

func _get_owned_heroes_for_class(class_id: int) -> Array:
    var out: Array = []

    if HeroCore == null:
        return out

    var troop_core: Object = _get_troop_bonus_core()
    if troop_core == null:
        return out

    var seen: Dictionary = {}
    for h in HeroCore.heroes.values():
        if not (h is Dictionary):
            continue
        if not bool(h.get("is_hired", false)):
            continue

        var hero_id := str(h.get("id", ""))
        if hero_id == "":
            continue

        var base_id := _base_id_from_hero_id(hero_id)
        if base_id == "" or seen.has(base_id):
            continue

        var unit_classes: Array = troop_core.call("get_unit_classes", base_id)
        if unit_classes.has(class_id):
            out.append(h)
            seen[base_id] = true

    return out

func _base_id_from_hero_id(hero_id: String) -> String:
    var id := hero_id.to_lower()
    if id.contains("_"):
        var parts := id.rsplit("_", true, 1)
        if parts.size() == 2 and String(parts[1]).is_valid_int():
            return String(parts[0])
    return id

func _count_units_of_type(base_id: String) -> int:
    if HeroCore == null:
        return 0
    var count := 0
    for h in HeroCore.heroes.values():
        if not (h is Dictionary):
            continue
        if not bool(h.get("is_hired", false)):
            continue
        var hero_id := str(h.get("id", ""))
        var h_base_id := _base_id_from_hero_id(hero_id)
        if h_base_id == base_id:
            count += 1
    return count

func _get_unit_class_name(class_id: int) -> String:
    match class_id:
        0: return "Grunt"
        1: return "Warrior"
        2: return "Ranged"
        3: return "Rider"
        4: return "Champion"
        5: return "Flying"
        6: return "Arcane"
        7: return "Undead"
    return "Unknown"

func _get_troop_bonus_core() -> Object:
    var tree := get_tree()
    if tree == null:
        return null
    var root := tree.root
    if root == null:
        return null
    return root.get_node_or_null("TroopBonusCore")

func _load_icon_texture(icon_id: String) -> Texture2D:
    if icon_id == "":
        return null

    var path := HeroAssetLoader.get_hero_icon_path(icon_id)
    if not ResourceLoader.exists(path):
        return null

    var res := load(path)
    if res is Texture2D:
        return res
    if res is SpriteFrames:
        var sf := res as SpriteFrames
        if sf.has_animation("idle") and sf.get_frame_count("idle") > 0:
            return sf.get_frame_texture("idle", 0)
        if sf.has_animation("walk") and sf.get_frame_count("walk") > 0:
            return sf.get_frame_texture("walk", 0)
    return null
