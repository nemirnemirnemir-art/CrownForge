extends Node

## HeroBarDisplay module
## Manages hero bar display updates and visual elements

var _slots: Array[TextureButton] = []
var _portraits: Node
var _selected_hero_id: String = ""
var _current_page: int = 0
const HEROES_PER_PAGE: int = 5

var _hp_bar_offset: Vector2 = Vector2(0, 42)
var _hp_bar_size: Vector2 = Vector2(50, 8)

func _get_hero_core() -> Node:
    var main_loop := Engine.get_main_loop()
    if not (main_loop is SceneTree):
        return null
    var tree := main_loop as SceneTree
    return tree.root.get_node_or_null("HeroCore")

func initialize(slots: Array[TextureButton], portraits: Node) -> void:
    _slots = slots
    _portraits = portraits

func configure_hp_bar(offset: Vector2, size: Vector2) -> void:
    _hp_bar_offset = offset
    _hp_bar_size = size

func set_selected_hero_id(hero_id: String) -> void:
    _selected_hero_id = hero_id

func get_selected_hero_id() -> String:
    return _selected_hero_id

func set_current_page(page: int) -> void:
    _current_page = page

func update_display(prev_button: SliderButton, next_button: SliderButton) -> void:
    var hero_core := _get_hero_core()
    if hero_core == null or _slots.is_empty():
        return
    
    # Get heroes as array and sort by ID
    var all_hero_ids: Array = []
    for hero_id in hero_core.query.get_all_hero_ids():
        # Filter dead and unhired heroes
        if not hero_core.query.is_hero_dead(hero_id) and hero_core.query.is_hero_hired(hero_id):
            all_hero_ids.append(hero_id)
            
    all_hero_ids.sort()
    
    var start_index: int = _current_page * HEROES_PER_PAGE
    var _end_index: int = min(start_index + HEROES_PER_PAGE, all_hero_ids.size())
    
    # Get heroes in battle
    var heroes_in_battle = hero_core.get_heroes_in_battle()
    
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
        
        if hero_index < all_hero_ids.size():
            var hero_id: String = all_hero_ids[hero_index]
            var is_in_battle: bool = hero_id in heroes_in_battle
            
            _update_slot_for_hero(slot, hero_id, is_in_battle)
        else:
            # Empty slot
            slot.texture_normal = null
            slot.modulate = Color.WHITE
            for child in slot.get_children():
                child.queue_free()
    
    # Update buttons
    # Do not disable buttons so they can still play click animation
    # Just change appearance if disabled logic applies
    prev_button.disabled = false
    prev_button.modulate.a = 0.5 if (_current_page == 0) else 1.0
    
    var total_pages = ceil(float(all_hero_ids.size()) / float(HEROES_PER_PAGE))
    var is_next_disabled = (_current_page >= total_pages - 1) or (total_pages == 0)
    
    next_button.disabled = false
    next_button.modulate.a = 0.5 if is_next_disabled else 1.0

func _update_slot_for_hero(slot: TextureButton, hero_id: String, is_in_battle: bool) -> void:
    # 1. Set Portrait
    var hero_core := _get_hero_core()
    if hero_core == null:
        return
    var icon_id: String = hero_core.query.get_hero_icon_id(hero_id)
    
    if icon_id != "" and _portraits:
        var icon_path: String = _portraits.get_or_assign_portrait(hero_id, icon_id)
        var texture = _portraits.load_portrait_texture(icon_path)
        if texture:
            slot.texture_normal = texture
            slot.ignore_texture_size = true # Force resize to button
            slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
    
    # 2. Reset modulate
    slot.modulate = Color.WHITE
    
    # 3. Battle Overlay
    if is_in_battle:
        slot.modulate = Color(1.0, 0.5, 0.5)
    
    # 4. Selection Border
    if hero_id == _selected_hero_id:
        _add_selection_border(slot)
    
    # 5. Status Icons
    _add_status_icons(slot, hero_id)
    
    # 6. Health Bar
    _add_health_bar(slot, hero_id)

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

func _add_status_icons(slot: TextureButton, _hero_id: String) -> void:
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

func _add_health_bar(slot: TextureButton, hero_id: String) -> void:
    var outline := ColorRect.new()
    outline.name = "HPBarOutline"
    outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    outline.color = Color(0, 0, 0, 1)
    outline.custom_minimum_size = _hp_bar_size + Vector2(2, 2)
    outline.size = _hp_bar_size + Vector2(2, 2)
    outline.position = _hp_bar_offset - Vector2(1, 1)
    slot.add_child(outline)

    var hp_bar_bg := ColorRect.new()
    hp_bar_bg.name = "HPBarBG"
    hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.85)
    hp_bar_bg.custom_minimum_size = _hp_bar_size
    hp_bar_bg.size = _hp_bar_size
    hp_bar_bg.position = Vector2(1, 1)
    outline.add_child(hp_bar_bg)
    
    var hp_percent = 0.0
    var hero_core := _get_hero_core()
    if hero_core == null:
        return
    var max_hp = hero_core.query.get_hero_max_hp(hero_id)
    if max_hp > 0:
        hp_percent = hero_core.query.get_hero_hp(hero_id) / max_hp
    
    var hp_bar_fill := ColorRect.new()
    hp_bar_fill.name = "HPBarFill"
    hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hp_bar_fill.color = Color(0.2, 0.8, 0.2, 1.0)
    hp_bar_fill.custom_minimum_size = Vector2(_hp_bar_size.x * hp_percent, _hp_bar_size.y)
    hp_bar_fill.size = Vector2(_hp_bar_size.x * hp_percent, _hp_bar_size.y)
    hp_bar_bg.add_child(hp_bar_fill)
