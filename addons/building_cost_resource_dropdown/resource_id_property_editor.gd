@tool
extends EditorProperty

const ResourceCoreScript := preload("res://core/resource_core.gd")

var _option: OptionButton
var _updating := false
var _target: Object
var _ids: Array[String] = []

func _init() -> void:
	_option = OptionButton.new()
	add_child(_option)
	add_focusable(_option)
	_option.item_selected.connect(_on_item_selected)

func setup(target: Object) -> void:
	_target = target
	_ids = _get_resource_ids()
	_rebuild_items()
	_update_selection_from_target()

func _update_property() -> void:
	_update_selection_from_target()

func _get_resource_ids() -> Array[String]:
	var ids: Array[String] = []
	if ResourceCoreScript:
		var all := ResourceCoreScript.RESOURCE_IDS
		for v in all:
			if v is String:
				ids.append(v)
	ids.sort()
	return ids

func _rebuild_items() -> void:
	_updating = true
	_option.clear()
	_option.add_item("", 0)
	for i in range(_ids.size()):
		_option.add_item(_ids[i], i + 1)
	_updating = false

func _update_selection_from_target() -> void:
	if _target == null:
		return
	_updating = true
	var cur: String = ""
	if "resource_id" in _target:
		cur = String(_target.resource_id)
	var idx := _ids.find(cur)
	_option.select(idx + 1 if idx != -1 else 0)
	_updating = false

func _on_item_selected(index: int) -> void:
	if _updating:
		return
	if _target == null:
		return
	var value := ""
	if index > 0 and index - 1 < _ids.size():
		value = _ids[index - 1]
	_target.resource_id = value
	emit_changed("resource_id", value)
