extends SceneTree

const LifecycleScript := preload("res://scripts/hero/modules/HeroOnFieldLifecycle.gd")


class FakeStateMachine:
	extends RefCounted

	var changed: Array[String] = []

	func change_state(name: String) -> void:
		changed.append(name)


class FakeHealth:
	extends RefCounted

	var dead: bool = false
	var auto_potions: int = 0
	var bar_updates: int = 0

	func check_auto_potion_use() -> void:
		auto_potions += 1

	func update_health_bar() -> void:
		bar_updates += 1

	func is_dead() -> bool:
		return dead


class FakeMovement:
	extends RefCounted

	var is_returning: bool = false


class FakeDebug:
	extends RefCounted

	var ticks: int = 0

	func process_debug_tick(_delta: float) -> void:
		ticks += 1


class FakeVisuals:
	extends RefCounted

	var sync_calls: int = 0

	func sync_selection_outline_flip() -> void:
		sync_calls += 1


class FakeHero:
	extends RefCounted

	var current_target = Node2D.new()
	var hero_id: String = "militia"
	var velocity: Vector2 = Vector2.ZERO
	var is_stunned: bool = false
	var stun_timer: float = 0.0
	var _stun_prev_sm_process: bool = true
	var _stun_prev_sm_physics: bool = true


class FakeHeroCore:
	extends RefCounted

	var owner_bridge = null

	func remove_from_squad(hero_id: String) -> void:
		if owner_bridge:
			owner_bridge.remove_calls.append(hero_id)


class FakeRuntimeBridge:
	extends RefCounted

	var remove_calls: Array[String] = []
	var _hero_core := FakeHeroCore.new()

	func _init() -> void:
		_hero_core.owner_bridge = self

	func get_hero_core() -> RefCounted:
		return _hero_core


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var lifecycle = LifecycleScript.new()
	if lifecycle == null:
		push_error("[test_hero_on_field_lifecycle] failed to instantiate lifecycle")
		quit(1)
		return

	var hero := FakeHero.new()
	var health := FakeHealth.new()
	var debug := FakeDebug.new()
	var visuals := FakeVisuals.new()
	var state_machine := FakeStateMachine.new()
	var movement := FakeMovement.new()
	var runtime := FakeRuntimeBridge.new()
	var combat_updates := 0
	var target_checks := 0

	lifecycle.setup(hero)
	lifecycle.physics_tick(0.1, debug, health, state_machine, visuals, func(_delta: float) -> void: combat_updates += 1, func() -> void: target_checks += 1, 6)
	if debug.ticks != 1 or health.auto_potions != 1 or health.bar_updates != 1:
		push_error("[test_hero_on_field_lifecycle] health/debug tick mismatch")
		quit(1)
		return

	health.dead = true
	lifecycle.physics_tick(0.1, debug, health, state_machine, visuals, func(_delta: float) -> void: combat_updates += 1, func() -> void: target_checks += 1, 6)
	if state_machine.changed.is_empty() or state_machine.changed[-1] != "HeroDeathState":
		push_error("[test_hero_on_field_lifecycle] death must change to HeroDeathState")
		quit(1)
		return

	hero.current_target = Node2D.new()
	lifecycle.return_to_bridge(movement, state_machine)
	if not movement.is_returning or hero.current_target != null:
		push_error("[test_hero_on_field_lifecycle] return_to_bridge must clear target and set returning")
		quit(1)
		return
	if state_machine.changed[-1] != "HeroReturningHomeState":
		push_error("[test_hero_on_field_lifecycle] return_to_bridge must switch state")
		quit(1)
		return

	lifecycle.on_bridge_reached("militia", runtime, Callable(func() -> void: target_checks += 1))
	if runtime.remove_calls != ["militia"]:
		push_error("[test_hero_on_field_lifecycle] bridge reached must remove from squad")
		quit(1)
		return

	print("[test_hero_on_field_lifecycle] PASS")
	quit(0)
