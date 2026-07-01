extends SceneTree

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

func _init() -> void:
	var failures: Array[String] = []
	var unit_ids := HeroSceneRegistryScript.get_registered_unit_ids()

	for unit_id in unit_ids:
		var scene := HeroSceneRegistryScript.load_scene(unit_id)
		if scene == null:
			failures.append("%s: scene_missing" % unit_id)
			continue

		var instance := scene.instantiate()
		if instance == null:
			failures.append("%s: instantiate_failed" % unit_id)
			continue

		var walk_node := instance.get_node_or_null("AnimWalk")
		var attack_node := instance.get_node_or_null("AnimAttack")

		if not (walk_node is AnimatedSprite2D):
			failures.append("%s: AnimWalk_missing" % unit_id)
		if not (attack_node is AnimatedSprite2D):
			failures.append("%s: AnimAttack_missing" % unit_id)

		instance.free()

	if not failures.is_empty():
		push_error("[test_hero_entry_scenes_dual_anim_nodes] Found %d scene(s) violating dual-node standard" % failures.size())
		for item in failures:
			print(" - %s" % item)
		quit(1)
		return

	print("[test_hero_entry_scenes_dual_anim_nodes] PASS")
	quit(0)
