extends SceneTree

const SummonInfernalsEffectScene := preload("res://scenes/spells/effects/SummonInfernalsEffect.tscn")
const SummonInfernalsConfig := preload("res://resources/spells/configs/summon_infernals.tres")


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	Corpse.active_corpses.clear()
	var artifact_core := get_root().get_node_or_null("ArtifactCore")
	if artifact_core == null:
		push_error("[test_summon_infernals_spawn_flow] ArtifactCore autoload must exist")
		quit(1)
		return
	artifact_core.call("reset")

	var effect := SummonInfernalsEffectScene.instantiate() as SpellEffect
	if effect == null:
		push_error("[test_summon_infernals_spawn_flow] failed to instantiate SummonInfernalsEffect")
		artifact_core.call("reset")
		quit(1)
		return

	var cfg := SummonInfernalsConfig.duplicate() as SpellConfig
	if cfg == null:
		push_error("[test_summon_infernals_spawn_flow] failed to duplicate summon_infernals config")
		artifact_core.call("reset")
		quit(1)
		return
	cfg.duration = 0.8

	var dummy_enemy := Node2D.new()
	dummy_enemy.name = "DummyEnemy"
	dummy_enemy.global_position = Vector2(520.0, 64.0)
	dummy_enemy.add_to_group("enemy")
	root.add_child(dummy_enemy)

	root.add_child(effect)
	effect.initialize(cfg, Vector2(120.0, 64.0))

	await process_frame
	await process_frame

	var tree := get_root().get_tree()
	if tree == null:
		push_error("[test_summon_infernals_spawn_flow] SceneTree is null")
		artifact_core.call("reset")
		quit(1)
		return

	var summons: Array = tree.get_nodes_in_group("summon")
	if summons.size() != 1:
		push_error("[test_summon_infernals_spawn_flow] expected exactly one summoned unit, got %d" % summons.size())
		artifact_core.call("reset")
		quit(1)
		return

	var summon: Node = summons[0] as Node
	if not (summon is Node2D):
		push_error("[test_summon_infernals_spawn_flow] summon is not Node2D")
		artifact_core.call("reset")
		quit(1)
		return

	if not summon.is_in_group("hero"):
		push_error("[test_summon_infernals_spawn_flow] summon must be in hero group")
		artifact_core.call("reset")
		quit(1)
		return

	if not summon.has_method("take_damage"):
		push_error("[test_summon_infernals_spawn_flow] summon must implement take_damage()")
		artifact_core.call("reset")
		quit(1)
		return

	var unit_anim := summon.get_node_or_null("UnitAnim") as AnimatedSprite2D
	if unit_anim == null or unit_anim.sprite_frames == null:
		push_error("[test_summon_infernals_spawn_flow] summon animation setup is missing")
		artifact_core.call("reset")
		quit(1)
		return

	if not unit_anim.sprite_frames.has_animation("run") or not unit_anim.sprite_frames.has_animation("attack"):
		push_error("[test_summon_infernals_spawn_flow] summon must have run/attack animations from nobody assets")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("load_save_data", {"owned": ["indestructible_shield"], "active": ["indestructible_shield"], "state": {}})
	var hp_before := float(summon.get("current_hp"))
	summon.call("take_damage", 30.0, false, func() -> float: return 0.05)
	var hp_after := float(summon.get("current_hp"))
	if absf(hp_after - hp_before) > 0.001:
		push_error("[test_summon_infernals_spawn_flow] indestructible shield must fully block infernal damage when it triggers")
		artifact_core.call("reset")
		quit(1)
		return

	await create_timer(1.2).timeout

	if is_instance_valid(summon):
		push_error("[test_summon_infernals_spawn_flow] summon must despawn after config duration")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("reset")
	print("[test_summon_infernals_spawn_flow] PASS")
	quit(0)
