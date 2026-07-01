extends SceneTree

const HeroDataScript := preload("res://core/hero/HeroData.gd")
const BootstrapScript := preload("res://scripts/hero/modules/HeroOnFieldBootstrap.gd")
const SmallBonesScene := preload("res://scenes/heroes/small_bones.tscn")

const ALLOWED_VARIANTS := [0.80, 0.85, 0.90, 0.95, 1.05, 1.10, 1.15, 1.20]

var _failed: bool = false


class FakeStats:
	extends RefCounted

	var is_melee: bool = true
	var projectile_scene = null
	var determined_ids: Array[String] = []

	func determine_combat_type(hero_id: String) -> void:
		determined_ids.append(hero_id)


class FakeVisuals:
	extends RefCounted

	var hero_id: String = ""


class FakeMovement:
	extends RefCounted

	var move_speed: float = 100.0

	func apply_speed_modifiers(_stats, is_melee: bool, override_move_speed: float) -> void:
		if override_move_speed > 0.0:
			move_speed = override_move_speed
		if not is_melee:
			move_speed /= 1.15


class FakeAnimations:
	extends RefCounted

	func setup(_hero, _sprite, _hero_id: String, _state_machine) -> void:
		pass

	func start_initial_animation() -> void:
		pass


class FakeCombatAI:
	extends RefCounted

	func setup(_hero, _stats) -> void:
		pass


class FakeHealth:
	extends RefCounted

	func initialize(_hero, _hero_id: String, _bar) -> void:
		pass


class FakeHero:
	extends CharacterBody2D

	var hero_id: String = "militia"
	var override_move_speed: float = -1.0
	var patrol_center: Vector2 = Vector2.ZERO
	var animation_sprite: AnimatedSprite2D = null
	var health_bar: ProgressBar = null
	var _projectile_scene_override = null
	var speed_multiplier: float = 1.0
	var override_attack_range: float = -1.0
	var override_projectile_speed: float = -1.0
	var override_projectile_type: String = ""

	func _init() -> void:
		animation_sprite = AnimatedSprite2D.new()
		animation_sprite.name = "AnimationSprite2D"
		add_child(animation_sprite)
		health_bar = ProgressBar.new()
		health_bar.name = "HealthBar"
		add_child(health_bar)


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	_test_hero_data_assigns_and_backfills_intrinsic_speed()
	if _failed:
		return
	await _test_bootstrap_applies_intrinsic_speed_without_touching_effect_multiplier()
	if _failed:
		return
	await _test_small_bones_applies_intrinsic_speed_for_permanent_hero()
	if _failed:
		return
	print("[test_hero_intrinsic_speed_variance] PASS")
	quit(0)


func _test_hero_data_assigns_and_backfills_intrinsic_speed() -> void:
	var hero_data = HeroDataScript.new()
	if hero_data == null:
		_fail("failed to instantiate HeroData")
		return

	var created := hero_data.create_hero("speed_test", "Speed Test", "speed_test", 100.0)
	if not created:
		_fail("failed to create speed_test hero")
		return

	var created_hero: Dictionary = hero_data.get_hero("speed_test")
	if not created_hero.has("intrinsic_speed_multiplier"):
		_fail("new heroes must get intrinsic_speed_multiplier")
		return
	if not _is_allowed_variant(float(created_hero["intrinsic_speed_multiplier"])):
		_fail("new hero intrinsic_speed_multiplier must use allowed mob-like variants")
		return

	hero_data.heroes["legacy_speedless"] = {
		"id": "legacy_speedless",
		"name": "Legacy",
		"base_hp": 10.0,
		"base_damage": 5.0,
		"hp": 10.0,
		"maxHp": 10.0,
		"damage": 5.0
	}
	hero_data.heroes["preserved"] = {
		"id": "preserved",
		"name": "Preserved",
		"base_hp": 10.0,
		"base_damage": 5.0,
		"hp": 10.0,
		"maxHp": 10.0,
		"damage": 5.0,
		"intrinsic_speed_multiplier": 1.15
	}

	hero_data.revalidate_all_heroes()

	var legacy_hero: Dictionary = hero_data.get_hero("legacy_speedless")
	if not legacy_hero.has("intrinsic_speed_multiplier"):
		_fail("revalidate_all_heroes must backfill intrinsic_speed_multiplier for old save data")
		return
	if not _is_allowed_variant(float(legacy_hero["intrinsic_speed_multiplier"])):
		_fail("backfilled intrinsic_speed_multiplier must use allowed mob-like variants")
		return
	if absf(float(hero_data.get_hero("preserved").get("intrinsic_speed_multiplier", 0.0)) - 1.15) > 0.001:
		_fail("existing intrinsic_speed_multiplier must not reroll during revalidation")
		return


