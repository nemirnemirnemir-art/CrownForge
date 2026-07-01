extends SceneTree

const HeroDamageFlowScript := preload("res://core/hero/HeroDamageFlow.gd")


class FakeCombat:
	extends RefCounted

	var result: Dictionary = {"died": false}
	var calls: Array = []

	func take_damage_with_amount(hero_id: String, amount: float) -> Dictionary:
		calls.append([hero_id, amount])
		return result.duplicate(true)


class FakeCounter:
	extends RefCounted

	var calls: Array = []

	func call0() -> void:
		calls.append([])

	func call1(a) -> void:
		calls.append([a])

	func call2(a, b) -> void:
		calls.append([a, b])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = HeroDamageFlowScript.new()
	if flow == null:
		push_error("[test_herocore_damage_flow] failed to instantiate helper")
		quit(1)
		return

	var combat := FakeCombat.new()
	var replacement := FakeCounter.new()
	var died_emitter := FakeCounter.new()
	var bus_emitter := FakeCounter.new()
	var remove_counter := FakeCounter.new()
	var update_counter := FakeCounter.new()

	combat.result = {"died": true}
	var died: bool = flow.apply_damage(
		combat,
		"hero_a",
		15.0,
		func(_hero_id: String, _amount: float) -> bool: return false,
		Callable(replacement, "call1"),
		Callable(died_emitter, "call1"),
		Callable(bus_emitter, "call1"),
		Callable(remove_counter, "call1"),
		Callable(update_counter, "call2")
	)
	if not died:
		push_error("[test_herocore_damage_flow] death result should be true")
		quit(1)
		return
	if replacement.calls.size() != 1 or remove_counter.calls.size() != 1:
		push_error("[test_herocore_damage_flow] death side effects were not forwarded")
		quit(1)
		return
	if update_counter.calls.size() != 0:
		push_error("[test_herocore_damage_flow] update callback must not run on death")
		quit(1)
		return

	combat.result = {"died": false}
	replacement.calls.clear()
	remove_counter.calls.clear()
	var survived: bool = flow.apply_damage(
		combat,
		"hero_b",
		5.0,
		func(_hero_id: String, _amount: float) -> bool: return false,
		Callable(replacement, "call1"),
		Callable(died_emitter, "call1"),
		Callable(bus_emitter, "call1"),
		Callable(remove_counter, "call1"),
		Callable(update_counter, "call2")
	)
	if survived:
		push_error("[test_herocore_damage_flow] non-lethal damage should return false")
		quit(1)
		return
	if update_counter.calls.is_empty():
		push_error("[test_herocore_damage_flow] hero update must run on non-lethal damage")
		quit(1)
		return

	print("[test_herocore_damage_flow] PASS")
	quit(0)
