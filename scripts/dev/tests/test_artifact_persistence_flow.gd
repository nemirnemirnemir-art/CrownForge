extends SceneTree

const PersistenceFlowScript := preload("res://core/artifacts/ArtifactPersistenceFlow.gd")


class FakeCatalog:
	extends RefCounted

	var known: Dictionary = {
		"mystic_stone": true,
		"mages_notebook": true,
	}

	func has_def(artifact_id: String) -> bool:
		return known.has(artifact_id)


class FakeCallbacks:
	extends RefCounted

	var reapply_calls: int = 0
	var refresh_calls: int = 0

	func reapply(active: Dictionary, runtime_applied: Dictionary, troop_core) -> void:
		reapply_calls += 1

	func refresh() -> void:
		refresh_calls += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = PersistenceFlowScript.new()
	if flow == null:
		push_error("[test_artifact_persistence_flow] failed to instantiate helper")
		quit(1)
		return

	var owned := {"mystic_stone": true, "mages_notebook": true}
	var active := {"mystic_stone": true}
	var state := {
		"mystic_stone": {"periodic_damage_accum": 0.4}
	}
	var save_data: Dictionary = flow.get_save_data(owned, active, state, 2, 1)
	state["mystic_stone"]["periodic_damage_accum"] = 0.8
	var saved_state: Dictionary = save_data.get("state", {})
	var saved_artifact_state: Dictionary = saved_state.get("mystic_stone", {})
	if absf(float(saved_artifact_state.get("periodic_damage_accum", -1.0)) - 0.4) > 0.001:
		push_error("[test_artifact_persistence_flow] save data must deep-copy artifact state")
		quit(1)
		return

	var catalog := FakeCatalog.new()
	var loaded: Dictionary = flow.load_save_data({
		"owned": ["mystic_stone", "unknown_artifact"],
		"active": ["mystic_stone", "mages_notebook", "unknown_artifact"],
		"state": {"mystic_stone": {"periodic_damage_accum": 0.25}},
		"pending_spell_choice_rewards": 3,
		"pending_legendary_spell_choice_rewards": 2,
	}, Callable(catalog, "has_def"))
	var loaded_owned: Dictionary = loaded.get("owned", {})
	var loaded_active: Dictionary = loaded.get("active", {})
	if not loaded_owned.has("mystic_stone") or loaded_owned.has("unknown_artifact"):
		push_error("[test_artifact_persistence_flow] owned normalization mismatch")
		quit(1)
		return
	if not loaded_active.has("mystic_stone") or loaded_active.has("mages_notebook") or loaded_active.has("unknown_artifact"):
		push_error("[test_artifact_persistence_flow] active normalization mismatch")
		quit(1)
		return
	if int(loaded.get("pending_spell_choice_rewards", -1)) != 3:
		push_error("[test_artifact_persistence_flow] pending spell count mismatch")
		quit(1)
		return
	if int(loaded.get("pending_legendary_spell_choice_rewards", -1)) != 2:
		push_error("[test_artifact_persistence_flow] pending legendary spell count mismatch")
		quit(1)
		return

	var reset_result: Dictionary = flow.reset_state()
	if not Dictionary(reset_result.get("owned", {})).is_empty():
		push_error("[test_artifact_persistence_flow] reset must clear owned state")
		quit(1)
		return
	if int(reset_result.get("pending_spell_choice_rewards", -1)) != 0:
		push_error("[test_artifact_persistence_flow] reset must clear pending spell rewards")
		quit(1)
		return

	var callbacks := FakeCallbacks.new()
	flow.reapply_active_effects(loaded_active, {}, null, Callable(callbacks, "reapply"), Callable(callbacks, "refresh"))
	if callbacks.reapply_calls != 1 or callbacks.refresh_calls != 1:
		push_error("[test_artifact_persistence_flow] reapply callbacks mismatch")
		quit(1)
		return

	print("[test_artifact_persistence_flow] PASS")
	quit(0)
