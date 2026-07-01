extends RefCounted
class_name ArtifactState

static func get_int(state: Dictionary, artifact_id: String, key: String, default_value: int = 0) -> int:
	var s_val: Variant = state.get(artifact_id)
	if s_val == null or not (s_val is Dictionary):
		return default_value
	return int((s_val as Dictionary).get(key, default_value))

static func set_int(state: Dictionary, artifact_id: String, key: String, value: int) -> void:
	var s_val: Variant = state.get(artifact_id)
	var s: Dictionary
	if s_val == null or not (s_val is Dictionary):
		s = {}
		state[artifact_id] = s
	else:
		s = s_val as Dictionary
	s[key] = value

static func get_float(state: Dictionary, artifact_id: String, key: String, default_value: float = 0.0) -> float:
	var s_val: Variant = state.get(artifact_id)
	if s_val == null or not (s_val is Dictionary):
		return default_value
	return float((s_val as Dictionary).get(key, default_value))

static func set_float(state: Dictionary, artifact_id: String, key: String, value: float) -> void:
	var s_val: Variant = state.get(artifact_id)
	var s: Dictionary
	if s_val == null or not (s_val is Dictionary):
		s = {}
		state[artifact_id] = s
	else:
		s = s_val as Dictionary
	s[key] = value

static func run_periodic_timer(state: Dictionary, artifact_id: String, key: String, period: float, delta: float, trigger: Callable) -> void:
	if period <= 0.0:
		return
	var accum := get_float(state, artifact_id, key, 0.0) + delta
	while accum >= period:
		accum -= period
		trigger.call()
	set_float(state, artifact_id, key, accum)
