extends RefCounted
class_name ArtifactPendingRewardFlow


func process_pending_rewards(state: Dictionary, runtime_flow) -> void:
	if int(state.get("pending", 0)) <= 0 and int(state.get("pending_legendary", 0)) <= 0:
		return
	var result = runtime_flow.process_pending_spell_choice_rewards(int(state.get("pending", 0)), int(state.get("pending_legendary", 0)))
	state["pending"] = int(result.pending)
	state["pending_legendary"] = int(result.pending_legendary)


func enqueue_pending_rewards(runtime_target_bridge, rewards: Variant, game_scene) -> void:
	runtime_target_bridge.enqueue_pending_rewards(rewards, game_scene)
