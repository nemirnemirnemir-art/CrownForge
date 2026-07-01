extends Node

var _seals: Dictionary = {}

func _ready() -> void:
	_load_all_seals()

func _load_all_seals() -> void:
	var path := "res://resources/seals/"
	if not DirAccess.dir_exists_absolute(path):
		# Create directory if it doesn't exist (simulated via write_to_file logic usually, but here just warning)
		return
		
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not file_name.begins_with(".") and (file_name.ends_with(".tres") or file_name.ends_with(".remap")):
				var clean_name = file_name.replace(".remap", "")
				var res = load(path + clean_name)
				if res is SealConfig:
					_seals[res.id] = res
			file_name = dir.get_next()

func get_seal(seal_id: String) -> SealConfig:
	return _seals.get(seal_id)

func get_all_seal_ids() -> Array:
	return _seals.keys()

func can_afford_seal(seal_id: String) -> bool:
	var seal = get_seal(seal_id)
	if not seal: return false
	if not ResourceCore: return false
	
	for res_id in seal.cost:
		if ResourceCore.get_resource(res_id) < seal.cost[res_id]:
			return false
	return true
