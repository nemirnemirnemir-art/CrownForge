extends SceneTree

const MobBootstrapScript := preload("res://scripts/mob/modules/MobBootstrap.gd")


class FakeStats:
	extends RefCounted

	var setup_calls: int = 0

	func setup(_mob, _move_speed, _invert, _attack_range, _aggro_range, _mob_damage, _heal_amount, _projectile_scene) -> void:
		setup_calls += 1


class FakeMovement:
	extends RefCounted

	var setup_calls: int = 0
	var wall_attack_stop_distance_override: float = -1.0

	func setup(_mob) -> void:
		setup_calls += 1

	func set_wall_attack_stop_distance(distance: float) -> void:
		wall_attack_stop_distance_override = distance


class FakeCombat:
	extends RefCounted

	var setup_calls: int = 0
	var attack_range: float = 0.0
	var mob_damage: float = 0.0
	var aggro_range: float = 0.0

	func setup(_mob, _aggro_area, _attack_component) -> void:
		setup_calls += 1

	func set_attack_range(value: float) -> void:
		attack_range = value


class FakeAnimations:
	extends RefCounted

	var setup_calls: int = 0

	func setup(_mob, _animation_sprite, _animation_dead, _attack_component, _anim_walk, _anim_attack) -> void:
		setup_calls += 1


class FakeVisuals:
	extends RefCounted

	var setup_calls: int = 0
	var spawn_effects: int = 0

	func setup(_mob) -> void:
		setup_calls += 1

	func play_spawn_effects() -> void:
		spawn_effects += 1


class FakeWallTargetingFlow:
	extends RefCounted

	var setup_calls: int = 0

	func setup(_mob) -> void:
		setup_calls += 1


class FakeHealth:
	extends Node

	signal died

	var setup_calls: int = 0

	func setup(_mob) -> void:
		setup_calls += 1


class FakeRewards:
	extends Node

	var setup_calls: int = 0

	func setup(_mob, _health) -> void:
		setup_calls += 1


class FakeSlots:
	extends Node

	var setup_calls: int = 0

	func setup(_mob) -> void:
		setup_calls += 1


class FakeClickHandler:
	extends Node

	var setup_calls: int = 0

	func setup(_mob, _click_area, _health) -> void:
		setup_calls += 1


class FakeMob:
	extends CharacterBody2D

	var move_speed: float = 50.0
	var invert_visual_facing: bool = false
	var attack_range: float = 25.0
	var aggro_range: float = 200.0
	var mob_damage: float = 4.0
	var heal_amount: float = 2.0
	var projectile_scene = null
	var behavior_target_type: String = ""
	var stats = null
	var movement = null
	var combat = null
	var animations = null
	var visuals = null
	var _runtime_bridge = null
	var _status_effects_flow = null
	var _death_flow = null
	var _wall_targeting_flow = null
	var health = FakeHealth.new()
	var rewards = FakeRewards.new()
	var slots = FakeSlots.new()
	var click_handler = FakeClickHandler.new()
	var click_area = Area2D.new()
	var animation_sprite = AnimatedSprite2D.new()
	var animation_dead = AnimatedSprite2D.new()
	var anim_walk = AnimatedSprite2D.new()
	var anim_attack = AnimatedSprite2D.new()
	var _aggro_area = Area2D.new()
	var _attack_component = Node.new()
	var _register_calls: int = 0
	var _behavior_calls: int = 0
	var _component_calls: int = 0
	var _animation_calls: int = 0
	var _signal_calls: int = 0
	var _spawn_calls: int = 0
	var _pending_wall_attack_stop_distance_override: float = -1.0

	func _init() -> void:
		add_child(health)
		add_child(rewards)
		add_child(slots)
		add_child(click_handler)

	func _register_combat_groups() -> void:
		_register_calls += 1

	func _behavior_setup() -> void:
		_behavior_calls += 1

	func _component_setup() -> void:
		_component_calls += 1
		health.setup(self)
		rewards.setup(self, health)
		slots.setup(self)
		click_handler.setup(self, click_area, health)

	func _animation_setup() -> void:
		_animation_calls += 1
		animations.setup(self, animation_sprite, animation_dead, _attack_component, anim_walk, anim_attack)

	func _signal_setup() -> void:
		_signal_calls += 1

	func _spawn_effects_setup() -> void:
		_spawn_calls += 1
		visuals.play_spawn_effects()

	func set_wall_attack_stop_distance(distance: float) -> void:
		_pending_wall_attack_stop_distance_override = maxf(0.0, distance)

	func _consume_pending_wall_attack_stop_distance_override() -> float:
		var pending_override := _pending_wall_attack_stop_distance_override
		_pending_wall_attack_stop_distance_override = -1.0
		return pending_override


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var bootstrap = MobBootstrapScript.new()
	if bootstrap == null:
		push_error("[test_mob_bootstrap] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	get_root().add_child(mob)
	mob.set_wall_attack_stop_distance(120.0)
	mob.stats = FakeStats.new()
	mob.movement = FakeMovement.new()
	mob.combat = FakeCombat.new()
	mob.animations = FakeAnimations.new()
	mob.visuals = FakeVisuals.new()
	mob._wall_targeting_flow = FakeWallTargetingFlow.new()

	bootstrap.run(mob)
	if mob.stats.setup_calls != 1 or mob.movement.setup_calls != 1 or mob.combat.setup_calls != 1:
		push_error("[test_mob_bootstrap] core modules not initialized")
		quit(1)
		return
	if mob.health.setup_calls != 1 or mob.rewards.setup_calls != 1 or mob.slots.setup_calls != 1 or mob.click_handler.setup_calls != 1:
		push_error("[test_mob_bootstrap] components not wired")
		quit(1)
		return
	if mob.visuals.spawn_effects != 1:
		push_error("[test_mob_bootstrap] spawn effects not triggered")
		quit(1)
		return
	if mob._wall_targeting_flow.setup_calls != 1:
		push_error("[test_mob_bootstrap] wall targeting flow not initialized")
		quit(1)
		return
	if absf(mob.movement.wall_attack_stop_distance_override - 120.0) > 0.01:
		push_error("[test_mob_bootstrap] pending wall stop override not applied during bootstrap")
		quit(1)
		return

	print("[test_mob_bootstrap] PASS")
	quit(0)
