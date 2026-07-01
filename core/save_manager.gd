extends RefCounted
class_name SaveManager

static func write_json(path: String, data: Variant) -> bool:
	var json_string := JSON.stringify(data)
	var tmp_path := path + ".tmp"
	var bak_path := path + ".bak"

	var abs_path := ProjectSettings.globalize_path(path)
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_bak := ProjectSettings.globalize_path(bak_path)

	# 1. Create backup of existing save
	if FileAccess.file_exists(path):
		var err_bak := DirAccess.copy_absolute(abs_path, abs_bak)
		if err_bak != OK:
			# print("[SaveManager] Warning: Failed to create backup: ", err_bak)
			pass

	# 2. Write to temp file
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		# print("[SaveManager] Error: Failed to open temp file for write: ", tmp_path)
		return false
	file.store_string(json_string)
	file.close()

	# 3. Rename temp to real (delete old first to ensure Windows compatibility)
	if FileAccess.file_exists(path):
		var err_del := DirAccess.remove_absolute(abs_path)
		if err_del != OK:
				# print("[SaveManager] Error: Failed to delete old save file: ", err_del)
				return false

	var err := DirAccess.rename_absolute(abs_tmp, abs_path)
	if err != OK:
		# print("[SaveManager] Error: Failed to rename tmp to save file: ", err)
		return false
		
	return true

static func read_json(path: String) -> Dictionary:
	var primary := _read_json_single(path)
	if not primary.is_empty():
		return primary
	return _read_json_single(path + ".bak")

static func _read_json_single(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var parse_result := json.parse(file.get_as_text())
	if parse_result != OK:
		return {}

	if json.data is Dictionary:
		return json.data
	return {}

static func delete_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	var abs_path := ProjectSettings.globalize_path(path)
	var err := DirAccess.remove_absolute(abs_path)
	return err == OK
