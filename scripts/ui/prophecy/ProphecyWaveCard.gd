extends Panel
class_name ProphecyWaveCard

signal picked(option_patterns: Array)
signal hovered(option_patterns: Array)
signal unhovered()

const DEBUG_PROPHECY_TOOLTIP := true
const TOOLTIP_SENTINEL := "prophecy_card_tooltip"
const USE_FIXED_HOVER_PANEL := true
const DEBUG_PROPHECY_DND := true

const EnemyPortraitScene: PackedScene = preload("res://scenes/ui/components/EnemyPortrait.tscn")
const ProphecyCardTooltipScene: PackedScene = preload("res://scenes/ui/prophecy/ProphecyCardTooltip.tscn")
const CARD_MIN_WIDTH := 256.0
const CARD_VERTICAL_PADDING := 12.0
const ROW_VERTICAL_SEPARATION := 4.0
const MOB_PORTRAIT_SIZE := Vector2(42, 42)
const MOB_CELL_SPACING := 20
const MOB_COUNT_FONT_SIZE := 46
const DRAG_START_DISTANCE_PX := 10.0

const ThaleahFont := preload("res://assets/ui/fonts/ThaleahFat.ttf")
const ProphecyWaveCardRowBuilderScript := preload("res://scripts/ui/prophecy/modules/ProphecyWaveCardRowBuilder.gd")
const ProphecyWaveCardDragPreviewBuilderScript := preload("res://scripts/ui/prophecy/modules/ProphecyWaveCardDragPreviewBuilder.gd")
const ProphecyWaveCardTooltipBuilderScript := preload("res://scripts/ui/prophecy/modules/ProphecyWaveCardTooltipBuilder.gd")

@onready var rows_container: VBoxContainer = get_node_or_null("Margin/Rows")

var option_patterns: Array = []
var interactive: bool = true

var option_key: String = ""

var _used: bool = false
var _dragging_self: bool = false
var _hovered: bool = false
var _left_press_active: bool = false
var _left_press_local_pos: Vector2 = Vector2.ZERO

var _normal_stylebox: StyleBox = null
var _hover_stylebox: StyleBox = null

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
    clip_contents = true
    if interactive:
        tooltip_text = "" if USE_FIXED_HOVER_PANEL else TOOLTIP_SENTINEL
    if rows_container:
        rows_container.clip_contents = true
        rows_container.set("theme_override_constants/separation", int(ROW_VERTICAL_SEPARATION))

    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

    _cache_styleboxes()
    _apply_visual_state()

    if DEBUG_PROPHECY_TOOLTIP:
        print("[ProphecyWaveCard] _ready name=", name, " interactive=", interactive, " tooltip_text='", tooltip_text, "' option_patterns=", (option_patterns.size() if option_patterns != null else -1))

    set_process(true)

func _process(_delta: float) -> void:
    if not _dragging_self:
        return
    var vp := get_viewport()
    if vp and not vp.gui_is_dragging():
        _dragging_self = false
        _apply_visual_state()

func _cache_styleboxes() -> void:
    var base := get_theme_stylebox("panel")
    if base:
        _normal_stylebox = base.duplicate(true)
        _hover_stylebox = base.duplicate(true)
        if _hover_stylebox is StyleBoxFlat:
            var sb := _hover_stylebox as StyleBoxFlat
            sb.bg_color = sb.bg_color.lightened(0.08)

func _on_mouse_entered() -> void:
    _hovered = true
    _apply_visual_state()
    if USE_FIXED_HOVER_PANEL and interactive and not _dragging_self and option_patterns != null and not option_patterns.is_empty():
        hovered.emit(option_patterns)

func _on_mouse_exited() -> void:
    _hovered = false
    _apply_visual_state()
    if USE_FIXED_HOVER_PANEL:
        unhovered.emit()

func set_interactive(enabled: bool) -> void:
    interactive = enabled
    mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
    _update_tooltip_enabled()

func set_used(is_used: bool) -> void:
    _used = is_used
    _apply_visual_state()

