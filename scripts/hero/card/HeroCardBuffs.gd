extends RefCounted
class_name HeroCardBuffs

## Управление баффами
## Создание слотов, обновление, иконки, тултипы

const MAX_BUFF_SLOTS: int = 6  # 3x2 grid

var _buff_grid: GridContainer
var _buff_slots: Array[Control] = []  # Changed from TextureRect to Control to support Panel nodes

func initialize(buff_grid: GridContainer) -> void:
    _buff_grid = buff_grid
    create_buff_slots()

func create_buff_slots() -> void:
    if not _buff_grid:
        print("[HeroCardBuffs] ⚠️ BuffGrid not found in scene!")
        return

    _buff_slots.clear()
    for i in range(MAX_BUFF_SLOTS):
        var slot_name = "BuffSlot%d" % i
        var slot = _buff_grid.get_node_or_null(slot_name)
        if slot:
            _buff_slots.append(slot)
        else:
            print("[HeroCardBuffs] ⚠️ BuffSlot%d not found!" % i)
            _buff_slots.append(null)

func update_buff_slots(selected_hero_id: String) -> void:
    if _buff_slots.is_empty():
        print("[HeroCardBuffs] ⚠️ Buff slots not initialized!")
        return

    if selected_hero_id == "" or not HeroCore:
        return

    var hero_buffs_dict = HeroCore.get_hero_buffs(selected_hero_id)
    print("[HeroCardBuffs] Buffs for %s: %s" % [selected_hero_id, str(hero_buffs_dict)])
    
    var buff_entries: Array[Dictionary] = []
    for buff_id in hero_buffs_dict.keys():
        var entry = hero_buffs_dict[buff_id].duplicate()
        entry["buff_id"] = buff_id
        buff_entries.append(entry)
    
    print("[HeroCardBuffs] Buff entries: %d" % buff_entries.size())

    for i in range(MAX_BUFF_SLOTS):
        var slot = _buff_slots[i]
        if slot == null:
            continue
            
        # Since slot is TextureRect now, we set its texture for "empty/hollow" vs "filled" state
        # Actually, the base texture (hollow background) is set in the scene (button_hollow_buff_background.png).
        # We need to overlay the buff icon ON TOP of it.
        # But wait, TextureRect only holds ONE texture.
        # So we should use the child BuffIcon for the actual buff symbol.
        # And the slot itself (TextureRect) remains the background.
        
        # Reset visual state
        slot.modulate = Color.WHITE

        var lock_icon = slot.get_node_or_null("LockIcon")
        
        # Buff Icon is a child node we create/find
        var buff_icon_node = slot.get_node_or_null("BuffIcon")

        # Last 2 slots are always locked
        if i >= 4:
            # Locked state
            # If we want a specific locked texture, we could set slot.texture = locked_bg
            # Or just use the lock icon overlay
            if lock_icon:
                lock_icon.visible = true
            if buff_icon_node:
                buff_icon_node.visible = false
            slot.tooltip_text = ""
            continue
        
        # Ensure buff_icon_node exists
        if not buff_icon_node:
            buff_icon_node = TextureRect.new()
            buff_icon_node.name = "BuffIcon"
            buff_icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
            buff_icon_node.z_index = 1
            buff_icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            buff_icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            buff_icon_node.set_anchors_preset(Control.PRESET_FULL_RECT)
            slot.add_child(buff_icon_node)

        if i < buff_entries.size():
            # Active Buff
            var buff = buff_entries[i]
            var buff_id = buff.get("buff_id", "")
            var _waves_left = buff.get("duration", 0)
            
			# Set background to hollow (default) or active if we have a different active BG
            
            # Set Buff Icon
            var icon_path = _get_buff_icon_path(buff_id)
            if icon_path != "" and ResourceLoader.exists(icon_path):
                buff_icon_node.texture = load(icon_path)
                buff_icon_node.visible = true
            else:
                buff_icon_node.visible = false
                
            # Tooltip
            slot.tooltip_text = _get_buff_tooltip_text(buff_id, buff)
            
        else:
            # Empty Slot
            # Just show hollow background (already set in scene)
            # Hide buff icon overlay
            buff_icon_node.visible = false
            
            # If we were using "hollow_buff.png" as an overlay before, we might not need it 
            # if the button background itself is now the hollow texture.
            # But the user said: "slots in buffgrid in default state should be hollow_buff"
            # And also: "button_hollow_buff_background is the button background"
            # If they are different images, we might need to clarify.
            # Assuming button_hollow_buff_background.png IS the hollow look.
            
            # If we want to display "hollow_buff.png" (the icon?) inside the empty slot:
            # Check if hollow_buff.png is an ICON or a BACKGROUND.
            # User said: "update HeroCardBuffs.gd to use 'hollow_buff.png' as the empty state icon"
            # BUT previously said: "button_hollow_buff_background is how the button should look"
            
            # Let's assume the TextureRect slot has button_hollow_buff_background.png (set in scene).
            # And if it's empty, we show NOTHING on top (so just the hollow background).
            # OR if "hollow_buff.png" is a specific symbol for "empty", we show it.
            # Given the name "hollow_buff", it sounds like an empty placeholder icon.
            # Let's try to load it into buff_icon_node if empty.
            
            var hollow_icon_path = "res://assets/vfx/buffs/ui/hollow_buff.png"
            if ResourceLoader.exists(hollow_icon_path):
                    buff_icon_node.texture = load(hollow_icon_path)
                    buff_icon_node.visible = true
                    buff_icon_node.modulate = Color(1, 1, 1, 0.5) # Dim it
            else:
                    buff_icon_node.visible = false
                    
            slot.tooltip_text = ""

func _get_buff_icon_path(buff_id: String) -> String:
    match buff_id:
        "good_rest":
            return "res://assets/vfx/buffs/ui/tavern_buff.png"
    return ""

func _get_buff_tooltip_text(buff_id: String, buff_data: Dictionary) -> String:
    var duration = buff_data.get("duration", 0)
    var tooltip = ""
    
    match buff_id:
        "good_rest":
            var damage_bonus = buff_data.get("damage_bonus_percent", 0.0)
            var damage_reduction = buff_data.get("damage_reduction_percent", 0.0)
            var instant_heal = buff_data.get("instant_heal_percent", 0.0)
            
            tooltip = "Good Rest"
            var effects = []
            
            if damage_bonus > 0.0:
                effects.append("+%.0f%% Damage" % (damage_bonus * 100))
            if damage_reduction > 0.0:
                effects.append("+%.0f%% Defense" % (damage_reduction * 100))
            if instant_heal > 0.0:
                effects.append("+%.0f%% Heal" % (instant_heal * 100))
            
            if effects.size() > 0:
                tooltip += ": " + ", ".join(effects)
            
            tooltip += "\nDuration: %d battles" % duration
        _:
            # Fallback for unknown buffs
            tooltip = "%s\nDuration: %d battles" % [buff_id, duration]
    
    return tooltip
