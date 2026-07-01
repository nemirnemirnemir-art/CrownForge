extends Node

## HeroBarDisplay module
## Manages hero bar display updates and visual elements

var _slots: Array[TextureButton] = []
var _portraits: Node
var _selected_hero_id: String = ""
var _current_page: int = 0
const HEROES_PER_PAGE: int = 20

func initialize(slots: Array[TextureButton], portraits: Node) -> void:
    _slots = slots
    _portraits = portraits

func set_selected_hero_id(hero_id: String) -> void:
    _selected_hero_id = hero_id

func get_selected_hero_id() -> String:
    return _selected_hero_id

func set_current_page(page: int) -> void:
    _current_page = page

func update_display(prev_button: Button, next_button: Button) -> void:
    if HeroCore == null or _slots.is_empty():
        return
    
    # Get heroes as array and sort by ID
    var all_heroes: Array = []
    for hero in HeroCore.heroes.values():
        if not hero.get("isDead", false):
            all_heroes.append(hero)
    all_heroes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a.get("id", "") < b.get("id", "")
    )
    
    var start_index: int = _current_page * HEROES_PER_PAGE
    var end_index: int = min(start_index + HEROES_PER_PAGE, all_heroes.size())
    
    # Get heroes in battle
    var heroes_in_battle = HeroCore.get_heroes_in_battle()
    
    for i in range(HEROES_PER_PAGE):
        var slot: TextureButton = _slots[i]
        slot.mouse_filter = Control.MOUSE_FILTER_STOP
        slot.disabled = false
        
        # Clear old visual effects
        var children_to_remove: Array = []
        for child in slot.get_children():
            if child.name.begins_with("SelectionBorder") or child.name.begins_with("StatusContainer") or child.name.begins_with("HPBar"):
                children_to_remove.append(child)
        
        for child in children_to_remove:
            slot.remove_child(child)
            child.queue_free()
        
        var hero_index: int = start_index + i
        
        if hero_index < all_heroes.size():
            var hero: Dictionary = all_heroes[hero_index]
            var hero_id: String = hero.get("id", "")
            var is_in_battle: bool = hero_id in heroes_in_battle
            
            _update_slot_for_hero(slot, hero, hero_id, is_in_battle)
        else:
            # Empty slot
            slot.texture_normal = null
            slot.modulate = Color.WHITE
            for child in slot.get_children():
                child.queue_free()
    
    # Update pagination buttons
    if prev_button != null:
        prev_button.disabled = (_current_page <= 0)
    if next_button != null:
        next_button.disabled = (end_index >= all_heroes.size())

func _update_slot_for_hero(slot: TextureButton, hero: Dictionary, hero_id: String, is_in_battle: bool) -> void:
    # 1. Set Portrait
    var icon_id: String = hero.get("icon_id", "")
    if icon_id != "" and _portraits:
        var icon_path: String = _portraits.get_or_assign_portrait(hero_id, icon_id)
        var texture = _portraits.load_portrait_texture(icon_path)
        if texture:
            slot.texture_normal = texture
    
    # 2. Reset modulate
    slot.modulate = Color.WHITE
    
    # 3. Battle Overlay
    if is_in_battle:
        slot.modulate = Color(1.0, 0.5, 0.5)
    
    # 4. Selection Border
    if hero_id == _selected_hero_id:
        _add_selection_border(slot)
    
    # 5. Status Icons
    _add_status_icons(slot, hero)
    
    # 6. Health Bar
    _add_health_bar(slot, hero)

func _add_selection_border(slot: TextureButton) -> void:
    var has_border = false
    for child in slot.get_children():
        if child.name == "SelectionBorder":
            has_border = true
            break
    
    if not has_border:
        var border_scene = load("res://scenes/ui/widgets/SelectionBorder.tscn")
        if border_scene:
            var border = border_scene.instantiate()
            border.name = "SelectionBorder"
            border.mouse_filter = Control.MOUSE_FILTER_IGNORE
            slot.add_child(border)

func _add_status_icons(slot: TextureButton, hero: Dictionary) -> void:
    var status_container = HBoxContainer.new()
    status_container.name = "StatusContainer"
    status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    status_container.alignment = BoxContainer.ALIGNMENT_END
    status_container.layout_mode = 1
    status_container.anchors_preset = Control.PRESET_BOTTOM_RIGHT
    status_container.position = Vector2(-2, -2)
    status_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
    status_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
    slot.add_child(status_container)

func _add_health_bar(slot: TextureButton, hero: Dictionary) -> void:
    var hp_bar_bg = ColorRect.new()
    hp_bar_bg.name = "HPBarBG"
    hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
    hp_bar_bg.custom_minimum_size = Vector2(50, 8)
    hp_bar_bg.size = Vector2(50, 8)
    hp_bar_bg.position = Vector2(0, 42)
    slot.add_child(hp_bar_bg)
    
    var hp_percent = 0.0
    var max_hp: float = float(hero.get("maxHp", 1.0))
    if HeroCore:
        var hero_id: String = str(hero.get("id", ""))
        if hero_id != "":
            var total_stats: Dictionary = HeroCore.get_hero_total_stats(hero_id)
            if total_stats is Dictionary and total_stats.has("maxHp"):
                max_hp = float(total_stats.get("maxHp", max_hp))
    if max_hp > 0:
        hp_percent = float(hero.get("hp", 0)) / max_hp
    
    var hp_bar_fill = ColorRect.new()
    hp_bar_fill.name = "HPBarFill"
    hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_bar_fill.color = Color(0.2, 0.8, 0.2, 1.0)
    hp_bar_fill.custom_minimum_size = Vector2(50 * hp_percent, 8)
    hp_bar_fill.size = Vector2(50 * hp_percent, 8)
    hp_bar_bg.add_child(hp_bar_fill)
