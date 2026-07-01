extends PanelContainer

const SPAWN_MODE_BATTLEFIELD := 0
const SPAWN_MODE_BARRACKS := 1
const SPAWN_MODE_TO_CAPACITY := 2

const _TEX_WARRIOR := preload("res://assets/ui/class_ui/Warrior.png")
const _TEX_ARMY_MENU := preload("res://assets/ui/class_ui/army_ui.png")
const _TEX_ATTACK := preload("res://assets/ui/class_ui/attack.png")
const _TEX_BARRACK := preload("res://assets/ui/class_ui/barrack.png")
const _TEX_BARRACK_AND_ATTACK := preload("res://assets/ui/class_ui/barrack_and_attack.png")

const BarracksUnitCollectorScript := preload("res://scripts/ui/town/barracks/BarracksUnitCollector.gd")
const BarracksRowBuilderScript := preload("res://scripts/ui/town/barracks/BarracksRowBuilder.gd")
const BarracksTooltipsScript := preload("res://scripts/ui/town/barracks/BarracksTooltips.gd")
const BarracksTransferLogicScript := preload("res://scripts/ui/town/barracks/BarracksTransferLogic.gd")

@onready var _expand_button: Button = $Root/Header/Content/ExpandButton
@onready var _spawn_mode_button: Button = $Root/Header/Content/SpawnModeButton
@onready var _deploy_button: Button = $Root/Header/Content/DeployButton
@onready var _drag_area: Control = $Root/Header/DragArea
@onready var _panel: Control = $Root/Panel
@onready var _rows: VBoxContainer = $Root/Panel/Scroll/Rows

@onready var _mode_tooltip: Control = $Root/ModeTooltip
@onready var _mode_tooltip_bg: TextureRect = $Root/ModeTooltip/ModeTooltipBg
@onready var _mode_tooltip_label: Label = $Root/ModeTooltip/ModeTooltipLabel

@onready var _unit_tooltip: Control = $Root/UnitTooltip
@onready var _unit_tooltip_bg: TextureRect = $Root/UnitTooltip/UnitTooltipBg
@onready var _unit_tooltip_title: Label = $Root/UnitTooltip/UnitTooltipContent/Title
@onready var _unit_tooltip_base_header: Label = $Root/UnitTooltip/UnitTooltipContent/BaseHeader
@onready var _unit_tooltip_hp_label: Label = $Root/UnitTooltip/UnitTooltipContent/StatsGrid/HPLabel
@onready var _unit_tooltip_hp_value: Label = $Root/UnitTooltip/UnitTooltipContent/StatsGrid/HPValue
@onready var _unit_tooltip_dps_label: Label = $Root/UnitTooltip/UnitTooltipContent/StatsGrid/DPSLabel
@onready var _unit_tooltip_dps_value: Label = $Root/UnitTooltip/UnitTooltipContent/StatsGrid/DPSValue
@onready var _unit_tooltip_class_icon: TextureRect = $Root/UnitTooltip/UnitTooltipContent/ClassRow/ClassIcon
@onready var _unit_tooltip_class_label: Label = $Root/UnitTooltip/UnitTooltipContent/ClassRow/ClassLabel
@onready var _unit_tooltip_trait_header: Label = $Root/UnitTooltip/UnitTooltipContent/TraitHeader
@onready var _unit_tooltip_trait_description: Label = $Root/UnitTooltip/UnitTooltipContent/TraitDescription

const EXPANDED_PANEL_GAP_Y: float = 8.0

var _expanded: bool = false
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _in_battle: bool = false

var _collector: BarracksUnitCollector = null
var _builder: BarracksRowBuilder = null
var _tooltips: BarracksTooltips = null
var _transfer: BarracksTransferLogic = null

func _ready() -> void:
    _expand_button.pressed.connect(_toggle_panel)
    _spawn_mode_button.pressed.connect(_cycle_spawn_mode)
    _spawn_mode_button.mouse_entered.connect(_on_spawn_mode_mouse_entered)
    _spawn_mode_button.mouse_exited.connect(_on_spawn_mode_mouse_exited)
    _deploy_button.pressed.connect(_on_deploy_pressed)
    
    _expand_button.icon = _TEX_ARMY_MENU
    _expand_button.expand_icon = true
    _spawn_mode_button.icon = _TEX_BARRACK
    _spawn_mode_button.expand_icon = true
    _deploy_button.icon = _TEX_WARRIOR
    _deploy_button.expand_icon = true
    
    if _drag_area:
        _drag_area.gui_input.connect(_on_drag_area_gui_input)
    
    _initialize_modules()
    _connect_external_signals()
    
    _panel.visible = false
    _panel.top_level = true
    _sync_spawn_mode_visuals()
    _request_refresh()

