extends PanelContainer

@onready var cost_rows: VBoxContainer = $VBox/Costs
@onready var all_shapes: Label = $VBox/ShapeBlock/AllShapes

var _gaze_core: Node = null

func _resource_core() -> Node:
	return get_node_or_null("/root/ResourceCore")

func _economy_core() -> Node:
	return get_node_or_null("/root/EconomyCore")

func _event_bus() -> Node:
	return get_node_or_null("/root/EventBus")

const _ICON_MAP := {
	"gold": preload("res://assets/items/resources/gold_4.png"),
	"wheat": preload("res://assets/items/resources/wheat_7.png"),
	"clay": preload("res://assets/items/resources/clay_3.png"),
}

func _ready() -> void:
	_gaze_core = get_node_or_null("/root/GazeCore")
	var resource_core := _resource_core()
	if resource_core and resource_core.has_signal("resource_changed"):
		resource_core.resource_changed.connect(_on_resource_changed)
	var event_bus := _event_bus()
	if event_bus and event_bus.has_signal("gold_changed"):
		event_bus.gold_changed.connect(_on_gold_changed)
	update_info()

func _on_resource_changed(_resource_id: String, _amount: int) -> void:
	update_info()

func _on_gold_changed(_new_amount: float, _delta: float) -> void:
	update_info()

func update_info() -> void:
	var resource_core := _resource_core()
	if _gaze_core == null or resource_core == null:
		return
	# shapes (disabled for now)
	if all_shapes:
		all_shapes.text = "Gaze Shapes:"

	# costs
	for c in cost_rows.get_children():
		c.queue_free()

	var cost: Dictionary = {}
	if _gaze_core.has_method("get_next_upgrade_cost"):
		cost = _gaze_core.call("get_next_upgrade_cost") as Dictionary
	if cost.is_empty():
		var lbl := Label.new()
		lbl.text = "Max level"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_rows.add_child(lbl)
		return

	for res_id in cost.keys():
		var need := int(cost[res_id])
		var have := _get_owned_amount(str(res_id), resource_core)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		x_add_icon_and_label(row, str(res_id), have, need)
		cost_rows.add_child(row)

func x_add_icon_and_label(row: HBoxContainer, res_id: String, have: int, need: int) -> void:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _ICON_MAP.get(res_id, null)
	row.add_child(icon)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.text = "%d/%d" % [have, need]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if have < need:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	row.add_child(lbl)

func _get_owned_amount(res_id: String, resource_core: Node) -> int:
	if res_id == "gold":
		var economy_core := _economy_core()
		if economy_core and economy_core.has_method("get_gold"):
			return int(economy_core.get_gold())
		return 0
	return int(resource_core.get_resource(res_id)) if resource_core and resource_core.has_method("get_resource") else 0
