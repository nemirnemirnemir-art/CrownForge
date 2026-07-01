extends SceneTree

const MobCombatFacadeScript := preload("res://scripts/mob/modules/MobCombatFacade.gd")


class FakeCombat:
	extends RefCounted

	var started: int = 0
	var ended: int = 0
	var finished: bool = true

	func start_attack() -> void:
		started += 1

	func attack_finished() -> bool:
		return finished

	func end_attack() -> void:
		ended += 1


class FakeAnimations:
	extends RefCounted

	var walk: int = 0
	var attack: int = 0
	var death: int = 0

	func play_walk() -> void:
		walk += 1

	func play_attack() -> void:
		attack += 1

	func play_death() -> void:
		death += 1


class FakeHealth:
	extends RefCounted

	var current_health: float = 3.0
	var max_health: float = 10.0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var facade = MobCombatFacadeScript.new()
	if facade == null:
		push_error("[test_mob_combat_facade] failed to instantiate helper")
		quit(1)
		return

	var combat := FakeCombat.new()
	var animations := FakeAnimations.new()
	var health := FakeHealth.new()

	facade.start_attack(combat)
	if combat.started != 1:
		push_error("[test_mob_combat_facade] start attack mismatch")
		quit(1)
		return
	if not facade.attack_finished(combat):
		push_error("[test_mob_combat_facade] attack_finished mismatch")
		quit(1)
		return
	facade.end_attack(combat)
	if combat.ended != 1:
		push_error("[test_mob_combat_facade] end attack mismatch")
		quit(1)
		return

	facade.play_walk(animations)
	facade.play_attack(animations)
	facade.play_death(animations)
	if animations.walk != 1 or animations.attack != 1 or animations.death != 1:
		push_error("[test_mob_combat_facade] animation routing mismatch")
		quit(1)
		return

	var healed := facade.heal(health, 5.0)
	if absf(healed - 5.0) > 0.01 or absf(health.current_health - 8.0) > 0.01:
		push_error("[test_mob_combat_facade] heal mismatch")
		quit(1)
		return

	print("[test_mob_combat_facade] PASS")
	quit(0)
