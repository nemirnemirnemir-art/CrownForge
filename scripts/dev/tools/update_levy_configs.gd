extends SceneTree

const BUILDINGS = {
	"archery": "Archery",
	"assassins_temple": "Assassins_temple",
	"black_sheep_barn": "black_sheep_barn",
	"bone_pit": "bone_pit",
	"gnome_dome": "Gnome_Dome",
	"hunters": "Hunters",
	"madhouse": "madhouse",
	"militia_camp": "militia_camp",
	"peasants_hut": "Peasants_Hut",
	"slingers_tree": "slinger_tree",
	"small_peasants_hut": "small_peasant_hut",
	"swordsmen_barracks": "barracks",
	"whipmens_house": "whipmen_house"
}

func _init():
	var log_file = FileAccess.open("res://update_log.txt", FileAccess.WRITE)
	log_file.store_line("Starting Levy Barracks config update...")
	
	for building_id in BUILDINGS:
		var folder_name = BUILDINGS[building_id]
		var png_name = folder_name 
		
		# Paths
		var png_path = "res://assets/environment/buildings/Levy_barracks/%s/%s.png" % [folder_name, png_name]
		var frames_path = "res://data/buildings/levy_barracks/%s_vzor_frames.tres" % building_id
		var config_path = "res://data/buildings/levy_barracks/%s.tres" % building_id
		
		log_file.store_line("Processing " + building_id + "...")
		
		if not FileAccess.file_exists(png_path):
			log_file.store_line("WARNING: Texture not found at " + png_path)
			continue
			
		var frames = SpriteFrames.new()
		var texture = load(png_path)
		if not texture:
			log_file.store_line("Error: Failed to load texture " + png_path)
			continue
			
		frames.add_animation("default")
		frames.set_animation_loop("default", true)
		frames.set_animation_speed("default", 5.0)
		frames.add_frame("default", texture)
		
		var err = ResourceSaver.save(frames, frames_path)
		if err != OK:
			log_file.store_line("Error saving frames: " + str(err))
			continue
			
		log_file.store_line("Saved frames to " + frames_path)
		
		if not FileAccess.file_exists(config_path):
			log_file.store_line("Error: Config not found " + config_path)
			continue
			
		var config = load(config_path)
		if not config:
			log_file.store_line("Error: Failed to load config " + config_path)
			continue
			
		config.use_vzor_animation = true
		config.vzor_frames = load(frames_path)
		config.vzor_animation_name = "default"
		config.icon = texture
		
		err = ResourceSaver.save(config, config_path)
		if err != OK:
			log_file.store_line("Error saving config: " + str(err))
			continue
			
		log_file.store_line("Updated config " + config_path)
		
	log_file.store_line("Update complete.")
	log_file.close()
	quit()
