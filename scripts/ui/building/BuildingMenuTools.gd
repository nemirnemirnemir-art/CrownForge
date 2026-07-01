extends RefCounted
class_name BuildingMenuTools

const DenariiSellPopupScene: PackedScene = preload("res://core/effects/DenariiSellPopup.tscn")

func setup_tool_buttons(menu: BuildingMenu) -> void:
	if not menu.tools_container:
		return
	var tools = [
		{"id": "destroy", "node_name": "DestroyTool", "name": "Destroy", "color": Color(0.8, 0.2, 0.2)},
		{"id": "sell", "node_name": "SellTool", "name": "Sell", "color": Color(0.2, 0.2, 0.8)}
	]
	for tool_data in tools:
		var btn = menu.get_node_or_null(String(tool_data["node_name"]))
		if btn:
			if btn.has_method("setup"):
				btn.setup(String(tool_data["id"]), String(tool_data["name"]), tool_data["color"])
			var callable := menu._on_tool_pressed.bind(String(tool_data["id"]))
			if not btn.pressed.is_connected(callable):
				btn.pressed.connect(callable)
		else:
			push_warning("[BuildingMenu] Tool button %s not found as direct child" % String(tool_data["node_name"]))

func refresh_tool_visuals(menu: BuildingMenu) -> void:
	if not menu.tools_container:
		return
	for child in menu.tools_container.get_children():
		if child is Button:
			var btn := child as Button
			var is_this_tool = (menu._active_tool != "" and btn.name.begins_with(menu._active_tool.capitalize()))
			btn.button_pressed = is_this_tool

func handle_tool_pressed(menu: BuildingMenu, tool_id: String) -> void:
	if menu._active_tool == tool_id:
		menu._active_tool = ""
	else:
		menu._active_tool = tool_id
		menu._selected_id = ""
		menu._hovered_id = ""
		menu._hide_details_panel()
	refresh_tool_visuals(menu)
	menu._refresh_selection_visuals()

func spawn_denarii_sell_popup(menu: BuildingMenu, global_pos: Vector2, amount: int) -> void:
	if DenariiSellPopupScene == null:
		return
	var popup: Node = DenariiSellPopupScene.instantiate()
	if popup == null:
		return
	var main_ui: Node = null
	var tree := menu.get_tree()
	if tree and tree.current_scene:
		main_ui = tree.current_scene.get_node_or_null("UILayer/MainUI")
	if main_ui == null and tree:
		main_ui = tree.get_first_node_in_group("main_ui")
	if main_ui and main_ui.has_method("add_popup"):
		main_ui.call("add_popup", popup)
	elif main_ui:
		main_ui.add_child(popup)
	elif tree and tree.current_scene:
		tree.current_scene.add_child(popup)
	else:
		menu.add_child(popup)
	if popup is CanvasItem:
		(popup as CanvasItem).top_level = true
	if popup.has_method("setup"):
		popup.call("setup", amount)
	if popup is Node2D:
		(popup as Node2D).global_position = global_pos
