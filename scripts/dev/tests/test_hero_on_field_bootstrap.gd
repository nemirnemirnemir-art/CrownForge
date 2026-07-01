extends SceneTree

const BootstrapScript := preload("res://scripts/hero/modules/HeroOnFieldBootstrap.gd")
const HeroOnFieldScript := preload("res://scripts/hero/HeroOnField.gd")
const HeroOnFieldDebugScript := preload("res://scripts/hero/modules/HeroOnFieldDebug.gd")


class FakeStats:
	extends RefCounted

	var determined: Array[String] = []
	var projectile_scene = null
	var attack_range: float = 25.0
	var max_range: float = 200.0
	var preferred_range: float = 0.0
	var min_range: float = 0.0
	var is_melee: bool = true
	var projectile_speed: float = 400.0
	var projectile_type: String = "arrow"

	func determine_combat_type(hero_id: String) -> void:
		determined.append(hero_id)


class FakeMovement:
	extends RefCounted

	var applied: Array = []

	func setup(_hero, _debug) -> void:
		pass

	func apply_speed_modifiers(stats, is_melee: bool, override_move_speed: float) -> void:
		applied.append([stats, is_melee, override_move_speed])


class FakeVisuals:
	extends RefCounted

	var setup_calls: int = 0
	var ensure_calls: int = 0
	var hero_id: String = ""

	func setup(_hero, _id: String) -> void:
		setup_calls += 1

	func ensure_anim_dead(_hero) -> void:
		ensure_calls += 1


class FakeAnimations:
	extends RefCounted

	var started: int = 0

	func setup(_hero, _sprite, _hero_id: String, _state_machine) -> void:
		pass

	func start_initial_animation() -> void:
		started += 1


class FakeCombatAI:
	extends RefCounted

	func setup(_hero, _stats) -> void:
		pass


class FakeHealth:
	extends RefCounted

	func initialize(_hero, _hero_id: String, _bar) -> void:
		pass


class FakeStateMachine:
	extends Node


class FakeDog:
	extends Node

	var checked: int = 0

	func check_and_spawn_dog() -> void:
		checked += 1


class FakeDebug:
	extends HeroOnFieldDebugScript

	var stuck_checks: int = 0

	func _init(hero_ref: Node2D = null) -> void:
		super(hero_ref)

	func check_stuck() -> void:
		stuck_checks += 1


