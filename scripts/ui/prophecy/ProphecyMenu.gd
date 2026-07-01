extends Control
class_name ProphecyMenu

signal confirmed(selected_waves: Array)

const ProphecyMenuStateScript := preload("res://scripts/ui/prophecy/modules/ProphecyMenuState.gd")
const ProphecyMenuCardsScript := preload("res://scripts/ui/prophecy/modules/ProphecyMenuCards.gd")
const ProphecyInfoPopupControllerScript := preload("res://scripts/ui/prophecy/modules/ProphecyInfoPopupController.gd")

const OPTIONS_PER_ROW: int = 6
const CURSOR_CYCLE_SEC: float = 1.1
const CURSOR_RISE_PHASE_SEC: float = 0.78
const CURSOR_RISE_DISTANCE: float = 10.0
const CURSOR_Y_OFFSET: float = 30.0

@onready var options_container: VBoxContainer = get_node_or_null("Root/Content/OptionsScroll/Options")
@onready var selected_slot_1 = get_node_or_null("Root/SelectedBar/SlotsWrapper/Slots/Slot1")
@onready var selected_slot_2 = get_node_or_null("Root/SelectedBar/SlotsWrapper/Slots/Slot2")
@onready var selected_slot_3 = get_node_or_null("Root/SelectedBar/SlotsWrapper/Slots/Slot3")
@onready var continue_button: Button = get_node_or_null("Root/ContinueButton")
@onready var selection_cursor: TextureRect = get_node_or_null("Root/SelectionCursor")

@onready var hover_info_panel: Control = get_node_or_null("Root/HoverInfoPanel")
@onready var hover_info_content: Control = get_node_or_null("Root/HoverInfoPanel/Margin/Content")

@onready var info_button: Control = get_node_or_null("Root/InfoButton")
@onready var rewards_info_popup: Control = get_node_or_null("RewardsInfoPopup")
@onready var rewards_info_rows: VBoxContainer = get_node_or_null("RewardsInfoPopup/Margin/VBox/Rows")

var _state: ProphecyMenuState
var _cards: ProphecyMenuCards
var _info_popup_controller: ProphecyInfoPopupController
var _preview_slot_index: int = -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false

    _state = ProphecyMenuStateScript.new()
    _state.setup()
    _cards = ProphecyMenuCardsScript.new()
    _cards.setup()
    _info_popup_controller = ProphecyInfoPopupControllerScript.new()

    if options_container:
        options_container.set("theme_override_constants/separation", 0)
    if selected_slot_1:
        selected_slot_1.slot_index = 0
        if selected_slot_1.has_signal("focused") and not selected_slot_1.focused.is_connected(_on_slot_focused):
            selected_slot_1.focused.connect(_on_slot_focused)
        if selected_slot_1.has_signal("cleared") and not selected_slot_1.cleared.is_connected(_on_slot_cleared):
            selected_slot_1.cleared.connect(_on_slot_cleared)
        if selected_slot_1.has_signal("dropped") and not selected_slot_1.dropped.is_connected(_on_slot_dropped):
            selected_slot_1.dropped.connect(_on_slot_dropped)
    if selected_slot_2:
        selected_slot_2.slot_index = 1
        if selected_slot_2.has_signal("focused") and not selected_slot_2.focused.is_connected(_on_slot_focused):
            selected_slot_2.focused.connect(_on_slot_focused)
        if selected_slot_2.has_signal("cleared") and not selected_slot_2.cleared.is_connected(_on_slot_cleared):
            selected_slot_2.cleared.connect(_on_slot_cleared)
        if selected_slot_2.has_signal("dropped") and not selected_slot_2.dropped.is_connected(_on_slot_dropped):
            selected_slot_2.dropped.connect(_on_slot_dropped)
    if selected_slot_3:
        selected_slot_3.slot_index = 2
        if selected_slot_3.has_signal("focused") and not selected_slot_3.focused.is_connected(_on_slot_focused):
            selected_slot_3.focused.connect(_on_slot_focused)
        if selected_slot_3.has_signal("cleared") and not selected_slot_3.cleared.is_connected(_on_slot_cleared):
            selected_slot_3.cleared.connect(_on_slot_cleared)
        if selected_slot_3.has_signal("dropped") and not selected_slot_3.dropped.is_connected(_on_slot_dropped):
            selected_slot_3.dropped.connect(_on_slot_dropped)
    if continue_button:
        continue_button.pressed.connect(_on_continue_pressed)

    _setup_info_popup()
    _ensure_tier_legend_visual()
    _update_continue_state()

func _process(_delta: float) -> void:
    _update_selection_cursor()
    if _info_popup_controller:
        _info_popup_controller.process_hover_panel(_cards, hover_info_panel, Callable(self, "_is_mouse_over_wave_card"), Callable(self, "_hide_hover_info"))

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_MOUSE_EXIT or what == NOTIFICATION_MOUSE_EXIT:
        _hide_hover_info()

