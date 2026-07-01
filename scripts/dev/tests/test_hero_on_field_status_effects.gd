extends SceneTree

const StatusEffectsScript := preload("res://scripts/hero/modules/HeroOnFieldStatusEffects.gd")


class FakeStateMachine:
	extends RefCounted

	var proc_enabled: bool = true
	var phys_enabled: bool = true

	func is_processing() -> bool:
		return proc_enabled

	func is_physics_processing() -> bool:
		return phys_enabled

	func set_process(v: bool) -> void:
		proc_enabled = v

	func set_physics_process(v: bool) -> void:
		phys_enabled = v


class FakeAnimations:
	extends RefCounted

	var attack_playing: bool = false

	func set_attack_animation_playing(v: bool) -> void:
		attack_playing = v


class FakeCombatBridge:
	extends RefCounted

	var damage_calls: Array = []
	var popup_pool = null

	func send_damage(hero_id: String, amount: int) -> void:
		damage_calls.append([hero_id, amount])

	func get_damage_popup_pool():
		return popup_pool


class FakePopupPool:
	extends RefCounted

	var popups: Array = []

	func show_damage(pos: Vector2, amount: int, crit: bool) -> void:
		popups.append([pos, amount, crit])


class FakeHero:
	extends Node2D

	var hero_id: String = "militia"
	var current_target = Node2D.new()
	var velocity: Vector2 = Vector2.RIGHT
	var is_stunned: bool = false
	var stun_timer: float = 0.0
	var _stun_prev_sm_process: bool = true
	var _stun_prev_sm_physics: bool = true
	var damage_taken_multiplier: float = 1.0
	var is_invincible: bool = false
	var evasion_chance: float = 0.0


func _run_test() -> void:
	var artifact_core := get_root().get_node_or_null("ArtifactCore")
	if artifact_core == null:
		push_error("[test_hero_on_field_status_effects] ArtifactCore autoload must exist")
		quit(1)
		return
	artifact_core.call("reset")

	var effects = StatusEffectsScript.new()
	var hero := FakeHero.new()
	var state_machine := FakeStateMachine.new()
	var animations := FakeAnimations.new()
	var combat := FakeCombatBridge.new()
	var popup := FakePopupPool.new()
	combat.popup_pool = popup

	effects.setup(hero)
	effects.apply_stun(1.5, state_machine, animations, null, null)
	if not hero.is_stunned or hero.current_target != null:
		push_error("[test_hero_on_field_status_effects] stun must clear target and set stunned")
		artifact_core.call("reset")
		quit(1)
		return
	if state_machine.proc_enabled or state_machine.phys_enabled:
		push_error("[test_hero_on_field_status_effects] stun must pause state machine")
		artifact_core.call("reset")
		quit(1)
		return

	effects.take_damage(10, 1.0, false, 0.0, combat, popup)
	if combat.damage_calls.is_empty() or int(combat.damage_calls[-1][1]) != 10:
		push_error("[test_hero_on_field_status_effects] damage must reach bridge")
		artifact_core.call("reset")
		quit(1)
		return
	if popup.popups.is_empty():
		push_error("[test_hero_on_field_status_effects] damage popup must show")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("load_save_data", {"owned": ["indestructible_shield"], "active": ["indestructible_shield"], "state": {}})
	effects.take_damage(10, 1.0, false, 0.0, combat, popup, func() -> float: return 0.05)
	if combat.damage_calls.size() != 1:
		push_error("[test_hero_on_field_status_effects] shielded damage must be fully blocked")
		artifact_core.call("reset")
		quit(1)
		return
	if popup.popups.size() != 1:
		push_error("[test_hero_on_field_status_effects] shielded damage must not show a damage popup")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("reset")
	print("[test_hero_on_field_status_effects] PASS")
	quit(0)


func _init() -> void:
	call_deferred("_run_test")
