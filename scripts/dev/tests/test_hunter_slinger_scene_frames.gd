extends SceneTree

const HeroSceneRegistryScript = preload("res://scripts/hero/HeroSceneRegistry.gd")

func _init() -> void:
	var expected := {
		"slinger": {"walk": 4, "attack": 6, "path_prefix": "res://assets/characters/tinyHeroes/Slinger/"},
		"hunter": {"walk": 5, "attack": 7, "path_prefix": "res://assets/characters/tinyHeroes/Hunter/"}
	}

	for unit_id in expected.keys():
		var scene := HeroSceneRegistryScript.load_scene(unit_id)
		if scene == null:
			push_error("[test_hunter_slinger_scene_frames] scene missing for %s" % unit_id)
			quit(1)
			return

		var inst := scene.instantiate()
		if inst == null:
			push_error("[test_hunter_slinger_scene_frames] instantiate failed for %s" % unit_id)
			quit(1)
			return

		var walk_node := inst.get_node_or_null("AnimWalk") as AnimatedSprite2D
		var attack_node := inst.get_node_or_null("AnimAttack") as AnimatedSprite2D
		if walk_node == null or attack_node == null:
			push_error("[test_hunter_slinger_scene_frames] missing AnimWalk/AnimAttack for %s" % unit_id)
			quit(1)
			return

		var walk_count := walk_node.sprite_frames.get_frame_count("walk") if walk_node.sprite_frames and walk_node.sprite_frames.has_animation("walk") else 0
		var attack_count := attack_node.sprite_frames.get_frame_count("attack") if attack_node.sprite_frames and attack_node.sprite_frames.has_animation("attack") else 0
		var expected_walk := int(expected[unit_id]["walk"])
		var expected_attack := int(expected[unit_id]["attack"])

		if walk_count != expected_walk or attack_count != expected_attack:
			push_error(
				"[test_hunter_slinger_scene_frames] expected %s walk=%d attack=%d, got walk=%d attack=%d" % [unit_id, expected_walk, expected_attack, walk_count, attack_count]
			)
			quit(1)
			return

		var expected_prefix := String(expected[unit_id]["path_prefix"])
		var walk_tex := walk_node.sprite_frames.get_frame_texture("walk", 0)
		var attack_tex := attack_node.sprite_frames.get_frame_texture("attack", 0)
		var walk_path := walk_tex.resource_path if walk_tex else ""
		var attack_path := attack_tex.resource_path if attack_tex else ""

		if not walk_path.begins_with(expected_prefix) or not attack_path.begins_with(expected_prefix):
			push_error(
				"[test_hunter_slinger_scene_frames] expected texture prefix %s for %s, got walk=%s attack=%s" % [expected_prefix, unit_id, walk_path, attack_path]
			)
			quit(1)
			return

		inst.free()

	print("[test_hunter_slinger_scene_frames] PASS")
	quit(0)
