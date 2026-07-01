extends RefCounted
class_name SpellCaptureOrbitController


func advance_position(global_origin: Vector2, orbit_a: float, orbit_r: float, phase: float, jitter_px: float) -> Dictionary:
	var t := float(Time.get_ticks_msec()) * 0.001
	var jitter := Vector2(
		sin(t * 18.0 + phase),
		cos(t * 23.0 + phase)
	) * jitter_px
	var offset := Vector2(cos(orbit_a), sin(orbit_a)) * orbit_r
	return {
		"position": global_origin + offset + jitter,
		"orbit_a": orbit_a,
	}
