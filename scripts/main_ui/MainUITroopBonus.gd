extends RefCounted
class_name MainUITroopBonus

var _button: Button = null
var _tooltip: PanelContainer = null
var _rows: Array = []
var _parent: Control = null
var _popup_layer: Control = null

func initialize(parent: Control, popup_layer: Control, resource_hbox: HBoxContainer) -> void:
	_parent = parent
	_popup_layer = popup_layer
	
	if resource_hbox == null:
		return
	
	_button = Button.new()
	_button.name = "TroopBonusesButton"
	_button.text = "Bonuses"
	_button.custom_minimum_size = Vector2(90, 32)
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.pressed.connect(_on_button_pressed)
	_button.mouse_entered.connect(_on_button_mouse_entered)
	_button.mouse_exited.connect(_on_button_mouse_exited)
	resource_hbox.add_child(_button)
	
	var troop_core := _get_troop_bonus_core()
	if troop_core and troop_core.has_signal("bonuses_changed"):
		var cb := Callable(self, "_on_troop_bonuses_changed")
		if not troop_core.is_connected("bonuses_changed", cb):
			troop_core.connect("bonuses_changed", cb)

func _on_button_pressed() -> void:
	pass

func _on_button_mouse_entered() -> void:
	_ensure_tooltip()
	_update_tooltip()
	if _tooltip:
		_tooltip.visible = true
		_tooltip.global_position = _button.global_position + Vector2(-10, _button.size.y + 10)

func _on_button_mouse_exited() -> void:
	if _tooltip:
		_tooltip.visible = false

func _on_troop_bonuses_changed() -> void:
	if _tooltip and _tooltip.visible:
		_update_tooltip()

func _ensure_tooltip() -> void:
	if _tooltip != null and is_instance_valid(_tooltip):
		return

	_tooltip = PanelContainer.new()
	_tooltip.name = "TroopBonusesTooltip"
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 100
	_tooltip.top_level = true
	_tooltip.custom_minimum_size = Vector2(360, 0)

	if _popup_layer:
		_popup_layer.add_child(_tooltip)
	elif _parent:
		_parent.add_child(_tooltip)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	_tooltip.add_child(vbox)

	var header := Label.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.text = "Troop Class Bonuses"
	vbox.add_child(header)

	_rows.clear()
	for class_id in range(8):
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		vbox.add_child(row)

		var class_lbl := Label.new()
		class_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		class_lbl.text = _get_unit_class_name(class_id)
		class_lbl.custom_minimum_size = Vector2(90, 0)
		row.add_child(class_lbl)

		var hp_lbl := Label.new()
		hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(hp_lbl)

		var dmg_lbl := Label.new()
		dmg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dmg_lbl.custom_minimum_size = Vector2(90, 0)
		row.add_child(dmg_lbl)

		var as_lbl := Label.new()
		as_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		as_lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(as_lbl)

		_rows.append({
			"hp": hp_lbl,
			"dmg": dmg_lbl,
			"as": as_lbl,
		})

func _update_tooltip() -> void:
	var troop_core := _get_troop_bonus_core()
	if troop_core == null:
		return

	if _rows.size() < 8:
		return

	for class_id in range(8):
		var row: Dictionary = _rows[class_id]
		var hp_lbl: Label = row.get("hp", null)
		var dmg_lbl: Label = row.get("dmg", null)
		var as_lbl: Label = row.get("as", null)
		if hp_lbl:
			var p_hp := float(troop_core.call("get_bonus_percent", class_id, 0))
			hp_lbl.text = "HP " + _format_signed_pct(p_hp)
		if dmg_lbl:
			var p_dmg := float(troop_core.call("get_bonus_percent", class_id, 1))
			dmg_lbl.text = "DMG " + _format_signed_pct(p_dmg)
		if as_lbl:
			var p_as := float(troop_core.call("get_bonus_percent", class_id, 2))
			as_lbl.text = "AS " + _format_signed_pct(p_as)

func _format_signed_pct(p: float) -> String:
	var v := int(round(p * 100.0))
	if v >= 0:
		return "+" + str(v) + "%"
	return str(v) + "%"

func _get_unit_class_name(class_id: int) -> String:
	match class_id:
		0: return "Grunt"
		1: return "Warrior"
		2: return "Ranged"
		3: return "Rider"
		4: return "Champion"
		5: return "Flying"
		6: return "Arcane"
		7: return "Undead"
	return "Unknown"

func _get_troop_bonus_core() -> Object:
	if _parent == null:
		return null
	var tree := _parent.get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root == null:
		return null
	return root.get_node_or_null("TroopBonusCore")
