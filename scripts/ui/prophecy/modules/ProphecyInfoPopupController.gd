extends RefCounted
class_name ProphecyInfoPopupController

var _info_popup_dragging: bool = false
var _info_popup_drag_offset: Vector2 = Vector2.ZERO
var _info_popup_user_pos: Vector2 = Vector2(40, 90)
var _info_button_hovered: bool = false
var _info_popup_hovered: bool = false


func setup_info_popup(rewards_info_popup: Control, rewards_info_rows: Control, info_button: Control, cards) -> void:
    if rewards_info_popup:
        rewards_info_popup.hide()
        rewards_info_popup.mouse_filter = Control.MOUSE_FILTER_STOP
        rewards_info_popup.z_index = 1000
        rewards_info_popup.global_position = _info_popup_user_pos
    if rewards_info_rows and cards:
        cards.populate_possible_rewards(rewards_info_rows)


func on_info_button_entered(rewards_info_popup: Control) -> void:
    if rewards_info_popup == null:
        return
    _info_button_hovered = true
    rewards_info_popup.global_position = _info_popup_user_pos
    rewards_info_popup.show()


func on_info_button_exited(rewards_info_popup: Control) -> void:
    _info_button_hovered = false
    _maybe_hide_info_popup(rewards_info_popup)


func on_info_popup_gui_input(rewards_info_popup: Control, event: InputEvent) -> void:
    if rewards_info_popup == null:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                _info_popup_dragging = true
                _info_popup_drag_offset = rewards_info_popup.global_position - mb.global_position
            else:
                _info_popup_dragging = false
                _info_popup_user_pos = rewards_info_popup.global_position
                _maybe_hide_info_popup(rewards_info_popup)
    elif event is InputEventMouseMotion and _info_popup_dragging:
        var mm := event as InputEventMouseMotion
        rewards_info_popup.global_position = mm.global_position + _info_popup_drag_offset
        _info_popup_user_pos = rewards_info_popup.global_position


func on_info_popup_mouse_entered() -> void:
    _info_popup_hovered = true


func on_info_popup_mouse_exited(rewards_info_popup: Control) -> void:
    _info_popup_hovered = false
    _maybe_hide_info_popup(rewards_info_popup)


func handle_card_hovered(option_patterns: Array, cards, hover_info_panel: Control, hover_info_content: Control, layout_now: Callable, layout_deferred: Callable) -> void:
    if cards == null:
        return
    cards.hover_gen += 1
    cards.hover_info_last_interaction_time_sec = Time.get_ticks_msec() / 1000.0
    cards.show_hover_info(option_patterns, hover_info_panel, hover_info_content)
    if layout_now.is_valid():
        layout_now.call()
    if layout_deferred.is_valid():
        layout_deferred.call()


func process_hover_panel(cards, hover_info_panel: Control, is_pointer_over_wave_card: Callable, hide_hover_info: Callable) -> void:
    if hover_info_panel == null or not hover_info_panel.visible or cards == null:
        return
    if is_pointer_over_wave_card.is_valid() and bool(is_pointer_over_wave_card.call()):
        cards.hover_info_last_interaction_time_sec = Time.get_ticks_msec() / 1000.0
        return
    if (Time.get_ticks_msec() / 1000.0) - cards.hover_info_last_interaction_time_sec < cards.HOVER_PANEL_FALLBACK_HIDE_DELAY_SEC:
        return
    if hide_hover_info.is_valid():
        hide_hover_info.call()


func handle_card_unhovered(host, cards, is_pointer_over_wave_card: Callable, hide_hover_info: Callable) -> void:
    var gen: int = cards.hover_gen if cards != null else 0
    var tree: Variant = null
    if host is Node and (host as Node).is_inside_tree():
        tree = (host as Node).get_tree()
    elif host is SceneTree:
        tree = host
    if tree == null:
        return
    await tree.create_timer(0.05).timeout
    if cards == null or gen != cards.hover_gen:
        return
    if is_pointer_over_wave_card.is_valid() and bool(is_pointer_over_wave_card.call()):
        cards.hover_info_last_interaction_time_sec = Time.get_ticks_msec() / 1000.0
        return
    if hide_hover_info.is_valid():
        hide_hover_info.call()


func _maybe_hide_info_popup(rewards_info_popup: Control) -> void:
    if rewards_info_popup == null:
        return
    if _info_button_hovered or _info_popup_hovered or _info_popup_dragging:
        return
    rewards_info_popup.hide()
