extends SceneTree

const BoardSlotUIScript := preload("res://scripts/dev/ten_kings/TenKingsBoardSlotUI.gd")
const CardLib := preload("res://scripts/dev/ten_kings/TenKingsCardLibrary.gd")

var _failed: bool = false


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await _test_building_preview_uses_on_field_sprite()
	await _test_troop_preview_uses_dense_figures()
	if _failed:
		quit(1)
		return
	print("[test_ten_kings_phase2_board_presentation] PASS")
	quit(0)


func _test_building_preview_uses_on_field_sprite() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var slot_ui := BoardSlotUIScript.new()
	root.add_child(slot_ui)
	slot_ui.setup(Vector2i(2, 2), 104.0)
	await process_frame

	if not slot_ui.has_method("set_preview_data"):
		push_error("[test_ten_kings_phase2_board_presentation] Board slot UI must expose set_preview_data")
		_failed = true
		root.queue_free()
		return

	slot_ui.update_display(BoardSlotUIScript.STATE_OCCUPIED, null, 1, "", 0)
	slot_ui.call("set_preview_data", {
		"card_id": CardLib.CARD_CASTLE,
		"side": 0,
		"stack_count": 1,
		"level": 1,
		"kind": "building",
		"damage_total": 0,
	})
	await process_frame

	var building_rect := slot_ui.get_node_or_null("Layout/PreviewLayer/BuildingSprite") as TextureRect
	if building_rect == null or not building_rect.visible or building_rect.texture == null:
		push_error("[test_ten_kings_phase2_board_presentation] Building preview must show on-field sprite")
		_failed = true

	var pack_grid := slot_ui.get_node_or_null("Layout/PackGrid") as GridContainer
	if pack_grid != null and pack_grid.visible:
		push_error("[test_ten_kings_phase2_board_presentation] Building preview must not use legacy pack grid")
		_failed = true

	root.queue_free()
	await process_frame


func _test_troop_preview_uses_dense_figures() -> void:
	var root := Control.new()
	get_root().add_child(root)

	var slot_ui := BoardSlotUIScript.new()
	root.add_child(slot_ui)
	slot_ui.setup(Vector2i(1, 2), 104.0)
	await process_frame

	slot_ui.update_display(BoardSlotUIScript.STATE_OCCUPIED, null, 1, "", 0)
	slot_ui.call("set_preview_data", {
		"card_id": CardLib.CARD_SOLDIER,
		"side": 0,
		"stack_count": 18,
		"level": 1,
		"kind": "troop",
		"damage_total": 0,
	})
	await process_frame

	var preview_layer := slot_ui.get_node_or_null("Layout/PreviewLayer") as Control
	if preview_layer == null:
		push_error("[test_ten_kings_phase2_board_presentation] Troop preview layer missing")
		_failed = true
		root.queue_free()
		return

	var visible_figures := 0
	for child: Node in preview_layer.get_children():
		if child is TextureRect and child.name.begins_with("TroopFigure") and child.visible:
			visible_figures += 1
	if visible_figures < 3:
		push_error("[test_ten_kings_phase2_board_presentation] Troop preview must show dense figure stack")
		_failed = true

	var icon_rect := slot_ui.get_node_or_null("Layout/IconRect") as TextureRect
	if icon_rect != null and icon_rect.visible:
		push_error("[test_ten_kings_phase2_board_presentation] Troop preview must replace legacy single icon")
		_failed = true

	root.queue_free()
	await process_frame
