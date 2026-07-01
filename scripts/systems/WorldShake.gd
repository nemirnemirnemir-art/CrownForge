extends Node
class_name WorldShake

@export var target_path: NodePath
@export var debug_enabled: bool = false

var _target: Node2D
var _base_pos: Vector2 = Vector2.ZERO

var _time_left: float = 0.0
var _amplitude: float = 0.0
var _frequency: float = 30.0
var _accum: float = 0.0
var _current_offset: Vector2 = Vector2.ZERO

var _last_debug_time: float = -999.0

func _ready() -> void:
    _target = get_node_or_null(target_path) as Node2D
    if _target:
        _base_pos = _target.position

func shake(amplitude: float = 6.0, duration: float = 0.12, frequency: float = 30.0) -> void:
    if _target == null:
        _target = get_node_or_null(target_path) as Node2D
        if _target:
            _base_pos = _target.position
        else:
            var now := Time.get_ticks_msec() / 1000.0
            if now - _last_debug_time > 1.0:
                _last_debug_time = now
                push_warning("[WorldShake] target not found: %s" % [target_path])
            return
    _base_pos = _target.position
    _time_left = maxf(_time_left, duration)
    _amplitude = maxf(_amplitude, amplitude)
    _frequency = maxf(1.0, frequency)
    var now2 := Time.get_ticks_msec() / 1000.0
    if debug_enabled and now2 - _last_debug_time > 0.75:
        _last_debug_time = now2
        print("[WorldShake] shake target=", _target.name, " base=", _base_pos, " amp=", _amplitude, " dur=", _time_left, " freq=", _frequency)

func _process(delta: float) -> void:
    if _target == null:
        _target = get_node_or_null(target_path) as Node2D
        if _target:
            _base_pos = _target.position
        else:
            return
    # If something external moved the target while we are not shaking, adopt new base position.
    if _time_left <= 0.0 and _current_offset.length() <= 0.01:
        _base_pos = _target.position

    if _time_left <= 0.0:
        _current_offset = _current_offset.lerp(Vector2.ZERO, minf(1.0, delta * 20.0))
        _target.position = _base_pos + _current_offset
        return

    _time_left = maxf(0.0, _time_left - delta)
    _accum += delta

    var step: float = 1.0 / _frequency
    if _accum >= step:
        _accum = fmod(_accum, step)
        _current_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _amplitude
        if debug_enabled:
            var now3 := Time.get_ticks_msec() / 1000.0
            if now3 - _last_debug_time > 0.25:
                _last_debug_time = now3
                print("[WorldShake] offset=", _current_offset, " time_left=", _time_left)

    var t: float = clampf(_time_left / maxf(0.001, _time_left + delta), 0.0, 1.0)
    _amplitude = lerpf(_amplitude, 0.0, (1.0 - t) * delta * 2.0)
    _target.position = _base_pos + _current_offset
