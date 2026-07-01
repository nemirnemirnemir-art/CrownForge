extends RefCounted
class_name ArtifactDeathSummonDomain

const COOLDOWN_KEY := "death_trigger_cooldown_remaining"
const TRIGGER_ORDER: Array[String] = [
	"scarecrow_hat",
	"indescribable_figurine",
]
const TRIGGER_SPECS := {
	"scarecrow_hat": {
		"artifact_id": "scarecrow_hat",
		"type": "effect",
		"scene_path": "res://scenes/spells/effects/BladecasterEffect.tscn",
		"cooldown": 40.0,
	},
	"indescribable_figurine": {
		"artifact_id": "indescribable_figurine",
		"type": "recruit_unit",
		"unit_id": "cacodaemon",
		"cooldown": 140.0,
	},
}

static func tick(active: Dictionary, state: Dictionary, delta: float) -> void:
	if delta <= 0.0:
		return
	for artifact_id in TRIGGER_ORDER:
		if not active.has(artifact_id):
			continue
		var cooldown_remaining := ArtifactState.get_float(state, artifact_id, COOLDOWN_KEY, 0.0)
		if cooldown_remaining <= 0.0:
			continue
		ArtifactState.set_float(state, artifact_id, COOLDOWN_KEY, maxf(0.0, cooldown_remaining - delta))

static func collect_death_triggers(active: Dictionary, state: Dictionary) -> Array:
	var specs: Array = []
	for artifact_id in TRIGGER_ORDER:
		if not active.has(artifact_id):
			continue
		var spec: Dictionary = TRIGGER_SPECS.get(artifact_id, {})
		if spec.is_empty():
			continue
		var cooldown_remaining := ArtifactState.get_float(state, artifact_id, COOLDOWN_KEY, 0.0)
		if cooldown_remaining > 0.0:
			continue
		specs.append(spec.duplicate(true))
		var cooldown := maxf(0.0, float(spec.get("cooldown", 0.0)))
		if cooldown > 0.0:
			ArtifactState.set_float(state, artifact_id, COOLDOWN_KEY, cooldown)
	return specs
