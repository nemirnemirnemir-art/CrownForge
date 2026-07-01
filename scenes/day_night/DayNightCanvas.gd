extends CanvasModulate
class_name DayNightCanvas
## DayNightCanvas - Applies global lighting based on DayNightCycle

func _ready() -> void:
    # Connect to DayNightCycle if available
    if DayNightCycle:
        DayNightCycle.time_changed.connect(_on_time_changed)
        # Apply initial color
        color = DayNightCycle.get_current_color()

func _on_time_changed(_progress: float) -> void:
    if DayNightCycle:
        color = DayNightCycle.get_current_color()
