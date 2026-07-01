extends Control
class_name InventorySlot

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")

## UI Component for a single inventory slot

## Signals
signal slot_clicked(index: int)
signal slot_double_clicked(index: int)
signal slot_hovered(index: int)
signal slot_unhovered(index: int)

## Nodes
@onready var background: ColorRect = $Background
@onready var icon: TextureRect = $Icon
@onready var selection_border: ReferenceRect = $SelectionBorder
@onready var lock_icon: TextureRect = $LockIcon

## State
var slot_index: int = -1
var item_data: Dictionary = {}
var _pulse_tween: Tween = null

func _ready() -> void:
    # Connect input events
    gui_input.connect(_on_gui_input)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

    if background:
        background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if icon:
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if selection_border:
        selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if lock_icon:
        lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # Default state
    selection_border.visible = false
    background.color = ItemSystem.get_rarity_color(ItemSystem.Rarity.UGLY) # Default color
    icon.texture = null

## Setup the slot with item data
func setup(index: int, item: Dictionary, empty_icon_path: String = "") -> void:
    slot_index = index
    item_data = item
    
    if item.is_empty():
        # Empty slot
        # background.color = Color(0.2, 0.2, 0.2, 0.5) # Removed gray background logic
        background.color = Color(0, 0, 0, 0) # Transparent background
        
        if empty_icon_path != "" and ResourceLoader.exists(empty_icon_path):
                icon.texture = load(empty_icon_path)
                # Use full opacity for the frame/placeholder if it's a custom PNG frame
                icon.modulate = Color(1, 1, 1, 1)
                
                # Force stretch for empty slot background images
                icon.stretch_mode = TextureRect.STRETCH_SCALE
                icon.set_anchors_preset(Control.PRESET_FULL_RECT)
                icon.offset_left = 0
                icon.offset_top = 0
                icon.offset_right = 0
                icon.offset_bottom = 0
        else:
            icon.texture = null
            icon.modulate = Color.WHITE
        tooltip_text = ""

        if lock_icon:
            lock_icon.visible = false
        
        # Hide quantity label if exists
        if has_node("QuantityLabel"):
            get_node("QuantityLabel").visible = false
    else:
        # Filled slot
        icon.modulate = Color.WHITE
        
        # Reset stretch mode for actual items (keep aspect ratio)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.set_anchors_preset(Control.PRESET_FULL_RECT)
        
        # Restore padding for items (5px margin as defined in scene)
        icon.offset_left = 5
        icon.offset_top = 5
        icon.offset_right = -5
        icon.offset_bottom = -5
        
        # Filled slot
        var rarity = item.get("rarity", ItemSystem.Rarity.UGLY)
        # background.color = ItemSystem.get_rarity_color(rarity) # We might want to keep rarity color or remove if using frames?
        # User asked to "remove gray background visuals when png files are present"
        # Assuming for FILLED items we still want rarity or just the item icon?
        # Let's keep rarity for now unless instructed otherwise, but maybe make it transparent if we want pure icon?
        # But user specifically said "remove visual of gray plates under png files which give visual of empty buttons"
        # This implies mostly for EMPTY state. 
        # For filled state, rarity color is useful info. Let's keep it but ensure it doesn't conflict.
        background.color = ItemSystem.get_rarity_color(rarity)
        
        var icon_path = item.get("icon_path", "")
        if icon_path != "" and ResourceLoader.exists(icon_path):
            icon.texture = load(icon_path)
        else:
            icon.texture = load("res://icon.svg") # Fallback to default icon
        
        # Show quantity if > 1
        var quantity = item.get("quantity", 1)
        if quantity > 1:
            if not has_node("QuantityLabel"):
                var lbl = Label.new()
                lbl.name = "QuantityLabel"
                lbl.add_theme_font_override("font", ThaleahFont)
                lbl.add_theme_font_size_override("font_size", 24)
                lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
                lbl.anchors_preset = Control.PRESET_BOTTOM_RIGHT
                lbl.position = Vector2(size.x - 20, size.y - 20)
                lbl.size = Vector2(20, 20)
                lbl.text = str(quantity)
                add_child(lbl)
            else:
                var lbl = get_node("QuantityLabel")
                lbl.text = str(quantity)
                lbl.visible = true
        else:
            if has_node("QuantityLabel"):
                get_node("QuantityLabel").visible = false

        # Tooltip is handled by external tooltip component, but we can set basic one
        var _item_type = item.get("item_type", ItemSystem.ItemType.WEAPON)  # Default to WEAPON if missing
        
        var _stats_text = ""
        var dmg_bonus = item.get("damage_bonus", 0)
        var min_dmg = item.get("min_damage", 0)
        var max_dmg = item.get("max_damage", 0)
        var hp_bonus = item.get("hp_bonus", 0)
        
        if min_dmg > 0 or max_dmg > 0:
            _stats_text += "\nDamage: %d-%d" % [min_dmg, max_dmg]
        elif dmg_bonus > 0:
            _stats_text += "\nDamage: +%d" % dmg_bonus
            
        if hp_bonus > 0:
            _stats_text += "\nHP: +%d" % hp_bonus
            
        # For _make_custom_tooltip to work, we need some text.
        # We can pass the item description or just a placeholder.
        # User wants NO HOVER tooltip, but CLICK popup.
        # So we disable tooltip_text.
        tooltip_text = ""

        if lock_icon:
            lock_icon.visible = bool(item.get("locked", false))

