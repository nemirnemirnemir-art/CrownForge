extends SceneTree

const MobRuntimeBridgeScript := preload("res://scripts/mob/modules/MobRuntimeBridge.gd")


class FakeBattleCore:
	extends Node

	var unregistered: Array[Node] = []

	func unregister_mob(mob: Node) -> void:
		unregistered.append(mob)


class FakeKingSpellState:
	extends Node

	var killed: int = 0

	func register_boss_killed(amount: int) -> void:
		killed += amount


class FakeMob:
	extends Node2D


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bridge = MobRuntimeBridgeScript.new()
	if bridge == null:
		push_error("[test_mob_runtime_bridge] failed to instantiate helper")
		quit(1)
		return

	var battle := FakeBattleCore.new()
	battle.name = "BattleCore"
	get_root().add_child(battle)
	var king := FakeKingSpellState.new()
	king.name = "KingSpellState"
	get_root().add_child(king)
	var mob := FakeMob.new()
	get_root().add_child(mob)

	bridge.setup(mob)
	bridge.set_overrides({"BattleCore": battle, "KingSpellState": king})
	if bridge.get_singleton("BattleCore") != battle:
		push_error("[test_mob_runtime_bridge] singleton lookup mismatch")
		quit(1)
		return
	bridge.unregister_from_battle_core()
	if battle.unregistered != [mob]:
		push_error("[test_mob_runtime_bridge] unregister flow mismatch")
		quit(1)
		return
	bridge.register_boss_killed()
	if king.killed != 1:
		push_error("[test_mob_runtime_bridge] boss kill registration mismatch")
		quit(1)
		return

	print("[test_mob_runtime_bridge] PASS")
	quit(0)
