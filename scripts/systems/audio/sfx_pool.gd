extends Node
class_name SfxPool

@export var pool_size_global: int = 16
@export var pool_size_2d: int = 16

var _global: Array[AudioStreamPlayer] = []
var _spatial_2d: Array[AudioStreamPlayer2D] = []
var _next_global: int = 0
var _next_2d: int = 0

var _registry: Dictionary = {} # StringName -> SoundData

func _ready() -> void:
    for i in range(pool_size_global):
        var p := AudioStreamPlayer.new()
        p.name = "SfxGlobal_%d" % i
        p.bus = "SFX"
        add_child(p)
        _global.append(p)

    for i in range(pool_size_2d):
        var p2 := AudioStreamPlayer2D.new()
        p2.name = "Sfx2D_%d" % i
        p2.bus = "SFX"
        add_child(p2)
        _spatial_2d.append(p2)

func register_sound(data) -> void:
    if data == null:
        return
    if data.id == &"":
        return
    _registry[data.id] = data

func has_sound(id: StringName) -> bool:
    return _registry.has(id)

func play(id: StringName, position: Variant = null) -> void:
    var data = _registry.get(id)
    play_resource(data, position)

func play_resource(data, position: Variant = null) -> void:
    if data == null:
        return

    var stream: AudioStream = data.pick_stream()
    if stream == null:
        return

    var pitch: float = float(data.get_pitch())

    if position == null:
        var p := _get_next_global()
        _configure_player(p, data, stream, pitch)
        p.play()
        return

    if position is Vector2:
        var p2 := _get_next_2d()
        _configure_player_2d(p2, data, stream, pitch, position)
        p2.play()
        return

    var pg := _get_next_global()
    _configure_player(pg, data, stream, pitch)
    pg.play()

func _get_next_global() -> AudioStreamPlayer:
    if _global.is_empty():
        var p_new := AudioStreamPlayer.new()
        p_new.bus = "SFX"
        add_child(p_new)
        return p_new

    var p_existing := _global[_next_global]
    _next_global = (_next_global + 1) % _global.size()
    return p_existing

func _get_next_2d() -> AudioStreamPlayer2D:
    if _spatial_2d.is_empty():
        var p2_new := AudioStreamPlayer2D.new()
        p2_new.bus = "SFX"
        add_child(p2_new)
        return p2_new

    var p2_existing := _spatial_2d[_next_2d]
    _next_2d = (_next_2d + 1) % _spatial_2d.size()
    return p2_existing

func _configure_player(p: AudioStreamPlayer, data, stream: AudioStream, pitch: float) -> void:
    if p.playing:
        p.stop()
    p.stream = stream
    p.bus = String(data.bus) if ("bus" in data and data.bus != &"") else "SFX"
    p.volume_db = float(data.volume_db) if ("volume_db" in data) else 0.0
    p.pitch_scale = pitch

func _configure_player_2d(p: AudioStreamPlayer2D, data, stream: AudioStream, pitch: float, pos: Vector2) -> void:
    if p.playing:
        p.stop()
    p.stream = stream
    p.bus = String(data.bus) if ("bus" in data and data.bus != &"") else "SFX"
    p.volume_db = float(data.volume_db) if ("volume_db" in data) else 0.0
    p.pitch_scale = pitch
    p.global_position = pos
