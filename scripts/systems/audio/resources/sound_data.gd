extends Resource
class_name SoundData

@export var id: StringName = &""
@export var streams: Array[AudioStream] = []
@export var bus: StringName = &"SFX"
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var pitch_random_range: float = 0.0

func pick_stream() -> AudioStream:
    if streams.is_empty():
        return null
    if streams.size() == 1:
        return streams[0]
    return streams[randi() % streams.size()]

func get_pitch() -> float:
    var p := maxf(0.01, pitch_scale)
    if pitch_random_range <= 0.0:
        return p
    var r := randf_range(-pitch_random_range, pitch_random_range)
    return maxf(0.01, p * (1.0 + r))
