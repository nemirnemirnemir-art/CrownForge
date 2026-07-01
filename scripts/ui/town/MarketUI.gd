extends Control
class_name MarketUI

const PathRegistryScript := preload("res://scripts/systems/PathRegistry.gd")
const UNDER_TEXTURE: Texture2D = preload("res://assets/ui/buildings/under.png")

signal trade_requested(resource_id: String)
signal close_requested

@onready var _title: Label = $Panel/Margin/VBox/Title
@onready var _row: HBoxContainer = $Panel/Margin/VBox/OptionsRow

const BASE_TRADES = [
	{"id": "", "amount": 0, "to": "", "to_amount": 0, "label": "Nothing"},
	{"id": "wheat", "amount": 1, "to": "gold", "to_amount": 1},
	{"id": "iron_ore", "amount": 1, "to": "gold", "to_amount": 1},
	{"id": "flour", "amount": 1, "to": "gold", "to_amount": 3},
	{"id": "steel", "amount": 1, "to": "gold", "to_amount": 3},
]

const EXTENDED_TRADES = [
	{"id": "clay", "amount": 1, "to": "gold", "to_amount": 1},
	{"id": "grapes", "amount": 1, "to": "gold", "to_amount": 1},
	{"id": "crystal", "amount": 1, "to": "gold", "to_amount": 1},
]

func _ready() -> void:
	visible = false
	if _title:
		_title.text = "Market"
	_setup_buttons()
	set_process_unhandled_input(true)

func _setup_buttons() -> void:
	for child in _row.get_children():
		child.queue_free()

	for trade in _get_trade_options():
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(84, 108)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.set_meta("trade_id", String(trade.id))

		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_child(vb)

		var icon_wrap := Control.new()
		icon_wrap.custom_minimum_size = Vector2(64, 64)
		icon_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(icon_wrap)

		var under := TextureRect.new()
		under.texture = UNDER_TEXTURE
		under.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		under.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		under.anchor_right = 1.0
		under.anchor_bottom = 1.0
		under.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_wrap.add_child(under)

		var tex = _get_icon_for_id(String(trade.id))
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.anchor_left = 0.15
			icon.anchor_top = 0.15
			icon.anchor_right = 0.85
			icon.anchor_bottom = 0.85
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_wrap.add_child(icon)

		var label := Label.new()
		label.text = String(trade.get("label", _get_trade_label(String(trade.id))))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(label)

		btn.pressed.connect(_on_btn_pressed.bind(trade.id))
		btn.mouse_entered.connect(_on_btn_mouse_entered.bind(trade))
		btn.mouse_exited.connect(_on_btn_mouse_exited)
		_row.add_child(btn)

func _get_trade_options() -> Array:
	var trades := BASE_TRADES.duplicate(true)
	if _has_extended_market_trades():
		trades.append_array(EXTENDED_TRADES.duplicate(true))
	return trades

func _get_trade_label(resource_id: String) -> String:
	match resource_id:
		"":
			return "Nothing"
		"wheat":
			return "Wheat"
		"iron_ore":
			return "Iron Ore"
		"flour":
			return "Flour"
		"clay":
			return "Clay"
		"grapes":
			return "Grapes"
		"steel":
			return "Steel"
		"crystal":
			return "Crystal"
		_:
			return resource_id.capitalize()

func _get_icon_for_id(res_id: String) -> Texture2D:
	if res_id == "":
		return null
	var res_map = {
		"gold": "gold_4", "wheat": "wheat_7", "iron_ore": "iron_ore_5", 
		"flour": "flour_8", "steel": "iron_ingot_6", "clay": "clay_3", "grapes": "grapes_10", "crystal": "crystal"
	}
	return PathRegistryScript.load_resource_icon(res_id, res_map)

func _on_btn_pressed(resource_id: String) -> void:
	_hide_trade_tooltip()
	trade_requested.emit(resource_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_hide_trade_tooltip()

var _tooltip = null
func _on_btn_mouse_entered(trade: Dictionary) -> void:
	_show_trade_tooltip(trade)

func _on_btn_mouse_exited() -> void:
	_hide_trade_tooltip()

func _show_trade_tooltip(trade: Dictionary) -> void:
	var tooltip_scene = load("res://scenes/ui/town/BuildingsTooltip.tscn")
	if not tooltip_scene:
		return

	_tooltip = tooltip_scene.instantiate()
	var main_ui: Node = null
	var tree := get_tree()
	if tree and tree.current_scene:
		main_ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
	if main_ui == null:
		main_ui = tree.get_first_node_in_group("main_ui")
	if main_ui and main_ui.has_method("add_popup"):
		main_ui.add_popup(_tooltip)
	elif main_ui:
		main_ui.add_child(_tooltip)
	else:
		add_child(_tooltip)

	_tooltip.z_index = 100
	_tooltip.top_level = true
	_tooltip.setup_for_trade(trade)

	_tooltip.global_position = get_global_mouse_position() + Vector2(10, 10)

func _hide_trade_tooltip() -> void:
	if _tooltip:
		_tooltip.queue_free()
		_tooltip = null

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	var panel := get_node_or_null("Panel") as Control
	if panel == null:
		return
	var rect := Rect2(panel.global_position, panel.size)
	if rect.has_point(mouse_event.global_position):
		return
	close_requested.emit()

func _has_extended_market_trades() -> bool:
	var tree := get_tree()
	if tree == null or tree.root == null:
		return false
	var artifact_core := tree.root.get_node_or_null("ArtifactCore")
	if artifact_core == null or not artifact_core.has_method("has_extended_market_trades"):
		return false
	return bool(artifact_core.call("has_extended_market_trades"))
