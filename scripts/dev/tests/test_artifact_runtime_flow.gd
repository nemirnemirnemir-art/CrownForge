extends SceneTree

const RuntimeFlowScript := preload("res://core/artifacts/ArtifactRuntimeFlow.gd")
const ArtifactEventHandlers := preload("res://core/artifacts/ArtifactEventHandlers.gd")
const ArtifactEffectExecutor := preload("res://core/artifacts/ArtifactEffectExecutor.gd")
const ArtifactStatQueries := preload("res://core/artifacts/ArtifactStatQueries.gd")


class FakeArtifactCore:
	extends Node

	signal artifacts_changed

	var _active: Dictionary = {"chi_fan": true}
	var _state: Dictionary = {}

	func get_active_ids() -> Array:
		return _active.keys()


class FakeSaveCore:
	extends Node

	var request_count: int = 0

	func request_save() -> void:
		request_count += 1


class DummyHero:
	extends Node2D

	var hero_id: String = ""
	var is_dead: bool = false
	var speed_multiplier: float = 1.0
	var attack_speed_multiplier: float = 1.0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var flow = RuntimeFlowScript.new()
	if flow == null:
		push_error("[test_artifact_runtime_flow] failed to instantiate helper")
		quit(1)
		return

	var active := {
		"mystic_stone": true,
	}
	var state := {}
	flow.process_active_effects(active, state, 1.25)
	var periodic_state: Dictionary = state.get("mystic_stone", {})
	if periodic_state.is_empty():
		push_error("[test_artifact_runtime_flow] periodic effect state was not created")
		quit(1)
		return
	var accum := float(periodic_state.get("periodic_damage_accum", -1.0))
	if accum < 0.0 or accum >= 1.0:
		push_error("[test_artifact_runtime_flow] periodic accumulator mismatch")
		quit(1)
		return

	var result: Dictionary = flow.process_pending_spell_choice_rewards(2, 1)
	if int(result.get("pending", -1)) != 2:
		push_error("[test_artifact_runtime_flow] pending spell rewards should remain queued without runtime menu")
		quit(1)
		return
	if int(result.get("pending_legendary", -1)) != 1:
		push_error("[test_artifact_runtime_flow] pending legendary spell rewards should remain queued without runtime menu")
		quit(1)
		return

	var artifact_core := FakeArtifactCore.new()
	artifact_core.name = "ArtifactCore"
	get_root().add_child(artifact_core)
	var save_core := FakeSaveCore.new()
	save_core.name = "SaveCore"
	get_root().add_child(save_core)
	var artifacts_changed_count := 0
	artifact_core.artifacts_changed.connect(func() -> void:
		artifacts_changed_count += 1
	)

	ArtifactEffectExecutor.on_spell_cast("fireball")
	ArtifactEffectExecutor.on_spell_cast("fireball")

	var chi_fan_state: Dictionary = artifact_core._state.get("chi_fan", {})
	if int(chi_fan_state.get("resolved_spell_casts", -1)) != 2:
		push_error("[test_artifact_runtime_flow] chi_fan must persist resolved spell cast stacks in artifact state")
		quit(1)
		return
	if ArtifactStatQueries.get_unit_flat_hp_bonus(artifact_core._active, artifact_core._state) != 10:
		push_error("[test_artifact_runtime_flow] chi_fan must add 5 flat HP per resolved spell cast")
		quit(1)
		return
	if artifacts_changed_count != 2:
		push_error("[test_artifact_runtime_flow] chi_fan spell casts must emit artifacts_changed for hero bonus sync")
		quit(1)
		return
	if save_core.request_count != 2:
		push_error("[test_artifact_runtime_flow] chi_fan spell casts must request saves when state changes")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var dead_hero := DummyHero.new()
	dead_hero.name = "DeadHero"
	dead_hero.hero_id = "fallen_hero"
	dead_hero.is_dead = true
	dead_hero.add_to_group("hero")
	root.add_child(dead_hero)

	var living_hero := DummyHero.new()
	living_hero.name = "LivingHero"
	living_hero.hero_id = "living_hero"
	living_hero.add_to_group("hero")
	root.add_child(living_hero)

	await process_frame
	ArtifactEventHandlers.on_hero_died({"hand_of_the_avenged": true}, {}, "fallen_hero")
	await process_frame

	if absf(living_hero.speed_multiplier - 1.3) > 0.001:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must buff a living ally move speed")
		quit(1)
		return
	if absf(living_hero.attack_speed_multiplier - 1.3) > 0.001:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must buff a living ally attack speed")
		quit(1)
		return
	if living_hero.get_node_or_null("HandOfTheAvengedIcon") == null:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must add a temporary status icon")
		quit(1)
		return

	await create_timer(6.2).timeout
	await process_frame

	if absf(living_hero.speed_multiplier - 1.0) > 0.001:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must restore move speed after the buff ends")
		quit(1)
		return
	if absf(living_hero.attack_speed_multiplier - 1.0) > 0.001:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must restore attack speed after the buff ends")
		quit(1)
		return
	if living_hero.get_node_or_null("HandOfTheAvengedIcon") != null:
		push_error("[test_artifact_runtime_flow] hand_of_the_avenged must remove its status icon after the buff ends")
		quit(1)
		return

	print("[test_artifact_runtime_flow] PASS")
	quit(0)
