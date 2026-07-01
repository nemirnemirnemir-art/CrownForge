extends SceneTree

const ArtifactRuntimeShellFlowScript := preload("res://core/artifacts/ArtifactRuntimeShellFlow.gd")
const ArtifactFriendlyDeathBuffDomainScript := preload("res://core/artifacts/ArtifactFriendlyDeathBuffDomain.gd")


class DummyHero:
	extends Node2D

	var hero_id: String = ""
	var is_dead: bool = false
	var speed_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0


class FakeEventBus:
	extends Node

	signal enemy_killed(enemy_id: String)
	signal wave_started(wave_number: int)
	signal hero_died(hero_id: String)
	signal game_loaded


class FakeCounter:
	extends RefCounted

	var calls: Array = []

	func call0() -> void:
		calls.append([])

	func call1(a) -> void:
		calls.append([a])


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = ArtifactRuntimeShellFlowScript.new()
	if flow == null:
		push_error("[test_artifact_runtime_shell_flow] failed to instantiate helper")
		quit(1)
		return

	var bus := FakeEventBus.new()
	get_root().add_child(bus)
	var enemy := FakeCounter.new()
	var wave := FakeCounter.new()
	var hero := FakeCounter.new()
	var loaded := FakeCounter.new()
	flow.connect_event_bus(bus, Callable(enemy, "call1"), Callable(wave, "call1"), Callable(hero, "call1"), Callable(loaded, "call0"))
	bus.enemy_killed.emit("mob")
	bus.wave_started.emit(4)
	bus.hero_died.emit("h")
	bus.game_loaded.emit()
	if enemy.calls != [["mob"]] or wave.calls != [[4]] or hero.calls != [["h"]] or loaded.calls.size() != 1:
		push_error("[test_artifact_runtime_shell_flow] event routing mismatch")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var dead_hero := DummyHero.new()
	dead_hero.hero_id = "fallen_hero"
	dead_hero.is_dead = true
	dead_hero.add_to_group("hero")
	root.add_child(dead_hero)

	var living_hero := DummyHero.new()
	living_hero.hero_id = "living_hero"
	living_hero.add_to_group("hero")
	root.add_child(living_hero)

	await process_frame
	ArtifactFriendlyDeathBuffDomainScript.on_friendly_troop_died({"hand_of_the_avenged": true}, "fallen_hero")
	await process_frame

	if absf(living_hero.speed_multiplier - 1.3) > 0.001:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must buff living ally move speed")
		quit(1)
		return
	if absf(living_hero.attack_speed_multiplier - 1.3) > 0.001:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must buff living ally attack speed")
		quit(1)
		return
	if living_hero.get_node_or_null("HandOfTheAvengedIcon") == null:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must add a status icon")
		quit(1)
		return

	await create_timer(6.2).timeout
	await process_frame

	if absf(living_hero.speed_multiplier - 1.0) > 0.001:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must restore move speed")
		quit(1)
		return
	if absf(living_hero.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must restore attack speed")
		quit(1)
		return
	if living_hero.get_node_or_null("HandOfTheAvengedIcon") != null:
		push_error("[test_artifact_runtime_shell_flow] hand_of_the_avenged must remove its status icon")
		quit(1)
		return

	print("[test_artifact_runtime_shell_flow] PASS")
	quit(0)
