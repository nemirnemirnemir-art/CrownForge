extends SceneTree

const OwnershipFlowScript := preload("res://core/artifacts/ArtifactOwnershipFlow.gd")


class FakeCatalog:
	extends RefCounted

	var known: Dictionary = {
		"mystic_stone": true,
		"mages_notebook": true,
	}

	func has_def(artifact_id: String) -> bool:
		return known.has(artifact_id)


class FakePickupRuntime:
	extends RefCounted

	var activated: Array = []
	var deactivated: Array = []

	func apply_pickup(artifact_id: String, state: Dictionary) -> Variant:
		if artifact_id == "mages_notebook":
			return {
				"queue_spell": true,
				"count": 2,
				"legendary_only": false,
				"pending_rewards": [{"type": "resource_choice", "amount": 25}],
			}
		if artifact_id == "mystic_stone":
			state[artifact_id] = {"periodic_damage_accum": 0.0}
		return null

	func queue_spell_rewards(pending: int, pending_legendary: int, count: int, legendary_only: bool) -> Dictionary:
		if legendary_only:
			return {"pending": pending, "pending_legendary": pending_legendary + count}
		return {"pending": pending + count, "pending_legendary": pending_legendary}

	func on_activated(artifact_id: String, state: Dictionary, runtime_class_bonus_applied: Dictionary, troop_core) -> void:
		activated.append(artifact_id)

	func on_deactivated(artifact_id: String, state: Dictionary, runtime_class_bonus_applied: Dictionary, troop_core) -> void:
		deactivated.append(artifact_id)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = OwnershipFlowScript.new()
	if flow == null:
		push_error("[test_artifact_ownership_flow] failed to instantiate helper")
		quit(1)
		return

	var owned: Dictionary = {}
	var active: Dictionary = {}
	var state: Dictionary = {}
	var runtime_class_bonus_applied: Dictionary = {"mystic_stone": true}
	var catalog := FakeCatalog.new()
	var runtime := FakePickupRuntime.new()

	var missing_result: Dictionary = flow.add_artifact("unknown_artifact", owned, state, 0, 0, Callable(catalog, "has_def"), Callable(runtime, "apply_pickup"), Callable(runtime, "queue_spell_rewards"))
	if bool(missing_result.get("added", true)):
		push_error("[test_artifact_ownership_flow] unknown artifact should not be added")
		quit(1)
		return

	var add_result: Dictionary = flow.add_artifact("mages_notebook", owned, state, 1, 0, Callable(catalog, "has_def"), Callable(runtime, "apply_pickup"), Callable(runtime, "queue_spell_rewards"))
	if not bool(add_result.get("added", false)) or not owned.has("mages_notebook"):
		push_error("[test_artifact_ownership_flow] add_artifact should own valid artifact")
		quit(1)
		return
	if int(add_result.get("pending_spell_choice_rewards", -1)) != 3:
		push_error("[test_artifact_ownership_flow] queued spell rewards mismatch")
		quit(1)
		return
	var pending_rewards: Array = add_result.get("pending_rewards", [])
	if pending_rewards.size() != 1:
		push_error("[test_artifact_ownership_flow] pending rewards passthrough mismatch")
		quit(1)
		return

	var activate_result: Dictionary = flow.set_active("mages_notebook", true, owned, active, state, runtime_class_bonus_applied, null, Callable(runtime, "on_activated"), Callable(runtime, "on_deactivated"))
	if not bool(activate_result.get("changed", false)) or not active.has("mages_notebook"):
		push_error("[test_artifact_ownership_flow] activation should change active state")
		quit(1)
		return
	if runtime.activated.size() != 1:
		push_error("[test_artifact_ownership_flow] activation callback mismatch")
		quit(1)
		return

	var remove_result: Dictionary = flow.remove_artifact("mages_notebook", owned, active, state, runtime_class_bonus_applied, null, Callable(runtime, "on_activated"), Callable(runtime, "on_deactivated"))
	if not bool(remove_result.get("removed", false)):
		push_error("[test_artifact_ownership_flow] remove_artifact should report removal")
		quit(1)
		return
	if owned.has("mages_notebook") or active.has("mages_notebook"):
		push_error("[test_artifact_ownership_flow] remove_artifact should clear ownership and active state")
		quit(1)
		return
	if runtime.deactivated.size() != 1:
		push_error("[test_artifact_ownership_flow] deactivation callback mismatch")
		quit(1)
		return

	print("[test_artifact_ownership_flow] PASS")
	quit(0)
