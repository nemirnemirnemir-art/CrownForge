extends SceneTree

const CombatFacadeScript := preload("res://scripts/hero/modules/HeroOnFieldCombatFacade.gd")


class FakeCombatAI:
	extends RefCounted

	var landed: Array[float] = []
	var target_dead: bool = false
	var attack_range_ok: bool = true
	var shot_targets: Array = []

	func is_target_dead(_target) -> bool:
		return target_dead

	func check_attack_range(target, _buffer: float = 0.0) -> bool:
		return attack_range_ok and target != null

	func shoot_projectile(target) -> void:
		shot_targets.append(target)

	func on_hit_landed(amount: float) -> void:
		landed.append(amount)


class FakeHero:
	extends RefCounted

	var current_target = Node2D.new()


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var facade = CombatFacadeScript.new()
	if facade == null:
		push_error("[test_hero_on_field_combat_facade] failed to instantiate facade")
		quit(1)
		return

	var hero := FakeHero.new()
	var combat := FakeCombatAI.new()

	facade.setup(hero, combat)
	if not facade.check_attack_range():
		push_error("[test_hero_on_field_combat_facade] attack range should succeed with valid target")
		quit(1)
		return

	facade.fire_projectile(hero.current_target)
	if combat.shot_targets.size() != 1:
		push_error("[test_hero_on_field_combat_facade] projectile shot not forwarded")
		quit(1)
		return

	facade.on_hit_landed(12.0)
	if combat.landed != [12.0]:
		push_error("[test_hero_on_field_combat_facade] landed-hit callback mismatch")
		quit(1)
		return

	combat.target_dead = true
	facade.validate_current_target()
	if hero.current_target != null:
		push_error("[test_hero_on_field_combat_facade] dead target must be cleared")
		quit(1)
		return

	print("[test_hero_on_field_combat_facade] PASS")
	quit(0)
