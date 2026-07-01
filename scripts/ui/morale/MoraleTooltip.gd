extends TextureRect
class_name MoraleTooltip

@onready var tooltip_panel: Control = $TooltipPanel
@onready var desc_label: Label = $TooltipPanel/Margin/VBox/Content/Description
@onready var factors_container: VBoxContainer = $TooltipPanel/Margin/VBox/FactorsList

# Exported textures for Inspector usage
@export var texture_0_20: Texture2D
@export var texture_21_40: Texture2D
@export var texture_41_60: Texture2D
@export var texture_61_80: Texture2D
@export var texture_81_100: Texture2D
@export var texture_101_plus: Texture2D

func _ready() -> void:
    if MoraleSystem:
        MoraleSystem.morale_updated.connect(_update_ui)
        _update_ui()
    
    var hover_area := $HoverArea if has_node("HoverArea") else null
    if hover_area:
        hover_area.mouse_entered.connect(_on_mouse_entered)
        hover_area.mouse_exited.connect(_on_mouse_exited)
    else:
        mouse_entered.connect(_on_mouse_entered)
        mouse_exited.connect(_on_mouse_exited)
    
    # Hide by default
    if tooltip_panel:
        tooltip_panel.visible = false

func _on_mouse_entered() -> void:
    if tooltip_panel:
        tooltip_panel.visible = true
        # Ensure it's on top
        z_index = 100

func _on_mouse_exited() -> void:
    if tooltip_panel:
        tooltip_panel.visible = false
        z_index = 0

func _update_ui() -> void:
    if not MoraleSystem: return
    
    var morale = MoraleSystem.get_total_morale()
    
    # 1. Update Root Texture (The Icon)
    var tex: Texture2D = texture_0_20
    
    if morale > 100:
        tex = texture_101_plus
    elif morale > 80:
        tex = texture_81_100
    elif morale > 60:
        tex = texture_61_80
    elif morale > 40:
        tex = texture_41_60
    elif morale > 20:
        tex = texture_21_40
    else:
        tex = texture_0_20
    
    if tex:
        texture = tex
        
    # 2. Update Description in Tooltip
    if tooltip_panel:
        var dmg_mod = MoraleSystem.get_damage_modifier() * 100.0
        var prod_mod = MoraleSystem.get_productivity_modifier() * 100.0
        desc_label.text = "Increases damage dealt by all units by %.1f%% and\nbuildings' productivity by %.2f%% per morale" % [0.5, 0.25]
        
        # 3. Update Factors in Tooltip
        for child in factors_container.get_children():
            child.queue_free()
            
        var breakdown = MoraleSystem.last_breakdown
        for source in breakdown:
            var val = breakdown[source]
            if val > 0:
                var label = Label.new()
                label.text = "%d from %s" % [val, source]
                label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1.0))
                label.add_theme_font_size_override("font_size", 21)
                factors_container.add_child(label)
        
        # Add Total line
        var total_label = Label.new()
        total_label.text = "Total Morale: %d" % morale
        total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        total_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1, 1.0)) # Dark Red
        total_label.add_theme_font_size_override("font_size", 24) 
        factors_container.add_child(HSeparator.new())
        factors_container.add_child(total_label)

        # Current Bonus Display
        var bonus_label = Label.new()
        bonus_label.text = "Current Bonuses: +%.1f%% DMG, +%.1f%% Speed" % [dmg_mod, prod_mod]
        bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        bonus_label.add_theme_color_override("font_color", Color(0.1, 0.4, 0.1, 1.0)) # Dark Green
        bonus_label.add_theme_font_size_override("font_size", 21)
        factors_container.add_child(bonus_label)
