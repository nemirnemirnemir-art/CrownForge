extends Node2D


var _travel := Vector2.ZERO
var _color := Color(1.0, 0.85, 0.35, 1.0)
var _line_width := 3.0
var _head_radius := 4.0
var _impact_radius := 10.0
var _travel_duration := 0.16
var _impact_duration := 0.08
var _elapsed := 0.0


func launch(start_pos, end_pos, shot_color, line_width, speed, head_radius, impact_radius) -> void:
    global_position = start_pos
    _travel = end_pos - start_pos
    _color = shot_color
    _line_width = line_width
    _head_radius = head_radius
    _impact_radius = impact_radius

    var distance := _travel.length()
    if speed > 0.0:
        _travel_duration = clampf(distance / speed, 0.05, 0.2)
    else:
        _travel_duration = 0.12

    _elapsed = 0.0
    queue_redraw()


func _process(delta) -> void:
    _elapsed += delta

    if _elapsed >= _travel_duration + _impact_duration:
        queue_free()
        return

    queue_redraw()


func _draw() -> void:
    var progress := 1.0
    if _travel_duration > 0.0:
        progress = clampf(_elapsed / _travel_duration, 0.0, 1.0)

    var head_pos := _travel * progress

    if progress < 1.0:
        var beam_color := _color
        beam_color.a = lerpf(0.95, 0.55, progress)
        draw_line(Vector2.ZERO, head_pos, beam_color, _line_width, true)

        var head_color := _color
        head_color.a = 1.0
        draw_circle(head_pos, _head_radius, head_color)
        return

    var impact_progress := 1.0
    if _impact_duration > 0.0:
        impact_progress = clampf((_elapsed - _travel_duration) / _impact_duration, 0.0, 1.0)

    var flash_color := _color
    flash_color.a = 1.0 - impact_progress
    draw_circle(_travel, lerpf(_head_radius, _impact_radius, impact_progress), flash_color)
