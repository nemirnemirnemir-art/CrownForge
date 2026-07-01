extends Node2D
class_name DenariiSellPopup

@export var rise_distance: float = 150.0
@export var sway_amplitude: float = 14.0
@export var sway_frequency: float = 8.0
@export var duration: float = 1.2

var _elapsed: float = 0.0
var _start_pos: Vector2 = Vector2.ZERO

func setup(_amount: int) -> void:
    pass

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _start_pos = global_position

func _process(delta: float) -> void:
    _elapsed += delta
    var t: float = clampf(_elapsed / maxf(0.001, duration), 0.0, 1.0)
    var eased: float = 1.0 - pow(1.0 - t, 2.0)

    global_position.y = _start_pos.y - rise_distance * eased
    global_position.x = _start_pos.x + sin(t * TAU * sway_frequency * 0.15) * sway_amplitude
    modulate.a = 1.0 - t

    if t >= 1.0:
        queue_free()