func _update_tooltip_enabled() -> void:
    if USE_FIXED_HOVER_PANEL:
        tooltip_text = ""
        return
    if not interactive:
        tooltip_text = ""
        if DEBUG_PROPHECY_TOOLTIP:
            print("[ProphecyWaveCard] tooltip disabled (interactive=false) name=", name)
        return
    if _dragging_self:
        tooltip_text = ""
        if DEBUG_PROPHECY_TOOLTIP:
            print("[ProphecyWaveCard] tooltip disabled (dragging) name=", name)
        return
    tooltip_text = TOOLTIP_SENTINEL
    if DEBUG_PROPHECY_TOOLTIP:
        print("[ProphecyWaveCard] tooltip enabled name=", name, " tooltip_text='", tooltip_text, "' patterns=", (option_patterns.size() if option_patterns != null else -1), " used=", _used)

func _apply_visual_state() -> void:
    var is_grey := _used or _dragging_self
    modulate = Color(0.7, 0.7, 0.7, 1.0) if is_grey else Color(1, 1, 1, 1)

    if _hovered and not is_grey and _hover_stylebox:
        add_theme_stylebox_override("panel", _hover_stylebox)
    elif _normal_stylebox:
        add_theme_stylebox_override("panel", _normal_stylebox)

    _update_tooltip_enabled()

func setup(patterns: Array) -> void:
    option_patterns = patterns
    if not rows_container:
        return
    for ch in rows_container.get_children():
        ch.queue_free()

    var total_mob_counts := ProphecyWaveCardRowBuilderScript.compute_total_mob_counts(option_patterns)
    var shown := {}

    for p in option_patterns:
        if p == null:
            continue
        rows_container.add_child(_build_pattern_row(p, total_mob_counts, shown))
    custom_minimum_size = ProphecyWaveCardRowBuilderScript.compute_min_size(
        rows_container.get_child_count(),
        CARD_MIN_WIDTH,
        MOB_PORTRAIT_SIZE,
        ROW_VERTICAL_SEPARATION,
        CARD_VERTICAL_PADDING
    )

func _gui_input(event: InputEvent) -> void:
    if not interactive:
        return
    if _used:
        return
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index != MOUSE_BUTTON_LEFT:
            return
        if mb.pressed:
            _left_press_active = true
            _left_press_local_pos = mb.position
            return
        if not _dragging_self:
            picked.emit(option_patterns)
        _left_press_active = false

func _get_drag_data(_at_position: Vector2) -> Variant:
    if not interactive:
        return null
    if _used:
        return null
    if not _left_press_active:
        return null
    if _left_press_local_pos.distance_to(_at_position) < DRAG_START_DISTANCE_PX:
        return null

    if DEBUG_PROPHECY_DND:
        print("[ProphecyWaveCard][DND] _get_drag_data name=", name, " patterns=", (option_patterns.size() if option_patterns != null else -1), " used=", _used)

    _left_press_active = false
    _dragging_self = true
    _apply_visual_state()

    var data := {"type": "prophecy_wave_option", "patterns": option_patterns}
    var preview := ProphecyWaveCardDragPreviewBuilderScript.create_drag_preview(
        get_scene_file_path(),
        option_patterns,
        CARD_MIN_WIDTH,
        MOB_PORTRAIT_SIZE
    )
    if preview:
        set_drag_preview(preview)
    return data

func _build_pattern_row(p: ProphecyPattern, total_mob_counts: Dictionary, shown: Dictionary) -> Control:
    return ProphecyWaveCardRowBuilderScript.build_pattern_row(
        p,
        total_mob_counts,
        shown,
        MOB_CELL_SPACING,
        MOB_PORTRAIT_SIZE,
        MOB_COUNT_FONT_SIZE,
        ThaleahFont,
        EnemyPortraitScene
    )

func _make_custom_tooltip(_for_text: String) -> Control:
    return ProphecyWaveCardTooltipBuilderScript.make_custom_tooltip(
        name,
        interactive,
        _dragging_self,
        option_patterns,
        USE_FIXED_HOVER_PANEL,
        DEBUG_PROPHECY_TOOLTIP,
        ProphecyCardTooltipScene
    )
