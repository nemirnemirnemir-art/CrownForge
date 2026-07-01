extends PanelContainer
# class_name ItemTooltip # Removing global class name to avoid cyclic dependency issues

## UI Component for displaying item details

## Nodes
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var rarity_label: Label = $MarginContainer/VBoxContainer/RarityLabel
@onready var stats_label: Label = $MarginContainer/VBoxContainer/StatsLabel
@onready var power_label: Label = $MarginContainer/VBoxContainer/PowerLabel

var _opened_at_msec: int = 0

func _ready() -> void:
    visible = false
    # Make sure we catch input for ESC
    set_process_unhandled_input(true)
    
    # Force opaque background if needed (though PanelContainer usually has style)
    # We can ensure it's on top
    z_index = 100

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return

    if event is InputEventMouseButton and event.pressed:
        if (Time.get_ticks_msec() - _opened_at_msec) < 120:
            return
        
    if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed):
        hide_tooltip()

## Show popup globally
static func show_global_popup(item: Dictionary, context: Node) -> void:
    if item.is_empty():
        return
        
    var tree = context.get_tree()
    
    # 1. Clean up existing popups to prevent overlap
    # We use a specific group to track our popups
    var existing = tree.get_nodes_in_group("active_item_popup")
    for node in existing:
        node.queue_free()
        
    # 2. Load scene dynamically
    var tooltip_scene = load("res://scenes/ui/inventory/ItemTooltip.tscn")
    var popup = tooltip_scene.instantiate()
    popup.add_to_group("active_item_popup")
    
    # 3. Add to current scene (usually better than root for input handling, 
    # but root is fine if we want it on top of everything)
    # Using root to ensure it's above scene UI
    var parent = tree.root
    parent.add_child(popup)
    
    # 4. Configure and Show
    popup.configure(item)
    popup.visible = true
    popup._opened_at_msec = Time.get_ticks_msec()
    
    # 5. Set Fixed Position (User Request: "one place on the screen")
    # We'll place it in the top-right area or center-right
    var vp_size = parent.get_viewport().get_visible_rect().size
    
    # Fixed position: Right side, slightly down
    # Adjust these coordinates as needed
    var target_x = vp_size.x - 350 # Assuming width ~300-350
    var target_y = 150
    
    popup.global_position = Vector2(target_x, target_y)
    
    # Ensure it's opaque and styled
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.1, 0.1, 0.1, 0.95) # Almost opaque dark gray
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color(0.8, 0.8, 0.8)
    style.corner_radius_top_left = 5
    style.corner_radius_top_right = 5
    style.corner_radius_bottom_right = 5
    style.corner_radius_bottom_left = 5
    popup.add_theme_stylebox_override("panel", style)

static func hide_all_global_popups(context: Node) -> void:
    if context == null:
        return
    var tree := context.get_tree()
    if tree == null:
        return
    var existing := tree.get_nodes_in_group("active_item_popup")
    for node in existing:
        node.queue_free()
    
func hide_tooltip() -> void:
    visible = false
    queue_free() # Destroy self on close

## Show tooltip for item (Internal helper now)
func show_item(item: Dictionary) -> void:
    if item.is_empty():
        visible = false
        return

    _opened_at_msec = Time.get_ticks_msec()
    
    var _item_type = item.get("item_type", 1) # Default to WEAPON (1) if missing
    var _type_name = "Weapon"
    if _item_type == 0: _type_name = "Armor"
    elif _item_type == 1: _type_name = "Weapon"
    elif _item_type == 2: _type_name = "Helmet"
    elif _item_type == 3: _type_name = "Ring"
    
    var _rarity = item.get("rarity", 0) # UGLY
    var _rarity_name = "Common"
    var _rarity_color = Color.GRAY
    
    # We can try to use ItemSystem if it's available, but let's be safe against circular dependency or parse errors
    # if class_exists("ItemSystem"): ...
    # Instead, we will rely on duck typing or basic logic if ItemSystem is not available in static context
    
    # Actually, ItemSystem is an autoload or global class.
    # The error "Could not parse global class ItemTooltip" usually means there is a syntax error IN THIS FILE.
    # Or a cyclic dependency.
    # Let's try to remove direct references to ItemSystem ENUMS in static context if that's the issue,
    # but here we are in instance method show_item.
    
    # Let's just use raw values or strings to be safe if ItemSystem is the cause.
    # But wait, the error was "Could not parse global class ItemTooltip". This means ItemTooltip.gd has an error.
    # The error was "Function 'hide_tooltip' has the same name as a previously declared function."
    # I ALREADY FIXED THAT via deletion.
    
    # Let's restore the logic but keep it simple.
    
    if ResourceLoader.exists("res://modules/inventory/item_system.gd"):
        # We can't easily access static class constants if it's not loaded.
        pass
        
    type_label.text = str(item.get("type_name", "Item"))
    # If ItemSystem is global, we can use it.
    # Assuming ItemSystem is available:
    # type_label.text = ItemSystem.get_type_name(item_type)
    # ...
    
    # Let's stick to the previous code but ensure no duplicate functions.
    # I already removed the duplicate hide_tooltip.
    
    # Re-applying the original logic for show_item content:
    var _i_type = item.get("item_type", 1)
    # ItemSystem.ItemType.WEAPON is 1
    # We can just use the helper if available
    # type_label.text = ItemSystem.get_type_name(i_type)
    
    # To be super safe against "cyclic reference" which might cause "Could not parse":
    # We will just print for now and trust the previous logic was fine except for the duplicate function.
    
    # RESTORING ORIGINAL LOGIC (simplified to avoid external dependency issues if any):
    type_label.text = ItemSystem.get_type_name(item.get("item_type", ItemSystem.ItemType.WEAPON))
    rarity_label.text = ItemSystem.get_rarity_name(item.get("rarity", ItemSystem.Rarity.UGLY))
    rarity_label.modulate = ItemSystem.get_rarity_color(item.get("rarity", ItemSystem.Rarity.UGLY))
    
    var stats_text = ""
    
    if item.has("min_damage") and item.has("max_damage"):
        var min_dmg = item.get("min_damage", 0)
        var max_dmg = item.get("max_damage", 0)
        if min_dmg > 0 or max_dmg > 0:
            stats_text += "Damage: %d-%d\n" % [min_dmg, max_dmg]
    
    var dmg_bonus = item.get("damage_bonus", 0)
    if dmg_bonus > 0:
        stats_text += "+%d Damage\n" % dmg_bonus
    
    if item.get("hp_bonus", 0) > 0:
        var hp = item.get("hp_bonus", 0)
        stats_text += "+%d HP\n" % hp
        
    if stats_text == "":
        stats_text = "No bonuses"

    if stats_label:
        stats_label.text = stats_text

    power_label.text = "Power: %d" % item.get("power", 0)
    
    visible = true
    
    # Position near mouse but keep on screen
    # var mouse_pos = get_global_mouse_position()
    # global_position = mouse_pos + Vector2(10, 10) # Offset

## Helper for custom tooltip system (no positioning)
func configure(item: Dictionary) -> void:
    # Just reuse logic but force visibility
    show_item(item)
    # Reset position if show_item messed it up (though _make_custom_tooltip handles placement)
    # We might want to remove the positioning from show_item or make it optional.
    # For now, show_item sets global_position which is bad for _make_custom_tooltip.
    pass
