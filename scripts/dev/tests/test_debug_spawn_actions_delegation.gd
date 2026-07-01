extends SceneTree

## Test that DebugSpawnActions.on_spawn_mob delegates to game_scene.debug_spawn_enemy_id
## instead of doing direct instantiate() which caused castle spawning bug

const DebugSpawnActionsScript := preload("res://scripts/ui/debug/modules/DebugSpawnActions.gd")


class FakeGameScene:
	extends Node

	var debug_spawn_calls: Array[Dictionary] = []

	func debug_spawn_enemy_id(enemy_id: String, count: int = 1) -> int:
		debug_spawn_calls.append({"enemy_id": enemy_id, "count": count})
		return count

	func has_method(method_name: String) -> bool:
		return method_name == "debug_spawn_enemy_id"


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var fake_game_scene := FakeGameScene.new()
	get_root().add_child(fake_game_scene)

	var actions = DebugSpawnActionsScript.new()
	actions.game_scene = fake_game_scene
	actions.setup(self)

	# TEST 1: Spawn GoblinBandit button should delegate with correct enemy_id
	actions.on_spawn_mob("GoblinBandit")
	if fake_game_scene.debug_spawn_calls.size() != 1:
		push_error("[test_debug_spawn_actions_delegation] Expected 1 spawn call, got %d" % fake_game_scene.debug_spawn_calls.size())
		quit(1)
		return

	var call1 = fake_game_scene.debug_spawn_calls[0]
	if call1.enemy_id != "goblin_bandit":
		push_error("[test_debug_spawn_actions_delegation] Expected enemy_id='goblin_bandit', got '%s'" % call1.enemy_id)
		quit(1)
		return

	# TEST 2: WallBuster should map correctly
	actions.on_spawn_mob("WallBuster")
	if fake_game_scene.debug_spawn_calls.size() != 2:
		push_error("[test_debug_spawn_actions_delegation] Expected 2 spawn calls, got %d" % fake_game_scene.debug_spawn_calls.size())
		quit(1)
		return

	var call2 = fake_game_scene.debug_spawn_calls[1]
	if call2.enemy_id != "wall_buster":
		push_error("[test_debug_spawn_actions_delegation] Expected enemy_id='wall_buster', got '%s'" % call2.enemy_id)
		quit(1)
		return

	# TEST 3: Dragon should map correctly
	actions.on_spawn_mob("Dragon")
	if fake_game_scene.debug_spawn_calls.size() != 3:
		push_error("[test_debug_spawn_actions_delegation] Expected 3 spawn calls, got %d" % fake_game_scene.debug_spawn_calls.size())
		quit(1)
		return

	var call3 = fake_game_scene.debug_spawn_calls[2]
	if call3.enemy_id != "dragon":
		push_error("[test_debug_spawn_actions_delegation] Expected enemy_id='dragon', got '%s'" % call3.enemy_id)
		quit(1)
		return

	# TEST 4: Invalid mob name should not call game_scene
	var prev_size = fake_game_scene.debug_spawn_calls.size()
	actions.on_spawn_mob("InvalidMobName")
	if fake_game_scene.debug_spawn_calls.size() != prev_size:
		push_error("[test_debug_spawn_actions_delegation] on_spawn_mob should not call game_scene for invalid names")
		quit(1)
		return

	print("[test_debug_spawn_actions_delegation] PASS")
	quit(0)