func _initialize_modules() -> void:
    _collector = BarracksUnitCollectorScript.new()
    
    _builder = BarracksRowBuilderScript.new()
    _builder.initialize(_collector)
    
    _tooltips = BarracksTooltipsScript.new()
    _tooltips.initialize(
        _mode_tooltip,
        _mode_tooltip_bg,
        _mode_tooltip_label,
        _spawn_mode_button,
        _unit_tooltip,
        _unit_tooltip_bg,
        _unit_tooltip_title,
        _unit_tooltip_base_header,
        _unit_tooltip_hp_label,
        _unit_tooltip_hp_value,
        _unit_tooltip_dps_label,
        _unit_tooltip_dps_value,
        _unit_tooltip_class_icon,
        _unit_tooltip_class_label,
        _unit_tooltip_trait_header,
        _unit_tooltip_trait_description,
        _collector
    )
    
    _transfer = BarracksTransferLogicScript.new()
    _transfer.initialize(_collector)

func _connect_external_signals() -> void:
    if HeroCore:
        if HeroCore.has_signal("squad_changed"):
            HeroCore.squad_changed.connect(_request_refresh)
        if HeroCore.has_signal("hero_created"):
            HeroCore.hero_created.connect(func(_id, _data): _request_refresh())
        if HeroCore.has_signal("hero_removed"):
            HeroCore.hero_removed.connect(func(_id): _request_refresh())
        if HeroCore.has_signal("hero_updated"):
            HeroCore.hero_updated.connect(func(_id, _data): _request_refresh())
        if HeroCore.has_signal("troop_spawn_mode_changed"):
            HeroCore.troop_spawn_mode_changed.connect(func(_mode): _sync_spawn_mode_visuals())
    
    if EventBus:
        if EventBus.has_signal("wave_started"):
            EventBus.wave_started.connect(func(_n): _set_in_battle(true))
        if EventBus.has_signal("wave_completed"):
            EventBus.wave_completed.connect(func(_n): _set_in_battle(false))
        if EventBus.has_signal("wave_failed"):
            EventBus.wave_failed.connect(func(_n): _set_in_battle(false))

func _set_in_battle(v: bool) -> void:
    if _in_battle == v:
        return
    _in_battle = v
    _request_refresh()

func _process(_delta: float) -> void:
    pass

func _on_drag_area_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb := event as InputEventMouseButton
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                _dragging = true
                _drag_offset = get_global_mouse_position() - global_position
                accept_event()
            else:
                _dragging = false
                accept_event()
    elif event is InputEventMouseMotion:
        if _dragging:
            global_position = get_global_mouse_position() - _drag_offset
            if _expanded:
                _position_expanded_panel()
            accept_event()

func _toggle_panel() -> void:
    _expanded = not _expanded
    _panel.visible = _expanded
    if _expanded:
        _position_expanded_panel()
    _request_refresh()

func _cycle_spawn_mode() -> void:
    var mode := _get_spawn_mode()
    mode = (mode + 1) % 3
    if HeroCore and HeroCore.has_method("set_troop_spawn_mode"):
        HeroCore.set_troop_spawn_mode(mode)
    _sync_spawn_mode_visuals()
    _request_refresh()

func _get_spawn_mode() -> int:
    var mode := SPAWN_MODE_BARRACKS
    if HeroCore and HeroCore.has_method("get_troop_spawn_mode"):
        mode = int(HeroCore.get_troop_spawn_mode())
    return mode

func _sync_spawn_mode_visuals() -> void:
    var mode := _get_spawn_mode()
    match mode:
        SPAWN_MODE_BATTLEFIELD:
            _spawn_mode_button.icon = _TEX_ATTACK
        SPAWN_MODE_BARRACKS:
            _spawn_mode_button.icon = _TEX_BARRACK
        SPAWN_MODE_TO_CAPACITY:
            _spawn_mode_button.icon = _TEX_BARRACK_AND_ATTACK

func _on_spawn_mode_mouse_entered() -> void:
    _tooltips.show_mode_tooltip(_get_spawn_mode())

func _on_spawn_mode_mouse_exited() -> void:
    _tooltips.hide_mode_tooltip()

