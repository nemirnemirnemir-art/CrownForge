extends SceneTree


class HoverProbeMenu:
	extends ProphecyMenu

	var simulate_mouse_over_wave_card: bool = false

	func _is_mouse_over_wave_card() -> bool:
		return simulate_mouse_over_wave_card


func _init() -> void:
	var menu := HoverProbeMenu.new()
	get_root().add_child(menu)
	call_deferred("_run_test", menu)


func _run_test(menu: HoverProbeMenu) -> void:
	menu.hover_info_panel = PanelContainer.new()
	menu.hover_info_content = VBoxContainer.new()
	menu.hover_info_panel.add_child(menu.hover_info_content)
	menu.add_child(menu.hover_info_panel)

	menu.hover_info_panel.show()
	menu.simulate_mouse_over_wave_card = true

	menu._on_card_unhovered()
	await create_timer(0.08).timeout

	if not menu.hover_info_panel.visible:
		push_error("[test_prophecy_hover_unhover_guard] hover panel must stay visible while pointer is still over wave card")
		quit(1)
		return

	menu.simulate_mouse_over_wave_card = false
	menu._on_card_unhovered()
	await create_timer(0.08).timeout

	if menu.hover_info_panel.visible:
		push_error("[test_prophecy_hover_unhover_guard] hover panel must hide after pointer leaves wave cards")
		quit(1)
		return

	print("[test_prophecy_hover_unhover_guard] PASS")
	quit(0)
