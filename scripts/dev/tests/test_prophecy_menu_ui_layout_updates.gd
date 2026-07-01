extends SceneTree

const ProphecyMenuScene = preload("res://scenes/ui/prophecy/ProphecyMenu.tscn")

func _init() -> void:
	var menu := ProphecyMenuScene.instantiate() as ProphecyMenu
	if menu == null:
		push_error("[test_prophecy_menu_ui_layout_updates] failed to instantiate ProphecyMenu")
		quit(1)
		return

	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: ProphecyMenu) -> void:
	menu.open(null, 2, 0)

	if menu.continue_button == null:
		push_error("[test_prophecy_menu_ui_layout_updates] continue_button is null")
		quit(1)
		return

	if abs(menu.continue_button.anchor_left - 0.5) > 0.001 or abs(menu.continue_button.anchor_right - 0.5) > 0.001:
		push_error("[test_prophecy_menu_ui_layout_updates] continue button must be centered by anchors")
		quit(1)
		return

	var selected_bar := menu.get_node_or_null("Root/SelectedBar") as Control
	if selected_bar == null:
		push_error("[test_prophecy_menu_ui_layout_updates] selected bar not found")
		quit(1)
		return

	if selected_bar.offset_top > -300.0 or selected_bar.offset_bottom > -120.0:
		push_error("[test_prophecy_menu_ui_layout_updates] selected bar must be moved up")
		quit(1)
		return

	var hard_title := menu.get_node_or_null("Root/SelectedBar/SlotsWrapper/LegendAndSlots/TierLegend/HardRow/Content/Title") as Label
	var hard_must := menu.get_node_or_null("Root/SelectedBar/SlotsWrapper/LegendAndSlots/TierLegend/HardRow/Content/Badge") as Label
	var hard_banner := menu.get_node_or_null("Root/SelectedBar/SlotsWrapper/LegendAndSlots/TierLegend/HardRow/Banner") as TextureRect

	if hard_title == null or hard_must == null or hard_banner == null:
		push_error("[test_prophecy_menu_ui_layout_updates] HARD legend row nodes are missing")
		quit(1)
		return

	if hard_title.get_theme_font_size("font_size") < 36 or hard_must.get_theme_font_size("font_size") < 30:
		push_error("[test_prophecy_menu_ui_layout_updates] HARD legend text must be 50% larger")
		quit(1)
		return

	if hard_banner.texture == null:
		push_error("[test_prophecy_menu_ui_layout_updates] HARD legend must use banner background texture")
		quit(1)
		return

	var card := _find_first_card(menu.options_container)
	if card == null:
		push_error("[test_prophecy_menu_ui_layout_updates] no prophecy wave cards found")
		quit(1)
		return

	menu._show_hover_info(card.option_patterns)
	await process_frame
	await process_frame

	if menu.hover_info_panel == null or not menu.hover_info_panel.visible:
		push_error("[test_prophecy_menu_ui_layout_updates] hover panel must be visible after hover")
		quit(1)
		return

	if menu.hover_info_panel.size.y < 200.0:
		push_error("[test_prophecy_menu_ui_layout_updates] hover panel height is too small and clips tooltip background")
		quit(1)
		return

	menu._on_card_unhovered()
	await create_timer(0.08).timeout

	if menu.hover_info_panel.visible:
		push_error("[test_prophecy_menu_ui_layout_updates] hover panel must hide after mouse leaves")
		quit(1)
		return

	print("[test_prophecy_menu_ui_layout_updates] PASS")
	quit(0)


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
