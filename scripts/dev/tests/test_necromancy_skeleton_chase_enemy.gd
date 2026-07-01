extends SceneTree

const SmallBonesScene := preload("res://scenes/heroes/small_bones.tscn")


func _init() -> void:
	var root := Node2D.new()
	get_root().add_child(root)
	call_deferred("_run_test", root)


func _run_test(root: Node2D) -> void:
	var artifact_core := get_root().get_node_or_null("ArtifactCore")
	if artifact_core == null:
		push_error("[test_necromancy_skeleton_chase_enemy] ArtifactCore autoload must exist")
		quit(1)
		return
	artifact_core.call("reset")

	var enemy := Node2D.new()
	enemy.name = "DummyEnemy"
	enemy.global_position = Vector2(340.0, 200.0)
	enemy.add_to_group("enemy")
	root.add_child(enemy)

	var skeleton := SmallBonesScene.instantiate() as Node2D
	if skeleton == null:
		push_error("[test_necromancy_skeleton_chase_enemy] failed to instantiate small_bones")
		artifact_core.call("reset")
		quit(1)
		return

	skeleton.global_position = Vector2(200.0, 200.0)
	root.add_child(skeleton)

	if skeleton.has_method("initialize_as_summon"):
		skeleton.call("initialize_as_summon", 1.8)

	await process_frame
	await process_frame

	var start_x := skeleton.global_position.x
	await create_timer(0.9).timeout
	var moved_x := skeleton.global_position.x

	if moved_x <= start_x + 5.0:
		push_error("[test_necromancy_skeleton_chase_enemy] skeleton must move to enemy, start_x=%.2f moved_x=%.2f" % [start_x, moved_x])
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("load_save_data", {"owned": ["indestructible_shield"], "active": ["indestructible_shield"], "state": {}})
	var hp_before := float(skeleton.get("current_hp"))
	skeleton.call("take_damage", 12.0, false, func() -> float: return 0.05)
	var hp_after := float(skeleton.get("current_hp"))
	if absf(hp_after - hp_before) > 0.001:
		push_error("[test_necromancy_skeleton_chase_enemy] indestructible shield must fully block SmallBones summon damage when it triggers")
		artifact_core.call("reset")
		quit(1)
		return

	artifact_core.call("reset")
	print("[test_necromancy_skeleton_chase_enemy] PASS")
	quit(0)