func _unhandled_input(event: InputEvent) -> void:
    if hover_info_panel == null or not hover_info_panel.visible:
        return
    if event is InputEventMouseMotion:
        if not _is_mouse_over_wave_card():
            _hide_hover_info()

func _is_mouse_over_wave_card() -> bool:
    return _cards.is_mouse_over_wave_card(get_viewport()) if _cards else false

func _setup_info_popup() -> void:
    if _info_popup_controller:
        _info_popup_controller.setup_info_popup(rewards_info_popup, rewards_info_rows, info_button, _cards)
    if rewards_info_popup:
        rewards_info_popup.gui_input.connect(_on_info_popup_gui_input)
        rewards_info_popup.mouse_entered.connect(_on_info_popup_mouse_entered)
        rewards_info_popup.mouse_exited.connect(_on_info_popup_mouse_exited)

    if info_button:
        info_button.mouse_entered.connect(_on_info_button_entered)
        info_button.mouse_exited.connect(_on_info_button_exited)

func _on_info_button_entered() -> void:
    if _info_popup_controller:
        _info_popup_controller.on_info_button_entered(rewards_info_popup)

func _on_info_button_exited() -> void:
    if _info_popup_controller:
        _info_popup_controller.on_info_button_exited(rewards_info_popup)

func _on_info_popup_gui_input(event: InputEvent) -> void:
    if _info_popup_controller:
        _info_popup_controller.on_info_popup_gui_input(rewards_info_popup, event)

func _on_info_popup_mouse_entered() -> void:
    if _info_popup_controller:
        _info_popup_controller.on_info_popup_mouse_entered()

func _on_info_popup_mouse_exited() -> void:
    if _info_popup_controller:
        _info_popup_controller.on_info_popup_mouse_exited(rewards_info_popup)

func open(pool: ProphecyPatternPool, prophecy_level: int = 1, locked_slot_count: int = 0) -> void:
    _state.reset(pool, prophecy_level, locked_slot_count)
    _preview_slot_index = -1
    visible = true
    _generate_and_render()
    _update_option_cards_state()
    _update_continue_state()
    _update_selection_cursor()

func close_menu() -> void:
    _hide_hover_info()
    _preview_slot_index = -1
    visible = false
    if selection_cursor:
        selection_cursor.visible = false

func _on_continue_pressed() -> void:
    if not _state.can_continue():
        return
    confirmed.emit(_state.selected)
    close_menu()

func _on_slot_cleared(index: int) -> void:
    _state.remove_bottom_pattern_from_slot(index)
    _render_selected()
    _update_option_cards_state()
    _update_continue_state()
    _update_selection_cursor()

func _on_slot_dropped(index: int, option_patterns: Array) -> void:
    _state.set_target_slot_index(index)
    var placed_index := _state.try_add_pattern_to_best_slot(index, option_patterns)
    if placed_index >= 0:
        _render_selected()
        _update_option_cards_state()
        _update_continue_state()
        _update_selection_cursor()


func _on_slot_focused(index: int) -> void:
    _state.set_target_slot_index(index)
    _preview_slot_index = -1
    _update_selection_cursor()

func _on_card_hovered(option_patterns: Array) -> void:
    _preview_slot_index = _state.get_preview_slot_for_option(option_patterns, _state.get_target_slot_index())
    _update_selection_cursor()
    if _info_popup_controller:
        _info_popup_controller.handle_card_hovered(option_patterns, _cards, hover_info_panel, hover_info_content, Callable(self, "_layout_hover_info_panel"), Callable(self, "_layout_hover_info_panel_deferred"))

func _on_card_unhovered() -> void:
    _preview_slot_index = -1
    _update_selection_cursor()
    if _info_popup_controller:
        await _info_popup_controller.handle_card_unhovered(self, _cards, Callable(self, "_is_mouse_over_wave_card"), Callable(self, "_hide_hover_info"))

func _show_hover_info(option_patterns: Array) -> void:
    _on_card_hovered(option_patterns)

func _try_add_pattern_to_slot(index: int, option_patterns: Array) -> bool:
    var ok := _state.try_add_pattern_to_slot(index, option_patterns)
    if ok:
        _render_selected()
        _update_option_cards_state()
        _update_continue_state()
        _update_selection_cursor()
    return ok

func _hide_hover_info() -> void:
    _cards.hide_hover_info(hover_info_panel, hover_info_content)

func _layout_hover_info_panel() -> void:
    _cards.layout_hover_info_panel(hover_info_panel, hover_info_content)

func _layout_hover_info_panel_deferred() -> void:
    await get_tree().process_frame
    _layout_hover_info_panel()

func _select_from_card(option_patterns: Array) -> void:
    var target_index := _state.get_target_slot_index()
    var placed_index := _state.try_add_pattern_to_best_slot(target_index, option_patterns)
    if placed_index >= 0:
        _render_selected()
        _update_option_cards_state()
        _update_continue_state()
        _update_selection_cursor()
        return

