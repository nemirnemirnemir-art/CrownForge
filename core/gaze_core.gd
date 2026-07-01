extends Node

signal gaze_level_changed(level: int)

const MAX_LEVEL: int = 3

const _LEVEL_TO_TILES := [3, 4, 5, 6]

var _gaze_level: int = 0

func get_level() -> int:
	return _gaze_level

func get_current_tiles() -> int:
	return _LEVEL_TO_TILES[clampi(_gaze_level, 0, MAX_LEVEL)]

func get_max_tiles() -> int:
	return _LEVEL_TO_TILES[MAX_LEVEL]

func get_next_upgrade_cost() -> Dictionary:
	var next := _gaze_level + 1
	match next:
		1:
			return {"gold": 113, "wheat": 113}
		2:
			return {"gold": 263, "wheat": 150, "clay": 150}
		3:
			return {"gold": 1125}
		_:
			return {}

func can_upgrade() -> bool:
	if _gaze_level >= MAX_LEVEL:
		return false
	if not ResourceCore and not EconomyCore:
		return false
	var cost := get_next_upgrade_cost()
	for res_id in cost.keys():
		var need := int(cost[res_id])
		if _get_owned_cost_resource(str(res_id)) < need:
			return false
	return true

func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	var cost := get_next_upgrade_cost()
	for res_id in cost.keys():
		var need := int(cost[res_id])
		if need <= 0:
			continue
		if not _consume_cost_resource(str(res_id), need):
			return false
	_gaze_level = clampi(_gaze_level + 1, 0, MAX_LEVEL)
	var artifact_core := _get_artifact_core()
	if artifact_core != null and artifact_core.has_method("on_gaze_upgraded"):
		artifact_core.call("on_gaze_upgraded")
	gaze_level_changed.emit(_gaze_level)
	if SaveCore:
		SaveCore.request_save()
	return true

func get_shape_text(level: int = -1) -> String:
	var lvl := level
	if lvl < 0:
		lvl = _gaze_level
	lvl = clampi(lvl, 0, MAX_LEVEL)
	match lvl:
		0:
			return "■ ■\n■"
		1:
			return "■ ■\n■ ■"
		2:
			return "■ ■\n■ ■ ■"
		3:
			return "■ ■ ■\n■ ■ ■"
		_:
			return ""

func get_save_data() -> Dictionary:
	return {"gaze_level": _gaze_level}

func load_save_data(data: Dictionary) -> void:
	_gaze_level = clampi(int(data.get("gaze_level", 0)), 0, MAX_LEVEL)
	gaze_level_changed.emit(_gaze_level)

func reset() -> void:
	_gaze_level = 0
	gaze_level_changed.emit(_gaze_level)

func _get_artifact_core() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ArtifactCore")


func _get_owned_cost_resource(resource_id: String) -> int:
	if resource_id == "gold":
		if EconomyCore != null and EconomyCore.has_method("get_gold"):
			return int(EconomyCore.get_gold())
		return 0
	if ResourceCore != null and ResourceCore.has_method("get_resource"):
		return int(ResourceCore.get_resource(resource_id))
	return 0


func _consume_cost_resource(resource_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if resource_id == "gold":
		return EconomyCore != null and EconomyCore.has_method("spend_gold") and bool(EconomyCore.spend_gold(float(amount)))
	return ResourceCore != null and ResourceCore.has_method("consume_resource") and bool(ResourceCore.consume_resource(resource_id, amount))
