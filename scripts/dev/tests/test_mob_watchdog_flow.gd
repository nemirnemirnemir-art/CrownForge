extends SceneTree

const MobWatchdogFlowScript := preload("res://scripts/mob/modules/MobWatchdogFlow.gd")


class FakeMovement:
	extends RefCounted

	var stuck: bool = true

	func check_stuck(_current_hp: float, _last_hp: float, _damage: float, _last_damage: float) -> bool:
		return stuck


class FakeCombat:
	extends RefCounted

	var total_damage: float = 4.0

	func get_total_damage_dealt() -> float:
		return total_damage


class FakeStateMachine:
	extends RefCounted

	var current_state = FakeState.new()
	var changed: Array[String] = []

	func change_state(name: String) -> void:
		changed.append(name)


class FakeState:
	extends RefCounted

	var name: String = "MobAttackState"


class FakeMob:
	extends RefCounted

	var current_health: float = 10.0
	var is_dead: bool = false
	var _last_hp: float = 0.0
	var _total_damage_dealt_last: float = 0.0


class FakeCounter:
	extends RefCounted

	var count: int = 0

	func bump() -> void:
		count += 1


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MobWatchdogFlowScript.new()
	if flow == null:
		push_error("[test_mob_watchdog_flow] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	var movement := FakeMovement.new()
	var combat := FakeCombat.new()
	var state_machine := FakeStateMachine.new()
	var end_attack := FakeCounter.new()

	flow.watchdog_tick(mob, movement, combat, state_machine, Callable(end_attack, "bump"))
	if end_attack.count != 1:
		push_error("[test_mob_watchdog_flow] watchdog must end attack when stuck")
		quit(1)
		return
	if state_machine.changed != ["MobMoveState"]:
		push_error("[test_mob_watchdog_flow] watchdog must push mob back to move state")
		quit(1)
		return

	print("[test_mob_watchdog_flow] PASS")
	quit(0)
