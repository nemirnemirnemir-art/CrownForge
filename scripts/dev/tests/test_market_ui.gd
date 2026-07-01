extends SceneTree

const MarketUIScene := preload("res://scenes/ui/town/MarketUI.tscn")


class FakeCounter:
	extends RefCounted

	var count: int = 0

	func bump() -> void:
		count += 1


func _init() -> void:
	call_deferred("_run_test")


func _assert_true(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_market_ui] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var ui := MarketUIScene.instantiate()
	root.add_child(ui)

	await process_frame

	if not _assert_true(ui.visible == false, "market ui must start hidden"):
		return
	if not _assert_true(ui.has_signal("close_requested"), "market ui must expose close_requested signal"):
		return
	if not _assert_true(ui._row.get_child_count() >= 1, "market ui must build options including empty slot"):
		return

	var first_btn := ui._row.get_child(0) as Button
	if not _assert_true(first_btn != null, "first market option must be a button"):
		return
	var first_label := first_btn.get_child(0).get_child(1) as Label
	if not _assert_true(first_label != null and first_label.text == "Nothing", "market first option must be Nothing"):
		return

	var requested: Array[String] = []
	ui.trade_requested.connect(func(resource_id: String) -> void:
		requested.append(resource_id)
	)
	first_btn.pressed.emit()
	if not _assert_true(requested == [""], "Nothing option must request empty trade resource"):
		return

	ui.visible = true
	ui.position = Vector2(40, 50)
	ui.size = Vector2(320, 140)
	var panel := ui.get_node_or_null("Panel") as Control
	if panel != null:
		panel.position = Vector2.ZERO
		panel.size = Vector2(320, 140)
	var close_counter := FakeCounter.new()
	ui.close_requested.connect(Callable(close_counter, "bump"))
	var click_outside := InputEventMouseButton.new()
	click_outside.button_index = MOUSE_BUTTON_LEFT
	click_outside.pressed = true
	click_outside.position = Vector2(9999, 9999)
	click_outside.global_position = Vector2(9999, 9999)
	ui._unhandled_input(click_outside)
	if not _assert_true(close_counter.count == 1, "click outside market ui must request close"):
		return

	print("[test_market_ui] PASS")
	quit(0)
