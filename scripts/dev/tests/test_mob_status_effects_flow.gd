extends SceneTree

const MobStatusEffectsFlowScript := preload("res://scripts/mob/modules/MobStatusEffectsFlow.gd")


class FakeHealth:
	extends RefCounted

	var taken: Array = []
	var stuns: Array[float] = []

	func take_damage(amount: float, is_crit: bool) -> void:
		taken.append([amount, is_crit])

	func apply_stun(duration: float) -> void:
		stuns.append(duration)


class FakePopup:
	extends RefCounted

	var evades: int = 0
	var stuns: int = 0

	func spawn_evade(_parent, _pos: Vector2) -> void:
		evades += 1

	func spawn_stun(_parent, _pos: Vector2) -> void:
		stuns += 1


class FakeStunEffect:
	extends RefCounted

	var attached: Array[float] = []

	func attach_to(_mob, duration: float) -> void:
		attached.append(duration)


class FakeMob:
	extends Node2D

	var damage_taken_multiplier: float = 2.0
	var evasion_chance: float = 0.0
	var is_invincible: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = MobStatusEffectsFlowScript.new()
	if flow == null:
		push_error("[test_mob_status_effects_flow] failed to instantiate helper")
		quit(1)
		return

	var mob := FakeMob.new()
	get_root().add_child(mob)
	var health := FakeHealth.new()
	var popup := FakePopup.new()
	var stun_fx := FakeStunEffect.new()
	flow.setup(mob, health)

	flow.take_damage(3.0, true, popup, null)
	if health.taken.is_empty() or absf(health.taken[-1][0] - 6.0) > 0.01:
		push_error("[test_mob_status_effects_flow] damage multiplier mismatch")
		quit(1)
		return

	flow.apply_stun(1.5, stun_fx, popup)
	if health.stuns != [1.5] or stun_fx.attached != [1.5] or popup.stuns != 1:
		push_error("[test_mob_status_effects_flow] stun flow mismatch")
		quit(1)
		return

	print("[test_mob_status_effects_flow] PASS")
	quit(0)
