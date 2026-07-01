extends RefCounted
class_name MainUIButtonFlow

func connect_buttons(test_gold_button: BaseButton, mine_button: BaseButton, grid: Node, forge_city_button: BaseButton, inventory_city_button: BaseButton, alchemy_city_button: BaseButton, callbacks: Dictionary) -> void:
	_connect_button(test_gold_button, callbacks.get("test_gold", Callable()))
	_connect_button(mine_button, callbacks.get("mine", Callable()))
	_connect_grid_button(grid, "PerksTestButton", callbacks.get("perks", Callable()))
	_apply_debug_button_gating(grid)
	_connect_button(forge_city_button, callbacks.get("forge", Callable()))
	_connect_button(inventory_city_button, callbacks.get("inventory", Callable()))
	_connect_button(alchemy_city_button, callbacks.get("alchemy", Callable()))

func _connect_button(button: BaseButton, callback: Callable) -> void:
	if button == null or not callback.is_valid():
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _connect_grid_button(grid: Node, button_name: String, callback: Callable) -> void:
	if grid == null:
		return
	_connect_button(grid.get_node_or_null(button_name) as BaseButton, callback)

func _apply_debug_button_gating(grid: Node) -> void:
	if grid == null:
		return
	for button_name in ["MineButton", "PerksTestButton", "TestGoldButton"]:
		var button := grid.get_node_or_null(button_name)
		if button == null:
			continue
		if button is CanvasItem:
			(button as CanvasItem).visible = false
		button.process_mode = Node.PROCESS_MODE_DISABLED
