extends SceneTree

const CardScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyWaveCard.tscn")

var _picked_count: int = 0


func _init() -> void:
	var card: ProphecyWaveCard = CardScene.instantiate() as ProphecyWaveCard
	if card == null:
		push_error("[test_prophecy_card_small_motion_no_drag] failed to instantiate card")
		quit(1)
		return

	get_root().add_child(card)
	card.setup([ProphecyPattern.new()])
	card.picked.connect(_on_picked)
	call_deferred("_run_test", card)


func _run_test(card: ProphecyWaveCard) -> void:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(40, 20)
	press.global_position = press.position
	card._gui_input(press)

	var drag_data: Variant = card._get_drag_data(Vector2(42, 21))
	if drag_data != null:
		push_error("[test_prophecy_card_small_motion_no_drag] tiny pointer movement must not start drag")
		quit(1)
		return

	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(42, 21)
	release.global_position = release.position
	card._gui_input(release)

	if _picked_count != 1:
		push_error("[test_prophecy_card_small_motion_no_drag] tiny movement click must still pick card (picked_count=%d)" % _picked_count)
		quit(1)
		return

	print("[test_prophecy_card_small_motion_no_drag] PASS")
	quit(0)


func _on_picked(_option_patterns: Array) -> void:
	_picked_count += 1
