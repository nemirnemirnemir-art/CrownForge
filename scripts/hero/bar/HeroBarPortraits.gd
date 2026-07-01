extends Node

## HeroBarPortraits module
## Manages hero portrait loading and assignment

func get_or_assign_portrait(hero_id: String, icon_id: String) -> String:
	# Check if hero already has a portrait assigned (via Query if we supported it, but let's trust AssetLoader)
	# Since we are moving away from writing to dictionary here, let's just get it from loader.
	
	var lookup_id = hero_id
	if icon_id != "":
		lookup_id = icon_id
		
	var portrait_path: String = HeroAssetLoader.get_hero_icon_path(lookup_id)
	return portrait_path

func get_random_portrait_path(icon_id: String) -> String:
	return HeroAssetLoader.get_hero_icon_path(icon_id)

func load_portrait_texture(icon_path: String) -> Texture2D:
	if not ResourceLoader.exists(icon_path):
		return null
	
	var loaded_resource = load(icon_path)
	if loaded_resource is SpriteFrames:
		var sprite_frames: SpriteFrames = loaded_resource
		if sprite_frames.has_animation("idle") and sprite_frames.get_frame_count("idle") > 0:
			return sprite_frames.get_frame_texture("idle", 0)
		elif sprite_frames.has_animation("walk") and sprite_frames.get_frame_count("walk") > 0:
			return sprite_frames.get_frame_texture("walk", 0)
		elif sprite_frames.get_animation_names().size() > 0:
			var anim_name: String = sprite_frames.get_animation_names()[0]
			if sprite_frames.get_frame_count(anim_name) > 0:
				return sprite_frames.get_frame_texture(anim_name, 0)
	elif loaded_resource is Texture2D:
		return loaded_resource
	
	return null

