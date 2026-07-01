extends HBoxContainer
class_name ResourceAmountRow

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")

@onready var _icon: TextureRect = get_node_or_null("Icon")
@onready var _value_label: Label = get_node_or_null("ValueLabel")

var _resource_id: String = ""

func setup(resource_id: String, required_amount: int, owned_amount: int = -1) -> void:
	_resource_id = resource_id
	_set_icon(resource_id)

	if _value_label:
		if owned_amount >= 0:
			_value_label.text = "%d / %d" % [owned_amount, required_amount]
			if owned_amount < required_amount:
				_value_label.modulate = Color(0.85, 0.25, 0.2, 1.0)  # Dark red for insufficient
			else:
				_value_label.modulate = Color(0, 0, 0, 1.0)
		else:
			_value_label.text = str(required_amount)
			_value_label.modulate = Color(0, 0, 0, 1.0)

func _set_icon(resource_id: String) -> void:
	if not _icon:
		return

	var res_map = {
		"wood": "wood_1",
		"gold": "gold_4",
		"clay": "clay_3",
		"wheat": "wheat_7",
		"meat": "meat_9",
		"iron_ore": "iron_ore_5",
		"ore": "iron_ore_5",
		"flour": "flour_8",
		"stone": "stone_2",
		"water": "water_-1",
		"mana": "mana_8",
		"steel": "iron_ingot_6",
		"metal": "iron_ingot_6"
	}

	_icon.texture = PathRegistryScript.load_resource_icon(resource_id, res_map)
