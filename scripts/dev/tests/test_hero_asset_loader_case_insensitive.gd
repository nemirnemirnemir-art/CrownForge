extends SceneTree

const HeroAssetLoaderScript = preload("res://scripts/utils/HeroAssetLoader.gd")

func _init() -> void:
	var expected_counts := {
		"SLINGER": {"walk": 4, "attack": 6},
		"SINGER": {"walk": 4, "attack": 6},
		"HUNTER": {"walk": 5, "attack": 7}
	}

	for hero_id in expected_counts.keys():
		var frames: SpriteFrames = HeroAssetLoaderScript.load_hero_sprite_frames(hero_id)
		if frames == null:
			push_error("[test_hero_asset_loader_case_insensitive] null frames for %s" % hero_id)
			quit(1)
			return

		var walk_count := frames.get_frame_count("walk") if frames.has_animation("walk") else 0
		var attack_count := frames.get_frame_count("attack") if frames.has_animation("attack") else 0
		var expected_walk := int(expected_counts[hero_id]["walk"])
		var expected_attack := int(expected_counts[hero_id]["attack"])

		if walk_count != expected_walk or attack_count != expected_attack:
			push_error(
				"[test_hero_asset_loader_case_insensitive] expected walk=%d attack=%d for %s, got walk=%d attack=%d" % [expected_walk, expected_attack, hero_id, walk_count, attack_count]
			)
			quit(1)
			return

	print("[test_hero_asset_loader_case_insensitive] PASS")
	quit(0)
