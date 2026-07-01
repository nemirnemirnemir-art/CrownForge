extends RefCounted
class_name SaveRegistryFlow


func register_module(save_modules: Dictionary, save_key: String, module: Object) -> void:
	if save_key == "" or module == null:
		return
	save_modules[save_key] = module


func derive_save_key(autoload_name: String) -> String:
	var core_name := autoload_name
	if core_name.ends_with("Core"):
		core_name = core_name.substr(0, core_name.length() - 4)
	var snake := ""
	for i in range(core_name.length()):
		var ch := core_name[i]
		var is_upper := ch.to_upper() == ch and ch.to_lower() != ch
		if i > 0 and is_upper:
			snake += "_"
		snake += ch.to_lower()
	match snake:
		"hero": return "heroes"
		"skill": return "skills"
		"resource": return "resources"
		"player_inventory": return "inventory"
		_: return snake


func try_register_save_target(save_modules: Dictionary, autoload_name: String, obj: Object) -> void:
	if obj == null:
		return
	var target: Object = null
	if obj.has_method("get_save_data"):
		target = obj
	else:
		var save_load = obj.get("save_load")
		if save_load != null and save_load is Object and (save_load as Object).has_method("get_save_data"):
			target = save_load
	if target == null:
		return
	var key := derive_save_key(autoload_name)
	if key == "":
		return
	register_module(save_modules, key, target)
