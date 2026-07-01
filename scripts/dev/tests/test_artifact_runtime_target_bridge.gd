extends SceneTree

const BridgeScript := preload("res://core/artifacts/ArtifactRuntimeTargetBridge.gd")


class FakeGameScene:
	extends Node

	var queued_rewards: Array = []

	func _init() -> void:
		add_to_group("game_scene")

	func enqueue_pending_reward(reward: Dictionary) -> void:
		queued_rewards.append(reward)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = BridgeScript.new()
	if bridge == null:
		push_error("[test_artifact_runtime_target_bridge] failed to instantiate helper")
		quit(1)
		return

	var troop_bonus_core := Node.new()
	troop_bonus_core.name = "TroopBonusCore"
	root.add_child(troop_bonus_core)

	var game_scene := FakeGameScene.new()
	root.add_child(game_scene)
	current_scene = game_scene

	var resolved_troop_bonus_core := bridge.get_troop_bonus_core(self)
	if resolved_troop_bonus_core == null or String(resolved_troop_bonus_core.name) != "TroopBonusCore":
		push_error("[test_artifact_runtime_target_bridge] troop bonus core lookup mismatch")
		quit(1)
		return
	if bridge.get_game_scene(self) != game_scene:
		push_error("[test_artifact_runtime_target_bridge] game scene lookup mismatch")
		quit(1)
		return

	bridge.enqueue_pending_rewards([
		{"type": "resource_choice", "amount": 15},
		"skip_me",
		{"type": "spell_grant", "spell_id": "magic_ball"},
	], game_scene)
	if game_scene.queued_rewards.size() != 2:
		push_error("[test_artifact_runtime_target_bridge] pending reward enqueue mismatch")
		quit(1)
		return

	print("[test_artifact_runtime_target_bridge] PASS")
	quit(0)
