extends SceneTree

const HeroAssetLoaderScript = preload("res://scripts/utils/HeroAssetLoader.gd")

func _init() -> void:
	var expected := {
		"madman": {"walk": 6, "attack": 5},
		"black_sheep": {"walk": 7, "attack": 7}
	}

	for hero_id in expected.keys():
		var frames: SpriteFrames = HeroAssetLoaderScript.load_hero_sprite_frames(hero_id)
		if frames == null:
			push_error("[test_hero_asset_loader_madman_black_sheep] null frames for %s" % hero_id)
			quit(1)
			return

		var walk_count := frames.get_frame_count("walk") if frames.has_animation("walk") else 0
		var attack_count := frames.get_frame_count("attack") if frames.has_animation("attack") else 0

		var expected_walk := int(expected[hero_id]["walk"])
		var expected_attack := int(expected[hero_id]["attack"])
		if walk_count != expected_walk or attack_count != expected_attack:
			push_error(
				"[test_hero_asset_loader_madman_black_sheep] expected walk=%d attack=%d for %s, got walk=%d attack=%d" % [expected_walk, expected_attack, hero_id, walk_count, attack_count]
			)
			quit(1)
			return

		var walk_tex := frames.get_frame_texture("walk", 0) if walk_count > 0 else null
		var attack_tex := frames.get_frame_texture("attack", 0) if attack_count > 0 else null

		if walk_tex == null or attack_tex == null:
			push_error(
				"[test_hero_asset_loader_madman_black_sheep] expected non-null first textures for %s, got walk=%s attack=%s" % [hero_id, str(walk_tex), str(attack_tex)]
			)
			quit(1)
			return

	print("[test_hero_asset_loader_madman_black_sheep] PASS")
	quit(0)
