extends Camera2D
class_name CameraShake2D

@export var debug_enabled: bool = false
@export var shake_decay: float = 5.0
@export var shake_time_speed: float = 20.0
@export var noise_frequency: float = 2.0
@export var return_speed: float = 10.5
@export var offset_limit: float = 64.0

var _shake_intensity: float = 0.0
var _active_shake_time: float = 0.0
var _shake_time: float = 0.0
var _noise := FastNoiseLite.new()
var _last_debug_time: float = 0.0

func _ready() -> void:
	randomize()
	_noise.frequency = noise_frequency
	_noise.seed = randi()

func _process(delta: float) -> void:
	if _active_shake_time > 0.0:
		_shake_time += delta * shake_time_speed
		_active_shake_time = maxf(0.0, _active_shake_time - delta)
		var offset_vec := _sample_noise() * _shake_intensity
		if offset_limit > 0.0:
			offset_vec = offset_vec.limit_length(offset_limit)
		offset = offset_vec
		_shake_intensity = maxf(_shake_intensity - shake_decay * delta, 0.0)
	else:
		offset = offset.lerp(Vector2.ZERO, minf(1.0, return_speed * delta))

func screen_shake(intensity: float, duration: float) -> void:
	if intensity <= 0.0 or duration <= 0.0:
		return
	randomize()
	_noise.seed = randi()
	_noise.frequency = noise_frequency
	_shake_intensity = intensity
	_active_shake_time = duration
	_shake_time = 0.0
	if debug_enabled:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_debug_time > 0.1:
			_last_debug_time = now
			print("[CameraShake2D] shake intensity=%.2f duration=%.2f" % [intensity, duration])

func stop_shake() -> void:
	_active_shake_time = 0.0
	_shake_intensity = 0.0

func _sample_noise() -> Vector2:
	return Vector2(
		_noise.get_noise_2d(_shake_time, 0.0),
		_noise.get_noise_2d(0.0, _shake_time)
	)
