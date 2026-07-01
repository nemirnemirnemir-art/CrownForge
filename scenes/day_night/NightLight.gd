extends PointLight2D
class_name NightLight
## NightLight - A light source that automatically turns on at night
## Place this scene in your game world as a lamp/torch/etc.

## Light configuration
@export var light_color: Color = Color(1.0, 0.9, 0.7, 1.0)  # Warm yellow
@export var light_energy_max: float = 1.0
@export var light_texture_scale: float = 1.0
@export var fade_duration: float = 2.0  # Seconds to fade in/out

## Internal state
var _target_energy: float = 0.0
var _is_night: bool = false

func _ready() -> void:
	# Set initial properties
	color = light_color
	energy = 0.0
	texture_scale = light_texture_scale
	
	# Connect to DayNightCycle
	if DayNightCycle:
		DayNightCycle.time_changed.connect(_on_time_changed)
		_update_light_state(DayNightCycle.get_time_progress())

func _process(delta: float) -> void:
	# Smoothly interpolate energy towards target
	if not is_equal_approx(energy, _target_energy):
		var speed := light_energy_max / fade_duration
		if energy < _target_energy:
			energy = minf(energy + speed * delta, _target_energy)
		else:
			energy = maxf(energy - speed * delta, _target_energy)

func _on_time_changed(progress: float) -> void:
	_update_light_state(progress)

func _update_light_state(progress: float) -> void:
	# Night is from 0.70 to 1.0 and 0.0 to ~0.05
	var should_be_on := progress >= 0.70 or progress < 0.05
	
	if should_be_on and not _is_night:
		_is_night = true
		_target_energy = light_energy_max
	elif not should_be_on and _is_night:
		_is_night = false
		_target_energy = 0.0

## Force light on/off (for debug)
func set_forced_on(on: bool) -> void:
	_target_energy = light_energy_max if on else 0.0
