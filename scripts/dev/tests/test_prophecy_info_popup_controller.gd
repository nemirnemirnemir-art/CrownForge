extends SceneTree

const CONTROLLER_PATH := "res://scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd"


class FakeHost:
	extends Control


class FakeCards:
	extends RefCounted

	const HOVER_PANEL_FALLBACK_HIDE_DELAY_SEC: float = 0.12

	var hover_gen: int = 0
	var hover_info_last_interaction_time_sec: float = 0.0
	var populate_calls: int = 0
	var shown_payloads: Array = []

	func populate_possible_rewards(_container: Node) -> void:
		populate_calls += 1

	func show_hover_info(option_patterns: Array, hover_info_panel: Control, _hover_info_content: Control) -> void:
		shown_payloads.append(option_patterns.duplicate(true))
		hover_info_panel.show()
		hover_info_last_interaction_time_sec = Time.get_ticks_msec() / 1000.0


var _pointer_over_wave_card: bool = false
var _hide_hover_calls: int = 0
var _layout_calls: int = 0
var _layout_deferred_calls: int = 0
var _hover_panel: PanelContainer


func _init() -> void:
	call_deferred("_run_test")


func _assert(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("[test_prophecy_info_popup_controller] %s" % message)
	quit(1)
	return false


func _run_test() -> void:
	var controller_script := load(CONTROLLER_PATH)
	if not _assert(controller_script != null, "failed to load ProphecyInfoPopupController.gd"):
		return

	var controller = controller_script.new()
	if not _assert(controller != null, "failed to instantiate ProphecyInfoPopupController"):
		return
	if not _assert(not controller.has_method("open"), "controller must not own menu open flow"):
		return
	if not _assert(not controller.has_method("close_menu"), "controller must not own menu close flow"):
		return

	var cards := FakeCards.new()
	var popup := PanelContainer.new()
	popup.global_position = Vector2(400, 400)
	var rows := VBoxContainer.new()
	popup.add_child(rows)
	var info_button := Control.new()
	var hover_host := FakeHost.new()
	get_root().add_child(info_button)
	get_root().add_child(popup)
	get_root().add_child(hover_host)

	controller.call("setup_info_popup", popup, rows, info_button, cards)
	if not _assert(not popup.visible, "setup must keep rewards info popup hidden"):
		return
	if not _assert(cards.populate_calls == 1, "setup must populate reward rows once"):
		return

	controller.call("on_info_button_entered", popup)
	if not _assert(popup.visible, "info button hover must show popup"):
		return
	if not _assert(popup.global_position == Vector2(40, 90), "first show must use default popup position"):
		return

	controller.call("on_info_button_exited", popup)
	if not _assert(not popup.visible, "popup must hide after button exit when nothing else is hovered"):
		return

	controller.call("on_info_button_entered", popup)
	controller.call("on_info_popup_mouse_entered")
	controller.call("on_info_button_exited", popup)
	if not _assert(popup.visible, "popup must stay visible while popup hover is active"):
		return
	controller.call("on_info_popup_mouse_exited", popup)
	if not _assert(not popup.visible, "popup must hide after popup hover ends"):
		return

	controller.call("on_info_button_entered", popup)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.global_position = Vector2(50, 100)
	controller.call("on_info_popup_gui_input", popup, press)
	var motion := InputEventMouseMotion.new()
	motion.global_position = Vector2(80, 150)
	controller.call("on_info_popup_gui_input", popup, motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.global_position = Vector2(80, 150)
	controller.call("on_info_popup_gui_input", popup, release)
	controller.call("on_info_button_exited", popup)
	if not _assert(not popup.visible, "popup must hide after drag completes and hover ends"):
		return
	controller.call("on_info_button_entered", popup)
	if not _assert(popup.global_position == Vector2(70, 140), "popup must remember dragged position between shows"):
		return

	_hover_panel = PanelContainer.new()
	var hover_content := VBoxContainer.new()
	_hover_panel.add_child(hover_content)
	get_root().add_child(_hover_panel)
	_hide_hover_calls = 0
	_layout_calls = 0
	_layout_deferred_calls = 0

	controller.call(
		"handle_card_hovered",
		[{"id": "pattern_a"}],
		cards,
		_hover_panel,
		hover_content,
		Callable(self, "_layout_hover_now"),
		Callable(self, "_layout_hover_deferred")
	)
	if not _assert(_hover_panel.visible, "card hover must show hover panel"):
		return
	if not _assert(cards.shown_payloads.size() == 1, "card hover must pass payload into cards helper"):
		return
	if not _assert(_layout_calls == 1 and _layout_deferred_calls == 1, "card hover must keep both layout callbacks"):
		return

	_pointer_over_wave_card = false
	controller.call(
		"process_hover_panel",
		cards,
		_hover_panel,
		Callable(self, "_is_pointer_over_wave_card"),
		Callable(self, "_hide_hover_info")
	)
	if not _assert(_hover_panel.visible, "hover panel must stay visible during fallback hide delay"):
		return

	cards.hover_info_last_interaction_time_sec = (Time.get_ticks_msec() / 1000.0) - 0.2
	controller.call(
		"process_hover_panel",
		cards,
		_hover_panel,
		Callable(self, "_is_pointer_over_wave_card"),
		Callable(self, "_hide_hover_info")
	)
	if not _assert(_hide_hover_calls == 1 and not _hover_panel.visible, "hover panel must hide after fallback delay expires"):
		return

	_hover_panel.show()
	_pointer_over_wave_card = true
	controller.call(
		"handle_card_unhovered",
		hover_host,
		cards,
		Callable(self, "_is_pointer_over_wave_card"),
		Callable(self, "_hide_hover_info")
	)
	await create_timer(0.08).timeout
	if not _assert(_hover_panel.visible, "unhover guard must keep panel visible while pointer is still over a wave card"):
		return

	_pointer_over_wave_card = false
	controller.call(
		"handle_card_unhovered",
		hover_host,
		cards,
		Callable(self, "_is_pointer_over_wave_card"),
		Callable(self, "_hide_hover_info")
	)
	await create_timer(0.08).timeout
	if not _assert(not _hover_panel.visible, "unhover guard must hide panel after pointer leaves wave cards"):
		return

	print("[test_prophecy_info_popup_controller] PASS")
	quit(0)


func _is_pointer_over_wave_card() -> bool:
	return _pointer_over_wave_card


func _hide_hover_info() -> void:
	_hide_hover_calls += 1
	if _hover_panel != null:
		_hover_panel.hide()


func _layout_hover_now() -> void:
	_layout_calls += 1


func _layout_hover_deferred() -> void:
	_layout_deferred_calls += 1
