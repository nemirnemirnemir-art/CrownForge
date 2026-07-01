extends Control

## Debug menu overlay - Toggle with V key
## Requires "scenes/ui/DebugMenu.tscn" structure in GameScene

@onready var panel: Panel = $Panel
var buttons_container: VBoxContainer # Init securely in _ready

# Scene references
var _time_slider: HSlider
var _time_label: Label
var _pause_checkbox: CheckBox

func _ready() -> void:
    visible = false
    
    # Try to find container in new scene structure
    buttons_container = get_node_or_null("Panel/ScrollContainer/VBoxContainer")
    
    # Check if we have the new Scene structure (from .tscn)
    if buttons_container and buttons_container.has_node("DayNightSection"):
        var day_night = buttons_container.get_node("DayNightSection")
        _time_label = day_night.get_node_or_null("TimeLabel")
        var slider_box = day_night.get_node("SliderBox")
        if slider_box: _time_slider = slider_box.get_node_or_null("TimeSlider")
        _pause_checkbox = day_night.get_node_or_null("PauseCheck")
        
        _connect_signals()

        # Morale Debug Button
        var m_btn = Button.new()
        m_btn.text = "+100 Morale (Debug)"
        m_btn.pressed.connect(func(): if MoraleSystem: MoraleSystem.add_debug_morale(100))
        buttons_container.add_child(m_btn)
    else:
        # Invalid structure (Old GameScene node without .tscn)
        # Self-destruct to avoid "Gray Box" artifact
        push_warning("[DebugMenu] Legacy node detected. Removing self. Please instance 'res://scenes/ui/debug/DebugMenu.tscn' in GameScene.")
        queue_free()

func _connect_signals() -> void:
    if _time_slider:
        if not _time_slider.value_changed.is_connected(_on_time_slider_changed):
            _time_slider.value_changed.connect(_on_time_slider_changed)
            
    if _pause_checkbox:
        if not _pause_checkbox.toggled.is_connected(_on_pause_toggled):
            _pause_checkbox.toggled.connect(_on_pause_toggled)

func _process(_delta: float) -> void:
    if visible and _time_label and DayNightCycle:
        var progress := DayNightCycle.get_time_progress()
        var time_str := DayNightCycle.get_time_string()
        var phase := DayNightCycle.get_current_phase()
        _time_label.text = "Time: %s (%s, %.0f%%)" % [time_str, phase.capitalize(), progress * 100.0]
        
        # Update slider without triggering signal
        if _time_slider and not _time_slider.has_focus():
            _time_slider.set_value_no_signal(progress)

func _on_time_slider_changed(value: float) -> void:
    if DayNightCycle:
        DayNightCycle.set_time(value)

func _on_phase_button_pressed(phase: String) -> void:
    if DayNightCycle:
        DayNightCycle.skip_to_phase(phase)

func _on_pause_toggled(pressed: bool) -> void:
    if DayNightCycle:
        DayNightCycle.set_paused(pressed)


