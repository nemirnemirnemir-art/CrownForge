extends SceneTree

const BasicConstructionUIScene := preload("res://scenes/ui/town/BasicConstructionUI.tscn")


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
	push_error("[test_basic_construction_ui] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var ui := BasicConstructionUIScene.instantiate()
	root.add_child(ui)

	await process_frame

	if not _assert_true(ui.visible == false, "basic construction ui must start hidden"):
		return
	if not _assert_true(ui.has_signal("close_requested"), "basic construction ui must expose close_requested signal"):
		return
	if not _assert_true(ui._row.get_child_count() >= 1, "basic construction ui must build options including empty slot"):
		return

	var first_btn := ui._row.get_child(0) as Button
	if not _assert_true(first_btn != null, "first construction option must be a button"):
		return
	var first_label := first_btn.find_children("", "Label", true, false).front() as Label
	if not _assert_true(first_label != null and first_label.text == "Nothing", "construction first option must be Nothing"):
		return
	ui.setup(false)
	if not _assert_true(first_btn.disabled == false, "Nothing option must stay enabled when construction is not ready"):
		return
	var second_btn := ui._row.get_child(1) as Button
	if not _assert_true(second_btn != null and second_btn.disabled, "real construction targets must stay disabled when not ready"):
		return
	ui.setup(true)

	var requested: Array[String] = []
	ui.target_requested.connect(func(building_id: String) -> void:
		requested.append(building_id)
	)
	first_btn.pressed.emit()
	if not _assert_true(requested == [""], "Nothing option must request empty construction target"):
		return

	ui.visible = true
	ui.position = Vector2(40, 50)
	ui.size = Vector2(420, 160)
	var panel := ui.get_node_or_null("Panel") as Control
	if panel != null:
		panel.position = Vector2.ZERO
		panel.size = Vector2(420, 160)
	var close_counter := FakeCounter.new()
	ui.close_requested.connect(Callable(close_counter, "bump"))
	var click_outside := InputEventMouseButton.new()
	click_outside.button_index = MOUSE_BUTTON_LEFT
	click_outside.pressed = true
	click_outside.position = Vector2(9999, 9999)
	click_outside.global_position = Vector2(9999, 9999)
	ui._unhandled_input(click_outside)
	if not _assert_true(close_counter.count == 1, "click outside construction ui must request close"):
		return

	print("[test_basic_construction_ui] PASS")
	quit(0)