func _get_slot_by_index(index: int) -> Control:
    match index:
        0:
            return selected_slot_1 as Control
        1:
            return selected_slot_2 as Control
        2:
            return selected_slot_3 as Control
        _:
            return null

func _get_cursor_animation_offset() -> float:
    var cycle_pos: float = fmod(float(Time.get_ticks_msec()) / 1000.0, CURSOR_CYCLE_SEC)
    if cycle_pos <= CURSOR_RISE_PHASE_SEC:
        var rise_t: float = cycle_pos / CURSOR_RISE_PHASE_SEC
        return -CURSOR_RISE_DISTANCE * rise_t * rise_t
    var fall_duration: float = maxf(0.01, CURSOR_CYCLE_SEC - CURSOR_RISE_PHASE_SEC)
    var fall_t: float = (cycle_pos - CURSOR_RISE_PHASE_SEC) / fall_duration
    return -CURSOR_RISE_DISTANCE * (1.0 - fall_t)

func _update_selection_cursor() -> void:
    if selection_cursor == null:
        return
    if not visible:
        selection_cursor.visible = false
        return

    var target_index := _preview_slot_index if _preview_slot_index >= 0 else _state.get_target_slot_index()
    var target_slot := _get_slot_by_index(target_index)
    if _state.is_all_slots_full() or target_slot == null or not target_slot.visible or _state.is_slot_locked(target_index):
        selection_cursor.visible = false
        return

    var cursor_size := selection_cursor.size
    if cursor_size == Vector2.ZERO and selection_cursor.texture:
        cursor_size = selection_cursor.texture.get_size()

    selection_cursor.visible = true
    var scaled_cursor_size := cursor_size * selection_cursor.scale
    selection_cursor.global_position = target_slot.global_position + Vector2(
        (target_slot.size.x - scaled_cursor_size.x) * 0.5,
        -scaled_cursor_size.y - CURSOR_Y_OFFSET + _get_cursor_animation_offset()
    )

func _render_selected() -> void:
    if selected_slot_1:
        selected_slot_1.set_locked(_state.is_slot_locked(0))
        selected_slot_1.set_option(_state.selected[0])
    if selected_slot_2:
        selected_slot_2.set_locked(_state.is_slot_locked(1))
        selected_slot_2.set_option(_state.selected[1])
    if selected_slot_3:
        selected_slot_3.set_locked(_state.is_slot_locked(2))
        selected_slot_3.set_option(_state.selected[2])

func _update_continue_state() -> void:
    if continue_button:
        continue_button.disabled = not _state.can_continue()

func _generate_and_render() -> void:
    if not options_container:
        return
    for ch in options_container.get_children():
        ch.queue_free()

    var options := _state.generate_wave_options()

    var options_hard: Array = []
    var options_mid: Array = []
    var options_easy: Array = []
    for patterns in options:
        if patterns == null:
            continue
        var p := _state.extract_single_pattern(patterns)
        if p == null:
            continue
        match ProphecyOptionGenerator.get_pattern_tier(p):
            ProphecyPattern.DifficultyTier.HARD:
                options_hard.append(patterns)
            ProphecyPattern.DifficultyTier.MID:
                options_mid.append(patterns)
            ProphecyPattern.DifficultyTier.EASY:
                options_easy.append(patterns)
            _:
                options_mid.append(patterns)

    if not options_easy.is_empty():
        _cards.add_section_banner(options_container, "EASY")
        _cards.add_rows_from_list(options_easy, OPTIONS_PER_ROW, options_container, _state, Callable(self, "_on_card_hovered"), Callable(self, "_on_card_unhovered"), Callable(self, "_select_from_card"))

    if not options_mid.is_empty():
        _cards.add_section_banner(options_container, "MID")
        _cards.add_rows_from_list(options_mid, OPTIONS_PER_ROW, options_container, _state, Callable(self, "_on_card_hovered"), Callable(self, "_on_card_unhovered"), Callable(self, "_select_from_card"))

    if not options_hard.is_empty():
        _cards.add_section_banner(options_container, "HARD")
        _cards.add_rows_from_list(options_hard, OPTIONS_PER_ROW, options_container, _state, Callable(self, "_on_card_hovered"), Callable(self, "_on_card_unhovered"), Callable(self, "_select_from_card"))

    _render_selected()

func _update_option_cards_state() -> void:
    _cards.update_option_cards_state(options_container, _state)

func _ensure_tier_legend_visual() -> void:
    var slots_wrapper := get_node_or_null("Root/SelectedBar/SlotsWrapper") as Control
    var slots := get_node_or_null("Root/SelectedBar/SlotsWrapper/Slots") as Control
    if slots_wrapper == null or slots == null:
        return
    if slots_wrapper.get_node_or_null("LegendAndSlots") != null:
        return

    var row := HBoxContainer.new()
    row.name = "LegendAndSlots"
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.set("theme_override_constants/separation", 16)

    slots_wrapper.remove_child(slots)
    slots_wrapper.add_child(row)
    row.add_child(_cards.build_tier_legend())
    row.add_child(slots)