func _make_custom_tooltip(_for_text: String) -> Control:
    # Disabled in favor of click popup
    return null

## Set selection state
func set_selected(selected: bool) -> void:
    if _pulse_tween and _pulse_tween.is_valid():
        _pulse_tween.kill()
        _pulse_tween = null
    if selected:
        selection_border.visible = true
        _pulse_tween = create_tween()
        _pulse_tween.set_loops()
        _pulse_tween.tween_property(selection_border, "modulate:a", 0.3, 0.7)
        _pulse_tween.tween_property(selection_border, "modulate:a", 1.0, 0.7)
    else:
        selection_border.visible = false
        selection_border.modulate = Color.WHITE

## Input handling
func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.double_click:
                slot_double_clicked.emit(slot_index)
            else:
                # Emit clicked signal for selection/logic
                slot_clicked.emit(slot_index)
            
            # Tooltip popup logic removed - handled by parent UI
            
    # Drag and Drop handling is done via standard _get_drag_data / _can_drop_data / _drop_data
    # But those methods must be implemented in this script or inherited.
    # Since this is a Control, we can implement them directly.

func _get_drag_data(_at_position: Vector2) -> Variant:
    if item_data.is_empty():
        return null

    if bool(item_data.get("locked", false)):
        return null
        
    # Create drag preview
    var preview = TextureRect.new()
    preview.texture = icon.texture
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.custom_minimum_size = Vector2(50, 50)
    preview.size = Vector2(50, 50)
    preview.modulate = Color(1, 1, 1, 0.8)
    
    set_drag_preview(preview)
    
    # Return data about this slot
    return {
        "source": self,
        "index": slot_index,
        "item": item_data
    }

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("source") and data.has("item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    # Let the parent handle the actual move logic by emitting a signal
    # Or better, we can define a standard signal for dropping
    # But `slot_dropped` signal is not standard.
    # We can assume the parent connects to this logic or we call a method on parent?
    # Better: emit a signal that the parent listens to? No, _drop_data is called on the receiving slot.
    
    # If we emit a signal here, the parent needs to connect to it for every slot.
    # Let's add a new signal `data_dropped(source_data, target_index)`
    data_dropped.emit(data, slot_index)

## Signals
signal data_dropped(source_data: Dictionary, target_index: int)

func _on_mouse_entered() -> void:
    slot_hovered.emit(slot_index)

func _on_mouse_exited() -> void:
    slot_unhovered.emit(slot_index)
