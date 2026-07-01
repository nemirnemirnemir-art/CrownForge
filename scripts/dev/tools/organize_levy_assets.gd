extends SceneTree

func _init():
	print("Starting asset organization for Levy Barracks...")
	var base_path = "res://assets/environment/buildings/Levy_barracks/"
	var dir = DirAccess.open(base_path)
	
	if not dir:
		print("Error: Could not open directory " + base_path)
		quit()
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	var files_to_move = []

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			files_to_move.append(file_name)
		file_name = dir.get_next()
	
	for file in files_to_move:
		var name_no_ext = file.get_basename()
		# Create subdirectory
		if not dir.dir_exists(name_no_ext):
			var err = dir.make_dir(name_no_ext)
			if err != OK:
				print("Failed to create dir: " + name_no_ext + " Error: " + str(err))
				continue
		
		# Move file
		var source = base_path + file
		var dest = base_path + name_no_ext + "/" + file
		var err = dir.rename(source, dest)
		if err == OK:
			print("✅ Moved " + file + " to " + dest)
		else:
			print("❌ Failed to move " + file + " (Error: " + str(err) + ")")

	print("Finished organization.")
	quit()
