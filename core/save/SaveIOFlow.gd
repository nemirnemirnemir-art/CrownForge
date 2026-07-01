extends RefCounted
class_name SaveIOFlow


func save_game(save_manager, save_file_path: String, can_save: bool, is_loading: bool, current_stage: int, has_critical_modules: bool, save_modules: Dictionary) -> bool:
	if not can_save:
		return false
	if current_stage <= 1 and is_loading:
		return false
	if not has_critical_modules:
		return false
	var save_data: Dictionary = {}
	for key in save_modules.keys():
		var module: Object = save_modules[key]
		if module != null and module.has_method("get_save_data"):
			save_data[str(key)] = module.get_save_data()
		else:
			save_data[str(key)] = {}
	return save_manager.write_json(save_file_path, save_data)


func load_game(save_manager, save_file_path: String, save_modules: Dictionary, on_loaded: Callable) -> bool:
	var data: Dictionary = save_manager.read_json(save_file_path)
	if data.is_empty():
		return false
	for key in save_modules.keys():
		var module: Object = save_modules[key]
		if module == null:
			continue
		if data.has(str(key)) and module.has_method("load_save_data"):
			module.load_save_data(data[str(key)])
	if on_loaded.is_valid():
		on_loaded.call()
	return true
