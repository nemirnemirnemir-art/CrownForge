extends SceneTree

func _init():
	var src_dir = "C:/Users/Макс/.gemini/antigravity/brain/b9619ab9-0394-4fc1-beaa-4be9142c10b4/"
	var dst_dir = "C:/Users/Maks/Documents/clickcer/assets/ui/icons/"
	
	var dir = DirAccess.open(dst_dir)
	if not dir:
		DirAccess.make_dir_recursive_absolute(dst_dir)
	
	var files = ["destroy_building_icon_1767915003417.png", "sell_blueprint_icon_1767915017792.png"]
	var targets = ["destroy_building_icon.png", "sell_blueprint_icon.png"]
	
	for i in range(files.size()):
		var err = DirAccess.copy_absolute(src_dir + files[i], dst_dir + targets[i])
		if err == OK:
			print("Copied: ", targets[i])
		else:
			print("Failed to copy ", targets[i], " Error code: ", err)
	
	quit()
