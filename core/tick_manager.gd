extends Node
## TickManager - Global game speed controller
## Provides game speed scaling (pause, 1x, 2x, 3x) for all time-dependent systems

signal speed_changed(new_speed: float)

## Current speed multiplier: 0.0 = paused, 1.0 = normal, 2.0 = double, 3.0 = triple
var speed_scale: float = 1.0:
	set(value):
		var old_value := speed_scale
		speed_scale = clampf(value, 0.0, 3.0)
		
		# Apply to global engine time scale
		# Note: We set it to roughly the speed_scale, but for 0 (pause), we set it to 0.
		Engine.time_scale = speed_scale
		
		if old_value != speed_scale:
			speed_changed.emit(speed_scale)
			# print("[TickManager] Speed changed: %.1fx (Engine.time_scale=%.1f)" % [speed_scale, Engine.time_scale])

## Returns true if game is paused (speed_scale == 0)
var is_paused: bool:
	get: return speed_scale == 0.0

## Returns delta scaled by current speed multiplier
## NOTE: If Engine.time_scale is used, 'delta' in _process is ALREADY scaled.
## So we generally don't need to multiply again unless we are using unscaled time.
## However, to be safe for scripts restricting their own logic, we just return delta implied.
## BUT, if we want to support "manual" ticking while Engine is normal, we keep this.
## Since user wants "Game Speed", Engine.time_scale is best. 
## We'll make this return delta * 1.0 if we rely on Engine.time_scale, OR we keep it for legacy.
## Better: If Engine.time_scale is modified, 'delta' passed to _process is already small/zero.
## If we multiply AGAIN, we get quadratic slowdown. 
## So, get_scaled_delta should just return 'delta' if we are using Engine.time_scale.
## Wait! If I change this, I must verify existing calls.
## Existing calls: tick_production(scaled_delta).
## If Engine.time_scale = 0.5, delta is 0.008 (instead of 0.016).
## If I return delta * speed_scale (0.5), I get 0.004. Effectively 0.25x speed.
## FIX: get_scaled_delta should now simply return `delta` because `delta` is already scaled by Engine!
## EXCEPTION: If we needed to scale something that uses wall-clock time.
func get_scaled_delta(delta: float) -> float:
	return delta
	# WAS: return delta * speed_scale hiding double-scaling bug

## Set speed to specific multiplier (0, 1, 2, or 3)
func set_speed(multiplier: float) -> void:
	self.speed_scale = multiplier

## Pause the game (speed = 0)
func pause() -> void:
	self.speed_scale = 0.0

## Resume to normal speed if paused
func resume() -> void:
	if speed_scale == 0.0:
		self.speed_scale = 1.0

## Toggle pause state
func toggle_pause() -> void:
	if is_paused:
		resume()
	else:
		pause()

## Get current speed as integer (0, 1, 2, 3)
func get_speed_index() -> int:
	return int(speed_scale)