func _on_deploy_pressed() -> void:
    _transfer.deploy_any_from_barracks()

func _request_refresh() -> void:
    call_deferred("_refresh_rows")

func _refresh_rows() -> void:
    if not _expanded:
        return
    if _rows == null:
        return
    
    for child in _rows.get_children():
        child.queue_free()

    var info := _collector.collect_unit_info()

    var unowned_ids: Array[String] = []
    var barracks_ids: Array[String] = []
    for unit_id in info.keys():
        var row_data: Dictionary = info[unit_id]
        var unowned_active := int(row_data.get("unowned_active", 0))
        var b_active := int(row_data.get("barracks_active", 0))
        var b_in_barracks := int(row_data.get("barracks_in_barracks", 0))
        var cap := int(row_data.get("capacity", 0))
        if unowned_active > 0:
            unowned_ids.append(str(unit_id))
        if (b_active + b_in_barracks) > 0 or cap > 0:
            barracks_ids.append(str(unit_id))
    unowned_ids.sort()
    barracks_ids.sort()

    var unowned_grid: GridContainer = null
    if unowned_ids.size() > 0:
        unowned_grid = GridContainer.new()
        unowned_grid.name = "UnownedGrid"
        unowned_grid.columns = 4
        unowned_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        unowned_grid.add_theme_constant_override("h_separation", 12)
        unowned_grid.add_theme_constant_override("v_separation", 12)
        _rows.add_child(unowned_grid)

        for unit_id in unowned_ids:
            var unowned_count := int(info[unit_id].get("unowned_active", 0))
            var tile := _builder.build_unowned_tile(
                unit_id,
                unowned_count,
                func(uid: String): _transfer.dismiss_one_unowned_from_field(uid),
                func(uid: String): _tooltips.show_unit_tooltip(uid),
                func(): _tooltips.on_face_unhover()
            )
            if tile != null:
                unowned_grid.add_child(tile)

    if unowned_ids.size() > 0 and barracks_ids.size() > 0:
        var sep := HSeparator.new()
        sep.custom_minimum_size = Vector2(0, 10)
        _rows.add_child(sep)

    for unit_id in barracks_ids:
        var row_data: Dictionary = info[unit_id]
        var b_active := int(row_data.get("barracks_active", 0))
        var b_in_barracks := int(row_data.get("barracks_in_barracks", 0))
        var cap := int(row_data.get("capacity", 0))
        var total := int(row_data.get("barracks_total", b_active + b_in_barracks))
        
        var callbacks := {
            "on_hover": func(uid: String): _tooltips.show_unit_tooltip(uid),
            "on_unhover": func(): _tooltips.on_face_unhover(),
            "on_move_to_barracks": func(uid: String): _on_move_to_barracks(uid, info.get(uid, {})),
            "on_move_to_field": func(uid: String): _transfer.move_one_from_barracks_to_field(uid),
            "on_dismiss": func(uid: String): _transfer.dismiss_one_barracks_from_field(uid),
            "can_add_to_field": func(): return _transfer.can_add_to_field()
        }
        
        var row := _builder.build_barracks_row(unit_id, total, b_in_barracks, cap, b_active, _in_battle, callbacks)
        if row != null:
            _rows.add_child(row)

    _position_expanded_panel()

func _on_move_to_barracks(unit_id: String, unit_info: Dictionary) -> void:
    _transfer.move_one_from_field_to_barracks(unit_id, _in_battle, unit_info)

func _position_expanded_panel() -> void:
    if _panel == null or not _expanded:
        return

    var header := get_node_or_null("Root/Header") as Control
    if header == null:
        return

    _panel.reset_size()
    var panel_size := _panel.get_combined_minimum_size()
    if panel_size == Vector2.ZERO:
        panel_size = _panel.size

    var header_rect := header.get_global_rect()
    var target_size := Vector2(maxf(panel_size.x, header_rect.size.x), panel_size.y)
    _panel.size = target_size

    var pos := Vector2(
        header_rect.position.x,
        header_rect.position.y - target_size.y - EXPANDED_PANEL_GAP_Y
    )

    var screen := get_viewport_rect().size
    pos.x = clampf(pos.x, 4.0, maxf(4.0, screen.x - target_size.x - 4.0))
    pos.y = clampf(pos.y, 4.0, maxf(4.0, screen.y - target_size.y - 4.0))
    _panel.global_position = pos