class FakeHero:
	extends CharacterBody2D

	var hero_id: String = "militia"
	var override_move_speed: float = 88.0
	var override_attack_range: float = 50.0
	var override_projectile_speed: float = 700.0
	var override_projectile_type: String = "bolt"
	var patrol_center: Vector2 = Vector2.ZERO
	var animation_sprite: AnimatedSprite2D = null
	var health_bar: ProgressBar = null
	var _projectile_scene_override = null
	var _state_machine = null
	var move_speed: float = 0.0
	var _debug: FakeDebug = null

	func _init() -> void:
		_debug = FakeDebug.new(self)
		var sprite := AnimatedSprite2D.new()
		sprite.name = "AnimationSprite2D"
		add_child(sprite)
		animation_sprite = sprite
		var bar := ProgressBar.new()
		bar.name = "HealthBar"
		add_child(bar)
		health_bar = bar
		var sm := FakeStateMachine.new()
		sm.name = "HeroStateMachine"
		add_child(sm)
		var dog := FakeDog.new()
		dog.name = "DogComponent"
		add_child(dog)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var artifact_core := get_root().get_node_or_null("ArtifactCore")
	if artifact_core == null:
		push_error("[test_hero_on_field_bootstrap] ArtifactCore autoload must exist")
		quit(1)
		return
	artifact_core.call("reset")

	var bootstrap = BootstrapScript.new()
	if bootstrap == null:
		push_error("[test_hero_on_field_bootstrap] failed to instantiate bootstrap")
		artifact_core.call("reset")
		quit(1)
		return

	var hero := FakeHero.new()
	get_root().add_child(hero)
	var stats := FakeStats.new()
	var movement := FakeMovement.new()
	var visuals := FakeVisuals.new()
	var animations := FakeAnimations.new()
	var combat := FakeCombatAI.new()
	var health := FakeHealth.new()

	bootstrap.setup(hero)
	var watchdog := hero.get_node_or_null("WatchdogTimer") as Timer
	if watchdog == null:
		push_error("[test_hero_on_field_bootstrap] watchdog timer was not created")
		artifact_core.call("reset")
		quit(1)
		return
	if not watchdog.autostart or absf(watchdog.wait_time - 1.0) > 0.01:
		push_error("[test_hero_on_field_bootstrap] watchdog timer config changed")
		artifact_core.call("reset")
		quit(1)
		return
	watchdog.timeout.emit()
	if hero._debug.stuck_checks != 1:
		push_error("[test_hero_on_field_bootstrap] watchdog timer must still trigger debug stuck checks")
		artifact_core.call("reset")
		quit(1)
		return
	bootstrap.setup_visual_nodes(hero)
	bootstrap.setup_physics(hero)
	var state_machine = bootstrap.setup_state_machine(hero)
	bootstrap.initialize_runtime(hero, stats, movement, visuals, animations, combat, health, state_machine)

	if state_machine == null:
		push_error("[test_hero_on_field_bootstrap] state machine not resolved")
		artifact_core.call("reset")
		quit(1)
		return
	if stats.determined != ["militia"]:
		push_error("[test_hero_on_field_bootstrap] combat type not determined")
		artifact_core.call("reset")
		quit(1)
		return
	if movement.applied.is_empty():
		push_error("[test_hero_on_field_bootstrap] movement modifiers not applied")
		artifact_core.call("reset")
		quit(1)
		return
	if absf(stats.attack_range - 50.0) > 0.01 or absf(stats.projectile_speed - 700.0) > 0.01 or stats.projectile_type != "bolt":
		push_error("[test_hero_on_field_bootstrap] overrides were not applied")
		artifact_core.call("reset")
		quit(1)
		return
	if animations.started != 1:
		push_error("[test_hero_on_field_bootstrap] initial animation not started")
		artifact_core.call("reset")
		quit(1)
		return
	var dog = hero.get_node("DogComponent") as FakeDog
	if dog.checked != 1:
		push_error("[test_hero_on_field_bootstrap] dog logic was not triggered")
		artifact_core.call("reset")
		quit(1)
		return

	var real_hero := HeroOnFieldScript.new()
	real_hero._bootstrap = bootstrap
	real_hero._debug = FakeDebug.new(real_hero)
	get_root().add_child(real_hero)
	real_hero._setup_watchdog()
	var real_watchdog := real_hero.get_node_or_null("WatchdogTimer") as Timer
	if real_watchdog == null:
		push_error("[test_hero_on_field_bootstrap] HeroOnField facade wrapper must create watchdog through bootstrap")
		artifact_core.call("reset")
		quit(1)
		return
	if real_watchdog.timeout.get_connections().is_empty():
		push_error("[test_hero_on_field_bootstrap] HeroOnField facade wrapper must keep watchdog timeout wired")
		artifact_core.call("reset")
		quit(1)
		return

	real_hero.is_temporary_summon = true
	real_hero._summon_max_hp = 20.0
	real_hero._summon_current_hp = 20.0
	artifact_core.call("load_save_data", {"owned": ["indestructible_shield"], "active": ["indestructible_shield"], "state": {}})
	real_hero.take_damage(6, func() -> float: return 0.05)
	if absf(real_hero._summon_current_hp - 20.0) > 0.001:
		push_error("[test_hero_on_field_bootstrap] HeroOnField summon wrapper must fully block damage when shield triggers")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("reset")
	print("[test_hero_on_field_bootstrap] PASS")
	quit(0)
