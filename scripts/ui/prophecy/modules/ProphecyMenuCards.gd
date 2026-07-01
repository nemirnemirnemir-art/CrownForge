extends RefCounted
class_name ProphecyMenuCards

## Handles UI building, hovering, and card instantiation for the Prophecy Menu

const WaveCardScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyWaveCard.tscn")
const ProphecyCardTooltipScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyCardTooltip.tscn")
const ProphecyUIBuilderScript := preload("res://scripts/ui/prophecy/modules/ProphecyUIBuilder.gd")

const HOVER_PANEL_MARGIN_RIGHT := 20.0
const HOVER_PANEL_MARGIN_BOTTOM := 240.0
const HOVER_PANEL_MIN_WIDTH := 620.0
const HOVER_PANEL_MAX_WIDTH := 1020.0
const HOVER_PANEL_MIN_HEIGHT := 220.0
const HOVER_PANEL_MAX_HEIGHT := 620.0
const HOVER_PANEL_PADDING_X := 24.0
const HOVER_PANEL_PADDING_Y := 20.0
const HOVER_PANEL_FALLBACK_HIDE_DELAY_SEC := 0.12

var _ui_builder: ProphecyUIBuilder
var hover_gen: int = 0
var hover_info_last_interaction_time_sec: float = 0.0

func setup() -> void:
    _ui_builder = ProphecyUIBuilderScript.new()

func is_mouse_over_wave_card(viewport: Viewport) -> bool:
    if viewport == null:
        return false

    var hovered := viewport.gui_get_hovered_control()
    var node: Node = hovered
    while node != null:
        if node is ProphecyWaveCard:
            return true
        node = node.get_parent()

    return false

func show_hover_info(option_patterns: Array, hover_info_panel: Control, hover_info_content: Control) -> void:
    if hover_info_panel == null or hover_info_content == null:
        return
    for ch in hover_info_content.get_children():
        ch.queue_free()
    if ProphecyCardTooltipScene and option_patterns != null and not option_patterns.is_empty():
        var inst := ProphecyCardTooltipScene.instantiate()
        if inst is Control:
            (inst as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
            (inst as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
            (inst as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
        hover_info_content.add_child(inst)
        if inst and inst.has_method("setup"):
            inst.call_deferred("setup", option_patterns)
        
        # We assume caller will defer layout calls
        hover_info_panel.show()
        hover_info_last_interaction_time_sec = Time.get_ticks_msec() / 1000.0

func hide_hover_info(hover_info_panel: Control, hover_info_content: Control) -> void:
    if hover_info_panel == null or hover_info_content == null:
        return
    hover_info_panel.hide()
    hover_info_last_interaction_time_sec = 0.0
    for ch in hover_info_content.get_children():
        ch.queue_free()

func layout_hover_info_panel(hover_info_panel: Control, hover_info_content: Control) -> void:
    if hover_info_panel == null or hover_info_content == null:
        return

    var content_size := hover_info_content.get_combined_minimum_size()
    if content_size == Vector2.ZERO:
        content_size = hover_info_content.size

    var target_width := clampf(content_size.x + HOVER_PANEL_PADDING_X, HOVER_PANEL_MIN_WIDTH, HOVER_PANEL_MAX_WIDTH)
    var target_height := clampf(content_size.y + HOVER_PANEL_PADDING_Y, HOVER_PANEL_MIN_HEIGHT, HOVER_PANEL_MAX_HEIGHT)

    hover_info_panel.custom_minimum_size = Vector2(target_width, target_height)
    hover_info_panel.offset_right = -HOVER_PANEL_MARGIN_RIGHT
    hover_info_panel.offset_left = hover_info_panel.offset_right - target_width
    hover_info_panel.offset_bottom = -HOVER_PANEL_MARGIN_BOTTOM
    hover_info_panel.offset_top = hover_info_panel.offset_bottom - target_height

func add_row(patterns_list: Array, options_container: VBoxContainer, state_manager: ProphecyMenuState, connect_hover_func: Callable, connect_unhover_func: Callable, connect_pick_func: Callable) -> void:
    if patterns_list == null or patterns_list.is_empty():
        return
    if not options_container:
        return
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.set("theme_override_constants/separation", 10)
    options_container.add_child(row)

    for patterns in patterns_list:
        var card := WaveCardScene.instantiate()
        row.add_child(card)
        card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        card.setup(patterns)
        if card is ProphecyWaveCard:
            var pwc := card as ProphecyWaveCard
            pwc.option_key = state_manager.compute_option_key(patterns)
            pwc.set_used(state_manager.is_option_used(pwc.option_patterns))
            if pwc.has_signal("hovered"):
                pwc.hovered.connect(connect_hover_func)
            if pwc.has_signal("unhovered"):
                pwc.unhovered.connect(connect_unhover_func)
        card.picked.connect(connect_pick_func)

func add_rows_from_list(source_list: Array, per_row: int, options_container: VBoxContainer, state_manager: ProphecyMenuState, connect_hover_func: Callable, connect_unhover_func: Callable, connect_pick_func: Callable) -> bool:
    if source_list == null:
        return false
    var safe_per_row: int = max(1, per_row)
    var is_first_row := true
    while not source_list.is_empty():
        if not is_first_row:
            _ui_builder.add_vertical_gap(options_container, 10)
        add_row(ProphecyUIBuilder.take_first(source_list, safe_per_row), options_container, state_manager, connect_hover_func, connect_unhover_func, connect_pick_func)
        is_first_row = false
    return not is_first_row

func update_option_cards_state(options_container: Node, state_manager: ProphecyMenuState) -> void:
    if not options_container:
        return
    for ch in options_container.get_children():
        _update_option_cards_state_recursive(ch, state_manager)

func _update_option_cards_state_recursive(n: Node, state_manager: ProphecyMenuState) -> void:
    if n is ProphecyWaveCard:
        var card := n as ProphecyWaveCard
        if card.option_key == "":
            card.option_key = state_manager.compute_option_key(card.option_patterns)
        card.set_used(state_manager.is_option_used(card.option_patterns) or not state_manager.can_select_option(card.option_patterns))
    for c in n.get_children():
        _update_option_cards_state_recursive(c, state_manager)

func build_tier_legend() -> Node:
    return _ui_builder.build_tier_legend()

func add_section_banner(parent: Node, text: String) -> void:
    _ui_builder.add_section_banner(parent, text)

func populate_possible_rewards(container: Node) -> void:
    _ui_builder.populate_possible_rewards(container)
