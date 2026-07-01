extends SceneTree

const ArtifactPendingRewardFlowScript := preload("res://core/artifacts/ArtifactPendingRewardFlow.gd")


class FakeRuntimeFlow:
	extends RefCounted

	var result = {"pending": 0, "pending_legendary": 0}

	func process_pending_spell_choice_rewards(_p: int, _l: int):
		return result


class FakeRuntimeBridge:
	extends RefCounted

	var enqueued: Array = []

	func enqueue_pending_rewards(rewards: Variant, _game_scene) -> void:
		enqueued.append(rewards)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = ArtifactPendingRewardFlowScript.new()
	if flow == null:
		push_error("[test_artifact_pending_reward_flow] failed to instantiate helper")
		quit(1)
		return

	var state := {"pending": 2, "pending_legendary": 1}
	var runtime := FakeRuntimeFlow.new()
	runtime.result = {"pending": 1, "pending_legendary": 0}
	flow.process_pending_rewards(state, runtime)
	if int(state["pending"]) != 1 or int(state["pending_legendary"]) != 0:
		push_error("[test_artifact_pending_reward_flow] pending reward state mismatch")
		quit(1)
		return

	var bridge := FakeRuntimeBridge.new()
	flow.enqueue_pending_rewards(bridge, [{"id": "spell"}], null)
	if bridge.enqueued.size() != 1:
		push_error("[test_artifact_pending_reward_flow] enqueue pending rewards mismatch")
		quit(1)
		return

	print("[test_artifact_pending_reward_flow] PASS")
	quit(0)
