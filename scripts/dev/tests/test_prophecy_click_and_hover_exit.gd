extends SceneTree

const ProphecyMenuScene := preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")

var _picked_count: int = 0
var _picked_payload_size: int = -1


func _init() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_click_and_hover_exit] failed to instantiate ProphecyMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	menu.open(null, 2, 0)

	var card := _find_first_card(menu.options_container)
	if card == null:
		push_error("[test_prophecy_click_and_hover_exit] no prophecy wave cards found")
		quit(1)
		return

	card.picked.connect(_on_card_picked)

	var click_down := InputEventMouseButton.new()
	click_down.button_index = MOUSE_BUTTON_LEFT
	click_down.pressed = true
	click_down.double_click = false
	card._gui_input(click_down)

	var click_up := InputEventMouseButton.new()
	click_up.button_index = MOUSE_BUTTON_LEFT
	click_up.pressed = false
	click_up.double_click = false
	card._gui_input(click_up)

	if _picked_count != 1:
		push_error("[test_prophecy_click_and_hover_exit] single click must select card (picked_count=%d)" % _picked_count)
		quit(1)
		return

	if _picked_payload_size <= 0:
		push_error("[test_prophecy_click_and_hover_exit] picked signal payload must contain patterns")
		quit(1)
		return

	menu._show_hover_info(card.option_patterns)

	if menu.hover_info_panel == null or not menu.hover_info_panel.visible:
		push_error("[test_prophecy_click_and_hover_exit] hover panel must be visible after hover")
		quit(1)
		return

	menu.notification(Node.NOTIFICATION_WM_MOUSE_EXIT)

	if menu.hover_info_panel.visible:
		push_error("[test_prophecy_click_and_hover_exit] hover panel must hide when mouse leaves window")
		quit(1)
		return

	print("[test_prophecy_click_and_hover_exit] PASS")
	quit(0)


func _on_card_picked(option_patterns: Array) -> void:
	_picked_count += 1
	_picked_payload_size = option_patterns.size()


func _find_first_card(node: Node) -> ProphecyWaveCard:
	if node == null:
		return null
	if node is ProphecyWaveCard:
		return node as ProphecyWaveCard
	for child in node.get_children():
		var found := _find_first_card(child)
		if found != null:
			return found
	return null
