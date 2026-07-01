extends Node
## DayNightCycle - Autoload singleton for day/night cycle management
## Manages time progression and provides current lighting state

signal time_changed(progress: float)
signal phase_changed(phase: String)

## Cycle duration in seconds (15 minutes = 900 seconds)
@export var cycle_duration: float = 900.0

## Current time in seconds (0 to cycle_duration)
var _current_time: float = 0.0

## Is the cycle paused?
var _is_paused: bool = false

## Phase thresholds (as progress 0.0 - 1.0)
const PHASE_DAWN_START: float = 0.00
const PHASE_DAY_START: float = 0.10
const PHASE_DUSK_START: float = 0.60
const PHASE_NIGHT_START: float = 0.70

## Color gradient for CanvasModulate
var _color_gradient: Gradient

## Last emitted phase (to avoid spamming signal)
var _last_phase: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_gradient()
	# Start at dawn for a nice first impression
	_current_time = cycle_duration * 0.05

func _setup_gradient() -> void:
	_color_gradient = Gradient.new()
	# Clear default points
	_color_gradient.offsets = []
	_color_gradient.colors = []
	
	# Define color stops (progress -> color)
	# Midnight -> Dawn -> Morning -> Day -> Dusk -> Twilight -> Midnight
	_color_gradient.add_point(0.00, Color("#1a1c2c"))  # Midnight (deep blue)
	_color_gradient.add_point(0.05, Color("#ff7e5f"))  # Dawn start (coral orange)
	_color_gradient.add_point(0.10, Color("#fff4e0"))  # Morning (warm cream)
	_color_gradient.add_point(0.35, Color("#ffffff"))  # Day peak (pure white)
	_color_gradient.add_point(0.60, Color("#ffffff"))  # Day end (still white)
	_color_gradient.add_point(0.68, Color("#feb47b"))  # Sunset (bright orange)
	_color_gradient.add_point(0.75, Color("#8e44ad"))  # Dusk (purple)
	_color_gradient.add_point(0.85, Color("#2c3e50"))  # Twilight (cold blue-gray)
	_color_gradient.add_point(1.00, Color("#1a1c2c"))  # Midnight (loop back)

func _process(delta: float) -> void:
	if _is_paused:
		return
	
	# Use real delta if game is paused (Engine.time_scale = 0)
	# Day/night should continue even when game is paused
	var real_delta := delta
	if is_equal_approx(Engine.time_scale, 0.0):
		real_delta = 0.016  # ~60 FPS fallback
	
	_current_time += real_delta
	if _current_time >= cycle_duration:
		_current_time = fmod(_current_time, cycle_duration)
	
	var progress := get_time_progress()
	time_changed.emit(progress)
	
	# Check phase change
	var current_phase := get_current_phase()
	if current_phase != _last_phase:
		_last_phase = current_phase
		phase_changed.emit(current_phase)
		print("[DayNightCycle] Phase changed to: %s (%.1f%%)" % [current_phase, progress * 100.0])

## Get current time as progress (0.0 to 1.0)
func get_time_progress() -> float:
	return _current_time / cycle_duration

## Get current color for CanvasModulate
func get_current_color() -> Color:
	return _color_gradient.sample(get_time_progress())

## Get current phase name
func get_current_phase() -> String:
	var p := get_time_progress()
	if p < PHASE_DAY_START:
		return "dawn"
	elif p < PHASE_DUSK_START:
		return "day"
	elif p < PHASE_NIGHT_START:
		return "dusk"
	else:
		return "night"

## Check if it's currently night
func is_night() -> bool:
	return get_time_progress() >= PHASE_NIGHT_START or get_time_progress() < PHASE_DAWN_START + 0.02

## Manually set time progress (0.0 to 1.0)
func set_time(progress: float) -> void:
	progress = clampf(progress, 0.0, 1.0)
	_current_time = progress * cycle_duration
	time_changed.emit(progress)
	
	var current_phase := get_current_phase()
	if current_phase != _last_phase:
		_last_phase = current_phase
		phase_changed.emit(current_phase)

## Skip to specific phase
func skip_to_phase(phase: String) -> void:
	match phase.to_lower():
		"dawn":
			set_time(PHASE_DAWN_START + 0.02)
		"day":
			set_time(PHASE_DAY_START + 0.1)
		"dusk":
			set_time(PHASE_DUSK_START + 0.02)
		"night":
			set_time(PHASE_NIGHT_START + 0.05)
		_:
			push_warning("[DayNightCycle] Unknown phase: %s" % phase)

## Pause/resume the cycle
func set_paused(paused: bool) -> void:
	_is_paused = paused

func is_paused() -> bool:
	return _is_paused

## Get formatted time string (HH:MM format, 6:00 = dawn, 12:00 = noon, 18:00 = dusk, 0:00 = midnight)
func get_time_string() -> String:
	var progress := get_time_progress()
	# Map progress to 24-hour time (0.0 = 0:00, 0.5 = 12:00, 1.0 = 24:00)
	# But we want dawn at 6:00, so offset by 0.25 (6 hours)
	var hour_progress := fmod(progress + 0.25, 1.0)
	var total_hours := hour_progress * 24.0
	var hours := int(total_hours)
	var minutes := int((total_hours - hours) * 60.0)
	return "%02d:%02d" % [hours, minutes]