func _test_bootstrap_applies_intrinsic_speed_without_touching_effect_multiplier() -> void:
	var hero_core = _get_hero_core()
	if hero_core == null:
		_fail("HeroCore autoload is required for runtime speed variance test")
		return
	var previous_multiplier := float(hero_core.get_hero("militia").get("intrinsic_speed_multiplier", 1.0))
	hero_core.update_hero("militia", {"intrinsic_speed_multiplier": 1.20})

	var hero := FakeHero.new()
	get_root().add_child(hero)

	var bootstrap := BootstrapScript.new()
	var stats := FakeStats.new()
	var movement := FakeMovement.new()
	var visuals := FakeVisuals.new()
	var animations := FakeAnimations.new()
	var combat := FakeCombatAI.new()
	var health := FakeHealth.new()
	var state_machine := Node.new()

	bootstrap.initialize_runtime(hero, stats, movement, visuals, animations, combat, health, state_machine)

	if absf(movement.move_speed - 120.0) > 0.01:
		_fail("hero bootstrap must apply stored intrinsic speed variance to runtime move_speed")
		return
	if absf(hero.speed_multiplier - 1.0) > 0.001:
		_fail("hero bootstrap must not overwrite temporary effect speed_multiplier")
		hero_core.update_hero("militia", {"intrinsic_speed_multiplier": previous_multiplier})
		return

	hero_core.update_hero("militia", {"intrinsic_speed_multiplier": previous_multiplier})
	hero.queue_free()
	await process_frame


func _test_small_bones_applies_intrinsic_speed_for_permanent_hero() -> void:
	var hero_core = _get_hero_core()
	if hero_core == null:
		_fail("HeroCore autoload is required for SmallBones speed variance test")
		return
	var previous_multiplier := float(hero_core.get_hero("small_bones").get("intrinsic_speed_multiplier", 1.0))
	hero_core.update_hero("small_bones", {"intrinsic_speed_multiplier": 0.80})

	var skeleton := SmallBonesScene.instantiate()
	get_root().add_child(skeleton)
	skeleton.initialize("small_bones")

	if absf(float(skeleton.move_speed) - 64.0) > 0.01:
		_fail("SmallBones permanent heroes must apply stored intrinsic speed variance")
		hero_core.update_hero("small_bones", {"intrinsic_speed_multiplier": previous_multiplier})
		return
	if absf(float(skeleton.speed_multiplier) - 1.0) > 0.001:
		_fail("SmallBones intrinsic speed must not overwrite temporary effect speed_multiplier")
		hero_core.update_hero("small_bones", {"intrinsic_speed_multiplier": previous_multiplier})
		return

	hero_core.update_hero("small_bones", {"intrinsic_speed_multiplier": previous_multiplier})
	skeleton.queue_free()
	await process_frame


func _is_allowed_variant(value: float) -> bool:
	for variant in ALLOWED_VARIANTS:
		if absf(value - float(variant)) <= 0.001:
			return true
	return false


func _get_hero_core():
	return get_root().get_node_or_null("HeroCore")


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("[test_hero_intrinsic_speed_variance] %s" % message)
	quit(1)
